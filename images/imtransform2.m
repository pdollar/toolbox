function J = imtransform2( I, H, varargin )
% Applies a linear or nonlinear transformation to an image I.
%
% Takes the center of the image as the origin, not the top left corner.
% Also, the coordinate system is row/column format, so H must be also.
%
% The bounding box of the image is set by the BBOX argument, a string that
% can be 'loose' (default) or 'crop'. When BBOX is 'loose', J includes the
% whole transformed image, which generally is larger than I. When BBOX is
% 'crop' J is cropped to include only the central portion of the
% transformed image and is the same size as I. The 'loose' flag is
% currently inexact (because of some padding/cropping). Preserves I's type.
%
% USAGE
%  J = imtransform2( I, H, varargin )
%
% INPUTS - common
%  I          - input image [converted to double]
%  H          - 3x3 nonsingular homography matrix
%  varargin   - additional params (struct or name/value pairs)
%    .method    - ['linear'] 'nearest', 'spline', 'cubic' (for interp2)
%    .bbox      - ['crop'] or 'loose'
%    .show      - [0] figure to use for optional display
%    .pad       - [0] padding value (scalar, 'replicate' or 'none')
%    .useCache  - [0] optionally cache precomp. for given transform/dims.
%    .us        - [] can specify source r/c for each target (instead of H)
%    .vs        - [] can specify source r/c for each target (instead of H)
%
% OUTPUTS
%  J       - transformed image
%
% EXAMPLE - rigid transformation (rotation + translation)
%  I=imread('peppers.png');
%  R = rotationMatrix(pi/4); T=[1; 3]; H=[R T; 0 0 1];
%  J = imtransform2(I,H,'show',1,'pad','replicate');
%
% EXAMPLE - general homography (out of plane rotation)
%  load trees; I=X;
%  S=eye(3); S([1 5])=1/500; % zoom out 500 pixels
%  H=S^-1*rotationMatrix([0 1 0],pi/4)*S;
%  J = imtransform2(I,H,'bbox','loose','show',1);
%
% EXAMPLE - rotation using three approaches (and timing)
%  load trees; I=imResample(X,4); angle=35; method='bilinear';
%  % (1) rotate using imrotate (slow)
%  tic; J1 = imrotate(I,angle,method,'crop'); toc
%  % (2) rotate using a homography matrix
%  R=rotationMatrix(angle/180*pi); H=[R [0; 0]; 0 0 1];
%  tic; J2 = imtransform2(I,H,'bbox','crop','method',method); toc
%  % (3) rotate by explicitly specifying target rs/cs
%  m=size(I,1)+4; n=size(I,2)+4; m2=(m-1)/2; n2=(n-1)/2;
%  [cs,rs]=meshgrid(-n2:n2,-m2:m2); vs=R*[cs(:) rs(:)]';
%  us=reshape(vs(2,:),m,n)-rs; vs=reshape(vs(1,:),m,n)-cs;
%  tic, J3=imtransform2(I,[],'us',us,'vs',vs,'method',method); toc
%  % compare all results
%  figure(1); clf; subplot(3,2,1); im(I); subplot(3,2,2); im(J1);
%  subplot(3,2,3); im(J2); subplot(3,2,4); im(abs(J1-J2)); title('J1-J2')
%  subplot(3,2,5); im(J3); subplot(3,2,6); im(abs(J2-J3)); title('J2-J3')
%
% See also TEXTUREMAP, INTERP2
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.01
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% check and parse inputs
dfs={'method','linear','bbox','crop','show',0,'pad',0,'useCache',0,...
  'us',[],'vs',[]};
[method,bbox,show,pad,useCache,us,vs] = getPrmDflt(varargin,dfs,1);
looseFlag = strcmp(bbox,'loose'); if(show), Iorig=I; end; useH=1;
if(~isempty(us) && ~isempty(vs)), useH=0; assert(numel(us)==numel(vs)); end
if(~isa(us,'double')||~isa(vs,'double')), us=double(us); vs=double(vs); end
if( useH && any(size(H)~=[3 3])), error('H must be 3x3'); end
if( useH && all(all(H==eye(3))) ), J=I; return; end
if( ~ismatrix(I) && ndims(I)~=3 ), error('I must a MxNXK array'); end
if(~any(strcmp(bbox,{'loose','crop'}))), error(['invalid bbox: ' bbox]);end
if(strncmpi(method,'lin',3) || strncmpi(method,'bil',3)), mflag=2;
elseif(strcmp(method,'nearest') ), mflag=1; else mflag=0; end

% pad I and convert to double, makes interpolation simpler
isDouble=isa(I,'double'); if(~isDouble), classI=class(I); I=double(I); end
if(~strcmp(pad,'none'))
  m=size(I,1); n=size(I,2); ms=[1 1 1:m m m]; ns=[1 1 1:n n n];
  I=I(ms,ns,:); if(~useH), us=us(ms,ns); vs=vs(ms,ns); end
  if(~ischar(pad)), I([1:2 m+3:m+4],:,:)=pad; I(:,[1:2 n+3:n+4],:)=pad; end
end; m=size(I,1); n=size(I,2);

% optionally cache precomputed transformations
persistent cVals cKeys cCnt; if(isempty(cCnt)), cCnt=0; end; cached=0;
if(useH && useCache), cKey=[m n H(:)' mflag looseFlag];
  if(cCnt>0), id=find(all(cKey(ones(1,cCnt),:)==cKeys(1:cCnt,:),2));
    if(~isempty(id)), [rs,cs,is]=deal(cVals{id}{:}); cached=1; end; end
end

% perform transform precomputations
if( ~useH )
  % compute inds from row/col flow
  [rs,cs,is]=imtransform2_c('flowToInds',us,vs,m,n,mflag);
elseif( useH && (~useCache || ~cached) )
  % set origin to be center of image
  r0 = (-m+1)/2; r1 = (m-1)/2;
  c0 = (-n+1)/2; c1 = (n-1)/2;
  
  % If 'loose' then get bounds of resulting image. To do this project the
  % original points accoring to the homography and see the bounds. Note
  % that since a homography maps a quadrilateral to a quadrilateral only
  % need to look at where the bounds of the quadrilateral are mapped to.
  if( looseFlag )
    P = H * [r0 r1 r0 r1; c0 c0 c1 c1; 1 1 1 1];
    rs=P(1,:)./P(3,:); r0=min(rs(:)); r1=max(rs(:));
    cs=P(2,:)./P(3,:); c0=min(cs(:)); c1=max(cs(:));
  end
  
  % apply inverse homography on meshgrid in destination image
  s=svd(H); if(s(3)<=1e-6*s(1)), error('H is ill conditioned'); end
  H=H^-1; H=H/H(9);
  [rs,cs,is]=imtransform2_c('homogToInds',H,m,n,r0,r1,c0,c1,mflag);
  
  % if using cache, put value into cache
  if(useCache), if(cCnt==length(cVals)), cCnt1=max(16,cCnt);
      cVals=[cVals; cell(cCnt1,1)]; cKeys=[cKeys; zeros(cCnt1,13)]; end
    cCnt=cCnt+1; cVals{cCnt}={rs,cs,is}; cKeys(cCnt,:)=cKey;
  end
end

% now texture map results ('nearest', 'linear' mexed for speed)
if( mflag )
  J = imtransform2_c('applyTransform',I,rs,cs,is,mflag);
else
  J=interp2(I(:,:,1),cs,rs,method,0);
  k=size(I,3); if(k>1), J=J(:,:,ones(1,k)); end
  for i=2:k, J(:,:,i)=interp2(I(:,:,i),cs,rs,method,0); end
end
if(~strcmp(pad,'none')), J=J(3:end-2,3:end-2,:); end
if(~isDouble), J=feval(classI,J); end

% optionally show
if(show), figure(show); clf; im(Iorig); figure(show+1); clf; im(J); end

end
