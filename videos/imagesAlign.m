function [H,Ip] = imagesAlign( I, Iref, varargin )
% Fast and robust estimation of homography relating two images.
%
% The algorithm for image alignment is a simple but effective variant of
% the inverse compositional algorithm. For a thorough overview, see:
%   "Lucas-kanade 20 years on A unifying framework,"
%   S. Baker and I. Matthews. IJCV 2004.
% The implementation is optimized and can easily run at 20-30 fps.
% 
% type may take on the following values:
%  'translation'  - translation only
%  'rigid'        - translation and rotation
%  'similarity'   - translation, rotation and scale
%  'affine'       - 6 parameter affine transform
%  'rotation'     - pure rotation (about x, y and z)
%  'projective'   - full 8 parameter homography
% Alternatively, type may be a vector of ids between 1 and 8, specifying
% exactly the types of transforms allowed. The ids correspond, to: 1:
% translate-x, 2: translate-y, 3: uniform scale, 4: shear, 5: non-uniform
% scale, 6: rotate-z, 7: rotate-x, 8: rotate-y. For example, to specify
% translation use type=[1,2]. If the transforms don't form a group, the
% returned homography may have more degrees of freedom than expected.
%
% Parameters (in rough order of importance): [resample] controls image
% downsampling prior to computing H. Runtime is proportional to area, so
% using resample<1 can dramatically speed up alignment, and in general not
% degrade performance much. [sig] controls image smoothing, sig=2 gives
% good performance, setting sig too low causes loss of information and too
% high will violate the linearity assumption. [epsilon] defines the
% stopping criteria, use to adjust performance versus speed tradeoff.
% [lambda] is a regularization term that causes small transforms to be
% favored, in general any small non-zero setting of lambda works well.
% [outThr] is a threshold beyond which pixels are considered outliers, be
% careful not to set too low. [minArea] determines coarsest scale beyond
% which the image is not downsampled (should not be set too low). [H0] can
% be used to specify an initial alignment. Use [show] to display results.
%
% USAGE
%  [H,Ip] = imagesAlign( I, Iref, varargin )
%
% INPUTS
%  I          - transformed version of I
%  Iref       - reference grayscale double image
%  varargin   - additional params (struct or name/value pairs)
%   .type       - ['projective'] see above for options
%   .resample   - [1] image resampling prior to homography estimation
%   .sig        - [2] amount of Gaussian spatial smoothing to apply
%   .epsilon    - [1e-3] stopping criteria (min change in error)
%   .lambda     - [1e-6] regularization term favoring small transforms
%   .outThr     - [inf] outlier threshold
%   .minArea    - [4096] minimum image area in coarse to fine search
%   .H0         - [eye(3)] optional initial homography estimate
%   .show       - [0] optionally display results in figure show
%
% OUTPUTS
%  H        - estimated homography to transform I into Iref
%  Ip       - tranformed version of I (slow to compute)
%
% EXAMPLE
%  Iref = double(imread('cameraman.tif'))/255;
%  H0 = [eye(2)+randn(2)*.1 randn(2,1)*10; randn(1,2)*1e-3 1];
%  I = imtransform2(Iref,H0^-1,'pad','replicate');
%  o=50; P=ones(o)*1; I(150:149+o,150:149+o)=P;
%  prmAlign={'outThr',.1,'resample',.5,'type',1:8,'show'};
%  [H,Ip]=imagesAlign(I,Iref,prmAlign{:},1);
%  tic, for i=1:30, H=imagesAlign(I,Iref,prmAlign{:},0); end;
%  t=toc; fprintf('average fps: %f\n',30/t)
%
% See also imTransform2
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.61
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get parameters
dfs={'type','projective','resample',1,'sig',2,'epsilon',1e-3,...
  'lambda',1e-6,'outThr',inf,'minArea',4096,'H0',eye(3),'show',0};
[type,resample,sig,epsilon,lambda,outThr,minArea,H0,show] = ...
  getPrmDflt(varargin,dfs,1);
filt = filterGauss(2*ceil(sig*2.5)+1,[],sig^2);

% determine type of transformation to recover
if(isnumeric(type)), assert(length(type)<=8); else
  id=find(strcmpi(type,{'translation','rigid','similarity','affine',...
    'rotation','projective'})); msgId='piotr:imagesAlign';
  if(isempty(id)), error(msgId,'unknown type: %s',type); end
  type={1:2,[1:2 6],[1:3 6],1:6,6:8,1:8}; type=type{id};
end; keep=zeros(1,8); keep(type)=1; keep=keep>0;

% compute image alignment (optionally resample first)
prm={keep,filt,epsilon,H0,minArea,outThr,lambda};
if( resample==1 ), H=imagesAlign1(I,Iref,prm); else
  S=eye(3); S([1 5])=resample; H0=S*H0*S^-1; prm{4}=H0;
  I1=imResample(I,resample); Iref1=imResample(Iref,resample);
  H=imagesAlign1(I1,Iref1,prm); H=S^-1*H*S;
end

% optionally rectify I and display results (can be expensive)
if(nargout==1 && show==0), return; end
Ip = imtransform2(I,H,'pad','replicate');
if(show), figure(show); clf; s=@(i) subplot(2,3,i);
  Is=[I Iref Ip]; ri=[min(Is(:)) max(Is(:))];
  D0=abs(I-Iref); D1=abs(Ip-Iref); Ds=[D0 D1]; di=[min(Ds(:)) max(Ds(:))];
  s(1); im(I,ri,0); s(2); im(Iref,ri,0); s(3); im(D0,di,0);
  s(4); im(Ip,ri,0); s(5); im(Iref,ri,0); s(6); im(D1,di,0);
  s(3); title('|I-Iref|'); s(6); title('|Ip-Iref|');
end

end

function H = imagesAlign1( I, Iref, prm )

% apply recursively if image large
[keep,filt,epsilon,H0,minArea,outThr,lambda]=deal(prm{:});
[h,w]=size(I); hc=mod(h,2); wc=mod(w,2);
if( w*h<minArea ), H=H0; else
  I1=imResample(I(1:(h-hc),1:(w-wc)),.5);
  Iref1=imResample(Iref(1:(h-hc),1:(w-wc)),.5);
  S=eye(3); S([1 5])=2; H0=S^-1*H0*S; prm{4}=H0;
  H=imagesAlign1(I1,Iref1,prm); H=S*H*S^-1;
end

% smooth images (pad first so dimensions unchanged)
O=ones(1,(length(filt)-1)/2); hs=[O 1:h h*O]; ws=[O 1:w w*O];
Iref=conv2(conv2(Iref(hs,ws),filt','valid'),filt,'valid');
I=conv2(conv2(I(hs,ws),filt','valid'),filt,'valid');

% pad images with nan so later can determine valid regions
hs=[1 1 1:h h h]; ws=[1 1 1:w w w]; I=I(hs,ws); Iref=Iref(hs,ws);
hs=[1:2 h+3:h+4]; I(hs,:)=nan; Iref(hs,:)=nan;
ws=[1:2 w+3:w+4]; I(:,ws)=nan; Iref(:,ws)=nan;

% convert weights hardcoded for 128x128 image to given image dims
wts=[1 1 1.0204 .03125 1.0313 0.0204 .00055516 .00055516];
s=sqrt(numel(Iref))/128;
wts=[wts(1:2) wts(3)^(1/s) wts(4)/s wts(5)^(1/s) wts(6)/s wts(7:8)/(s*s)];

% prepare subspace around Iref
[~,Hs]=ds2H(-ones(1,8),wts); Hs=Hs(:,:,keep); K=size(Hs,3);
[h,w]=size(Iref); Ts=zeros(h,w,K); k=0;
if(keep(1)), k=k+1; Ts(:,1:end-1,k)=Iref(:,2:end); end
if(keep(2)), k=k+1; Ts(1:end-1,:,k)=Iref(2:end,:); end
pTransf={'method','bilinear','pad','none','useCache'};
for i=k+1:K, Ts(:,:,i)=imtransform2(Iref,Hs(:,:,i),pTransf{:},1); end
Ds=Ts-Iref(:,:,ones(1,K)); Mref = ~any(isnan(Ds),3);
if(0), figure(10); montage2(Ds); end
Ds = reshape(Ds,[],size(Ds,3));

% iteratively project Ip onto subspace, storing transformation
lambda=lambda*w*h*eye(K); ds=zeros(1,8); err=inf;
for i=1:100
  s=svd(H); if(s(3)<=1e-4*s(1)), H=eye(3); return; end
  Ip=imtransform2(I,H,pTransf{:},0); dI=Ip-Iref; dI0=abs(dI);
  M=Mref & ~isnan(Ip); M0=M; if(outThr<inf), M=M & dI0<outThr; end
  M1=find(M); D=Ds(M1,:); ds1=(D'*D + lambda)^(-1)*(D'*dI(M1));
  if(any(isnan(ds1))), ds1=zeros(K,1); end
  ds(keep)=ds1; H1=ds2H(ds,wts); H=H*H1; H=H/H(9);
  err0=err; err=dI0; err(~M0)=0; err=mean2(err); del=err0-err;
  if(0), fprintf('i=%03i err=%e del=%e\n',i,err,del); end
  if( del<epsilon ), break; end
end

end

function [H,Hs] = ds2H( ds, wts )
% compute homography from offsets ds
Hs=eye(3); Hs=Hs(:,:,ones(1,8));
Hs(2,3,1)=wts(1)*ds(1);                       % 1 x translation
Hs(1,3,2)=wts(2)*ds(2);                       % 2 y translation
Hs(1:2,1:2,3)=eye(2)*wts(3)^ds(3);            % 3 scale
Hs(2,1,4)=wts(4)*ds(4);                       % 4 shear
Hs(1,1,5)=wts(5)^ds(5);                       % 5 scale non-uniform
ct=cos(wts(6)*ds(6)); st=sin(wts(6)*ds(6));
Hs(1:2,1:2,6)=[ct -st; st ct];                % 6 rotation about z
ct=cos(wts(7)*ds(7)); st=sin(wts(7)*ds(7));
Hs([1 3],[1 3],7)=[ct -st; st ct];            % 7 rotation about x
ct=cos(wts(8)*ds(8)); st=sin(wts(8)*ds(8));
Hs(2:3,2:3,8)=[ct -st; st ct];                % 8 rotation about y
H=eye(3); for i=1:8, H=Hs(:,:,i)*H; end
end
