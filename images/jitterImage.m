function IJ = jitterImage( I, varargin )
% Creates multiple, slightly jittered versions of an image.
%
% Takes an image I, and generates a number of images that are copies of the
% original image with slight translation, rotation and scaling applied. The
% original image also appears in the final set. If the input image is
% actually a MxNxK stack of images then applies op to each image in stack
% and returns an MxNxKxR where R=(nTrn*nTrn*nPhi) set of images.
%
% The parameter jsiz controls the size of the cropped images. If jsiz gives
% a size that's sufficiently smaller than I then all data in the the final
% set will come from I. However, if this is not the case then I may need to
% be padded first. The way this is done is with padarray with the
% 'replicate' method. If jsiz is not specified, it is set to be the size of
% the original image.
%
% Rotations and translations are specified by giving a range and a maximum
% value for each. For example, if mPhi=10 and nPhi=5, then the actual
% rotations applied are linspace(-mPhi,mPhi,nPhi) = [-10 -5 0 5 10].
% Likewise if mTrn=3 and nTrn=3 then the translations are [-3 0 3]. Each
% translation is applied in the x direction as well as the y direction.
% Each combination of rotation, translation in x, and translation in y is
% used (for example phi=5, transx=-3, transy=0), so the total number of
% images generated is R=nTrn*nTrn*nPhi). This function works faster if all
% of the translation end up being integer valued.
%
% USAGE
%  function IJ = jitterImage( I, varargin )
%
% INPUTS
%  I          - BW image (MxN) or images (MxNxK), must have odd dims
%  varargin   - additional params (struct or name/value pairs)
%   .nPhi        - [0] number of rotations
%   .mPhi        - [0] max value for rotation
%   .nTrn        - [0] number of translations
%   .mTrn        - [0] max value for translation
%   .jsiz        - [] Final size of each image in IJ
%   .flip        - [0] if true then also adds reflection of each image
%   .scls        - [1 1] nScl x 2 array of vert/horiz scalings
%   .method      - ['linear'] interpolation method for imtransform2
%
% OUTPUTS
%  IJ          - MxNxR or MxNxKxR set of images, R=(nTrn^2*nPhi*nScl)
%
% EXAMPLE
%  load trees; I=imresize(ind2gray(X,map),[41 41]); clear X caption map
%  % creates 7^2*2 images of slight trans with reflection (but no rotation)
%  IJ = jitterImage(I,'nTrn',7,'mTrn',3, 'flip',1); montage2(IJ)
%  % creates 5 images of slight rotations (no translations)
%  IJ = jitterImage(I,'nPhi',5,'mPhi',25,'flip',0); montage2(IJ)
%  % creates 45 images of both rot and slight trans
%  IJ = jitterImage(I,'nPhi',5,'mPhi',10,'nTrn',3,'mTrn',2); montage2(IJ)
%  % additionally create multiple scaled versions
%  IJ = jitterImage(I,'scls',[1 1; 2 1; 1 2; 2 2]); montage2(IJ)
%
% See also jitterVideo, imtransform2
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% NOTE: CODE HAS BECOME REALLY MESSY :-(

% Eigenanalysis of IJ can be informative:
%   I = double(I);
%   IJ = jitterImage( I, 111, 10, 0, 0 );
%   IJ = jitterImage( I, 11, 10, 11, 3 ); %slow
%   [ U, mu, variances ] = pca( IJ );
%   ks = 0:min(11,size(U,2));   % should need about 4
%   pcaVisualize( U, mu, variances, IJ, [], ks );


% get additional parameters
nd=ndims(I); siz=size(I);
dfs={'nPhi',0, 'mPhi',0, 'nTrn',0, 'mTrn',0, 'jsiz',siz(1:2),...
  'flip',0, 'scls',[1 1], 'method','linear'};
[nPhi,mPhi,nTrn,mTrn,jsiz,flip,scls,method]=getPrmDflt(varargin,dfs,1);
if(nPhi<=1), mPhi=0; nPhi=1; end; if(nTrn<=1), mTrn=0; nTrn=1; end
if((nd~=2 && nd~=3) || length(jsiz)~=2), error('I must be 2D or 3D'); end

% build translations and phis
phis=linspace(-mPhi,mPhi,nPhi)/180*pi;
trn=linspace(-mTrn,mTrn,nTrn); [dX,dY]=meshgrid(trn,trn);
dY=dY(:)'; dX=dX(:)';

% I must be big enough to support given ops so grow I if necessary
siz1=jsiz+2*max(dX); if(nPhi>1), siz1=sqrt(2)*siz1+1; end
siz1=[siz1(1)*max(scls(:,1)) siz1(2)*max(scls(:,2))];
pad=(siz1-siz(1:2))/2; pad=max([ceil(pad) 0],0);
if(any(pad>0)), I=padarray(I,pad,'replicate','both'); end

% now for each image jitter it
if( nd==2 )
  IJ = jitterImage1(I,method,jsiz,phis,dX,dY,scls,flip);
elseif( nd==3 )
  IJ = fevalArrays(I,@jitterImage1,method,jsiz,phis,dX,dY,scls,flip);
  IJ = reshape(IJ,size(IJ,1),size(IJ,2),[]);
end
end

function IJ = jitterImage1( I, method, jsiz, phis, dX, dY, scls, flip )
% this function does the work for SCALE and FLIPPING
nScl=size(scls,1);
for i=1:nScl
  if(i==2), IJ=repmat(IJ,[1 1 1 nScl]); end
  if(all(scls(i,:)==1)), I1=I; else
    S=[scls(i,1) 0; 0 scls(i,2)]; H=[S [0;0]; 0 0 1];
    I1 = imtransform2(I,H,method,'crop');
  end
  I1 = jitterImage2(I1,method,jsiz,phis,dX,dY);
  if(i==1), IJ=I1; continue; else IJ(:,:,:,i)=I1; end
end
IJ = reshape(IJ,jsiz(1),jsiz(2),[]);
if(flip), IJ=cat(3,IJ,IJ(:,end:-1:1,:)); end
end

function IJ = jitterImage2( I, method, jsiz, phis, dX, dY )
% this function does the work for ROT/TRANS
nTrn = length(dX); nPhi = length(phis); nOps = nTrn*nPhi;
siz = size(I);   deltas = (siz - jsiz)/2;
% get each of the transformations.
index = 1;
if( all(mod(dX,1))==0) % all integer translations [optimized for speed]
  startr = floor(deltas(1)+1); endr = floor(siz(1)-deltas(1));
  startc = floor(deltas(2)+1); endc = floor(siz(2)-deltas(2));
  IJ = repmat( I(1), [jsiz(1), jsiz(2), nOps] );
  for phi=phis
    if( phi==0); IR = I; else
      R = rotationMatrix( phi );
      H = [R [0;0]; 0 0 1];
      IR = imtransform2( I, H, method, 'crop' );
    end
    for t=1:nTrn
      I2 = IR( (startr:endr)-dX(t), (startc:endc)-dY(t) );
      IJ(:,:,index) = I2; index = index+1;
    end
  end
else % arbitrary translations
  IJ = repmat( I(1), [siz(1), siz(2), nOps] );
  for phi=phis
    R = rotationMatrix( phi );
    for t=1:nTrn
      H = [R dX(t) dY(t); 0 0 1];
      I2 = imtransform2( I, H, method, 'crop' );
      IJ(:,:,index) = I2; index = index+1;
    end
  end
  IJ = arrayToDims( IJ, [jsiz, nOps] );
end
end
