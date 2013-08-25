function [Vx,Vy,reliab] = opticalFlow( I1, I2, varargin )
% Coarse-to-fine optical flow using Lucas&Kanade or Horn&Schunck.
%
% Implemented 'type' of optical flow estimation:
%  LK: http://en.wikipedia.org/wiki/Lucas-Kanade_method
%  HS: http://en.wikipedia.org/wiki/Horn-Schunck_method
% LK is a local, fast method (the implementation is fully vectorized).
% HS is a global, slower method (an SSE implementation is provided).
%
% Common parameters for LK and HS: 'smooth' determines smoothing prior to
% flow computation and can make flow estimation more robust. 'maxScale' can
% be used to downsample an image for faster but lower quality results, e.g.
% maxScale=.5 makes flow computation about 4x faster. LK: 'radius' controls
% integration window size (and smoothness of flow). HS: 'alpha' controls
% tradeoff between data and smoothness term (and smoothness of flow) and
% 'nIter' determines number of gradient decent steps.
%
% USAGE
%  [Vx,Vy,reliab] = opticalFlow( I1, I2, pFlow )
%
% INPUTS
%  I1, I2   - input images to calculate flow between
%  pFlow    - parameters (struct or name/value pairs)
%   .type       - ['LK'] may be either 'LK' or 'HS'
%   .smooth     - [1] smoothing radius for triangle filter (may be 0)
%   .filt       - [0] median filtering radius for smoothing flow field
%   .minScale   - [1/64] minimum pyramid scale (must be a power of 2)
%   .maxScale   - [1] maximum pyramid scale (must be a power of 2)
%   .radius     - [5] integration radius for weighted window [LK only]
%   .alpha      - [1] smoothness constraint [HS only]
%   .nIter      - [250] number of iterations [HS only]
%
% OUTPUTS
%  Vx, Vy   - x,y components of flow  [Vx>0->right, Vy>0->down]
%  reliab   - reliability of flow in given window [LK only]
%
% EXAMPLE - compute LK flow on test images
%  load opticalFlowTest;
%  [Vx,Vy]=opticalFlow(I1,I2,'smooth',1,'radius',10,'type','LK');
%  figure(1); im(I1); figure(2); im(I2);
%  figure(3); im([Vx Vy]); colormap jet;
%
% EXAMPLE - rectify I1 to I2 using computed flow
%  load opticalFlowTest;
%  [Vx,Vy]=opticalFlow(I1,I2,'smooth',1,'radius',10,'type','LK');
%  I1=imtransform2(I1,[],'vs',-Vx,'us',-Vy,'pad','replicate');
%  figure(1); im(I1); figure(2); im(I2);
%
% EXAMPLE - compare LK and HS flow
%  load opticalFlowTest;
%  prm={'smooth',1,'radius',10,'alpha',20,'nIter',200,'type'};
%  tic, [Vx1,Vy1]=opticalFlow(I1,I2,prm{:},'LK'); toc
%  tic, [Vx2,Vy2]=opticalFlow(I1,I2,prm{:},'HS'); toc
%  figure(1); im([Vx1 Vy1; Vx2 Vy2]); colormap jet;
%
% See also convTri, imtransform2
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get default parameters and do error checking
dfs={ 'type','LK', 'smooth',1, 'filt',0, 'minScale',1/64, ...
  'maxScale',1, 'radius',5, 'alpha',1, 'nIter',250 };
[type,smooth,filt,minScale,maxScale,radius,alpha,nIter] = ...
  getPrmDflt(varargin,dfs,1);
assert(any(strcmp(type,{'LK','HS'}))); useLk=strcmp(type,'LK');
if( ~ismatrix(I1) || ~ismatrix(I2) || any(size(I1)~=size(I2)) )
  error('Input images must be 2D and have same dimensions.'); end

% run optical flow in coarse to fine fashion
if(~isa(I1,'single')), I1=single(I1); I2=single(I2); end
[h,w]=size(I1); nScales=max(1,floor(log2(min([h w 1/minScale])))+1);
for s=1:max(1,nScales + round(log2(maxScale)))
  % get current scale and I1s and I2s at given scale
  scale=2^(nScales-s); h1=round(h/scale); w1=round(w/scale);
  if( scale==1 ), I1s=I1; I2s=I2; else
    I1s=imResample(I1,[h1 w1]); I2s=imResample(I2,[h1 w1]); end
  % initialize Vx,Vy or upsample from previous scale
  if(s==1), Vx=zeros(h1,w1,'single'); Vy=Vx; else r=sqrt(h1*w1/numel(Vx));
    Vx=imResample(Vx,[h1 w1])*r; Vy=imResample(Vy,[h1 w1])*r; end
  % transform I2s according to current estimate of Vx and Vy
  if(s>1), I2s=imtransform2(I2s,[],'pad','replciate','vs',Vx,'us',Vy); end
  % smooth images
  I1s=convTri(I1s,smooth); I2s=convTri(I2s,smooth);
  % run optical flow on current scale
  if( useLk ), [Vx1,Vy1,reliab]=opticalFlowLk(I1s,I2s,radius);
  else [Vx1,Vy1]=opticalFlowHs(I1s,I2s,alpha,nIter); reliab=[]; end
  Vx=Vx+Vx1; Vy=Vy+Vy1;
  % finally median filter the resulting flow field
  if(filt), Vx=medfilt2(Vx,[filt filt],'symmetric'); end
  if(filt), Vy=medfilt2(Vy,[filt filt],'symmetric'); end
end
r=sqrt(h*w/numel(Vx));
if(r~=1), Vx=imResample(Vx,[h w])*r; Vy=imResample(Vy,[h w])*r; end

end

function [Vx,Vy,reliab] = opticalFlowLk( I1, I2, radius  )
% Compute elements of A'A and also of A'b
radius=min(radius,floor(min(size(I1,1),size(I1,2))/2)-1);
[Ix,Iy]=gradient2(I1); It=I2-I1; AAxy=convTri(Ix.*Iy,radius);
AAxx=convTri(Ix.^2,radius)+1e-5; ABxt=convTri(-Ix.*It,radius);
AAyy=convTri(Iy.^2,radius)+1e-5; AByt=convTri(-Iy.*It,radius);
% Find determinant and trace of A'A
AAdet=AAxx.*AAyy-AAxy.^2; AAdeti=1./AAdet; AAtr=AAxx+AAyy;
% Compute components of velocity vectors (A'A)^-1 * A'b
Vx = AAdeti .* ( AAyy.*ABxt - AAxy.*AByt);
Vy = AAdeti .* (-AAxy.*ABxt + AAxx.*AByt);
% Check for ill conditioned second moment matrices
reliab = 0.5*AAtr - 0.5*sqrt(AAtr.^2-4*AAdet);
end

function [Vx,Vy] = opticalFlowHs( I1, I2, alpha, nIter )
% compute derivatives (averaging over 2x2 neighborhoods)
pad = @(I,p) imPad(I,p,'replicate');
Ex = I1(:,2:end)-I1(:,1:end-1) + I2(:,2:end)-I2(:,1:end-1);
Ey = I1(2:end,:)-I1(1:end-1,:) + I2(2:end,:)-I2(1:end-1,:);
Ex = Ex/4; Ey = Ey/4; Et = (I2-I1)/4;
Ex = pad(Ex,[1 1 1 2]) + pad(Ex,[0 2 1 2]);
Ey = pad(Ey,[1 2 1 1]) + pad(Ey,[1 2 0 2]);
Et=pad(Et,[0 2 1 1])+pad(Et,[1 1 1 1])+pad(Et,[1 1 0 2])+pad(Et,[0 2 0 2]);
Z=1./(alpha*alpha + Ex.*Ex + Ey.*Ey);
% iterate updating Ux and Vx in each iter
if( 1 )
  [Vx,Vy]=opticalFlowHsMex(Ex,Ey,Et,Z,nIter);
  Vx=Vx(2:end-1,2:end-1); Vy=Vy(2:end-1,2:end-1);
else
  Vx=zeros(size(I1),'single'); Vy=Vx;
  for i = 1:nIter
    Mx=.25*(shift(Vx,-1,0)+shift(Vx,1,0)+shift(Vx,0,-1)+shift(Vx,0,1));
    My=.25*(shift(Vy,-1,0)+shift(Vy,1,0)+shift(Vy,0,-1)+shift(Vy,0,1));
    m=(Ex.*Mx+Ey.*My+Et).*Z; Vx=Mx-Ex.*m; Vy=My-Ey.*m;
    Vx=Vx(2:end-1,2:end-1); Vy=Vy(2:end-1,2:end-1);
  end
end
end

function J = shift( I, y, x ) %#ok<DEFNU>
% shift I by -1<=x,y<=1 pixels
[h,w]=size(I); J=zeros(h+2,w+2,'single');
J(2-y:end-1-y,2-x:end-1-x)=I;
end
