function IJ = jitterImage( I, varargin )
% Creates multiple, slightly jittered versions of an image.
%
% Takes an image I, and generates a number of images that are copies of the
% original image with slight translation, rotation and scaling applied. If
% the input image is actually an MxNxK stack of images then applies op to
% each image. Rotations and translations are specified by giving a range
% and a max value for each. For example, if mPhi=10 and nPhi=5, then the
% actual rotations applied are linspace(-mPhi,mPhi,nPhi)=[-10 -5 0 5 10].
% Likewise if mTrn=3 and nTrn=3 then the translations are [-3 0 3]. Each
% tran is applied in the x direction as well as the y direction. Each
% combination of rotation, tran in x, tran in y and scale is used (for
% example phi=5, transx=-3, transy=0), so the total number of images
% generated is R=nTrn*nTrn*nPhi*nScl. Finally, jsiz controls the size of
% the cropped images. If jsiz gives a size that's sufficiently smaller than
% I then all data in the the final set will come from I. Otherwise, I must
% be padded first (by calling padarray with the 'replicate' option).
%
% USAGE
%  function IJ = jitterImage( I, varargin )
%
% INPUTS
%  I          - image (MxN) or set of K images (MxNxK)
%  varargin   - additional params (struct or name/value pairs)
%   .maxn        - [inf] maximum jitters to generate (prior to flip)
%   .nPhi        - [0] number of rotations
%   .mPhi        - [0] max value for rotation
%   .nTrn        - [0] number of translations
%   .mTrn        - [0] max value for translation
%   .flip        - [0] if true then also adds reflection of each image
%   .jsiz        - [] Final size of each image in IJ
%   .scls        - [1 1] nScl x 2 array of vert/horiz scalings
%   .method      - ['linear'] interpolation method for imtransform2
%   .hasChn      - [0] if true I is MxNxC or MxNxCxK
%
% OUTPUTS
%  IJ          - MxNxKxR or MxNxCxKxR set of images, R=(nTrn^2*nPhi*nScl)
%
% EXAMPLE
%  load trees; I=imresize(ind2gray(X,map),[41 41]); clear X caption map
%  % creates 10 (of 7^2*2) images of slight trans
%  IJ = jitterImage(I,'nTrn',7,'mTrn',3,'maxn',10); montage2(IJ)
%  % creates 5 images of slight rotations w reflection
%  IJ = jitterImage(I,'nPhi',5,'mPhi',25,'flip',1); montage2(IJ)
%  % creates 45 images of both rot and slight trans
%  IJ = jitterImage(I,'nPhi',5,'mPhi',10,'nTrn',3,'mTrn',2); montage2(IJ)
%  % additionally create multiple scaled versions
%  IJ = jitterImage(I,'scls',[1 1; 2 1; 1 2; 2 2]); montage2(IJ)
%  % example on color image (5 images of slight rotations)
%  I=imResample(imread('peppers.png'),[100,100]);
%  IJ=jitterImage(I,'nPhi',5,'mPhi',25,'hasChn',1);
%  montage2(uint8(IJ),{'hasChn',1})
%
% See also imtransform2
%
% Piotr's Image&Video Toolbox      Version 2.65
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get additional parameters
siz=size(I);
dfs={'maxn',inf, 'nPhi',0, 'mPhi',0, 'nTrn',0, 'mTrn',0, 'flip',0, ...
  'jsiz',siz(1:2), 'scls',[1 1], 'method','linear', 'hasChn',0};
[maxn,nPhi,mPhi,nTrn,mTrn,flip,jsiz,scls,method,hasChn] = ...
  getPrmDflt(varargin,dfs,1);
if(nPhi<1), mPhi=0; nPhi=1; end; if(nTrn<1), mTrn=0; nTrn=1; end

% I must be big enough to support given ops so grow I if necessary
trn=linspace(-mTrn,mTrn,nTrn); [dX,dY]=meshgrid(trn,trn);
dY=dY(:)'; dX=dX(:)'; phis=linspace(-mPhi,mPhi,nPhi)/180*pi;
siz1=jsiz+2*max(dX); if(nPhi>1), siz1=sqrt(2)*siz1+1; end
siz1=[siz1(1)*max(scls(:,1)) siz1(2)*max(scls(:,2))];
pad=(siz1-siz(1:2))/2; pad=max([ceil(pad) 0],0);
if(any(pad>0)), I=padarray(I,pad,'replicate','both'); end

% jitter each image
nScl=size(scls,1); nTrn=length(dX); nPhi=length(phis);
nOps=min(maxn,nTrn*nPhi*nScl); if(flip), nOps=nOps*2; end
if(hasChn), nd=3; jsiz=[jsiz siz(3)]; else nd=2; end
n=size(I,nd+1); IJ=zeros([jsiz nOps n],class(I));
is=repmat({':'},1,nd); prm={method,maxn,jsiz,phis,dX,dY,scls,flip};
for i=1:n, IJ(is{:},:,i)=jitterImage1(I(is{:},i),prm{:}); end

end

function IJ = jitterImage1( I,method,maxn,jsiz,phis,dX,dY,scls,flip )
% generate list of transformations (HS)
nScl=size(scls,1); nTrn=length(dX); nPhi=length(phis);
nOps=nTrn*nPhi*nScl; HS=zeros(3,3,nOps); k=0;
for s=1:nScl, S=[scls(s,1) 0; 0 scls(s,2)];
  for p=1:nPhi, R=rotationMatrix(phis(p));
    for t=1:nTrn, k=k+1; HS(:,:,k)=[S*R [dX(t); dY(t)]; 0 0 1]; end
  end
end
% apply each transformation HS(:,:,i) to image I
if(nOps>maxn), HS=HS(:,:,randSample(nOps,maxn)); nOps=maxn; end
siz=size(I); nd=ndims(I); nCh=size(I,3);
I1=I; p=(siz-jsiz)/2; IJ=zeros([jsiz nOps],class(I));
for i=1:nOps, H=HS(:,:,i); d=H(1:2,3)';
  if( all(all(H(1:2,1:2)==eye(2))) && all(mod(d,1)==0) )
    % handle transformation that's just an integer translation
    s=max(1-d,1); e=min(siz(1:2)-d,siz(1:2)); s1=2-min(1-d,1); e1=e-s+s1;
    I1(s1(1):e1(1),s1(2):e1(2),:) = I(s(1):e(1),s(2):e(2),:);
  else % handle general transformations
    for j=1:nCh, I1(:,:,j)=imtransform2(I(:,:,j),H,'method',method); end
  end
  % crop and store result
  I2 = I1(p(1)+1:end-p(1),p(2)+1:end-p(2),:);
  if(nd==2), IJ(:,:,i)=I2; else IJ(:,:,:,i)=I2;  end
end
% finally flip each resulting image
if(flip), IJ=cat(nd+1,IJ,IJ(:,end:-1:1,:,:)); end
end
