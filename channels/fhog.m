function H = fhog( I, binSize, nOrients, clip, crop )
% Efficiently compute Felzenszwalb's HOG (FHOG) features.
%
% A fast implementation of the HOG variant used by Felzenszwalb et al.
% in their work on discriminatively trained deformable part models.
%  http://www.cs.berkeley.edu/~rbg/latent/index.html
% Gives nearly identical results to features.cc in code release version 5
% but runs 4x faster (over 125 fps on VGA color images).
%
% The computed HOG features are 3*nOrients+5 dimensional. There are
% 2*nOrients contrast sensitive orientation channels, nOrients contrast
% insensitive orientation channels, 4 texture channels and 1 all zeros
% channel (used as a 'truncation' feature). Using the standard value of
% nOrients=9 gives a 32 dimensional feature vector at each cell. This
% variant of HOG, refered to as FHOG, has been shown to achieve superior
% performance to the original HOG features. For details please refer to
% work by Felzenszwalb et al. (see link above).
%
% This function is essentially a wrapper for calls to gradientMag()
% and gradientHist(). Specifically, it is equivalent to the following:
%  [M,O] = gradientMag( I,0,0,0,1 ); softBin = -1; useHog = 2;
%  H = gradientHist(M,O,binSize,nOrients,softBin,useHog,clip);
% See gradientHist() for more general usage.
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  H = fhog( I, [binSize], [nOrients], [clip], [crop] )
%
% INPUTS
%  I        - [hxw] color or grayscale input image (must have type single)
%  binSize  - [8] spatial bin size
%  nOrients - [9] number of orientation bins
%  clip     - [.2] value at which to clip histogram bins
%  crop     - [0] if true crop boundaries
%
% OUTPUTS
%  H        - [h/binSize w/binSize nOrients*3+5] computed hog features
%
% EXAMPLE
%  I=imResample(single(imread('peppers.png'))/255,[480 640]);
%  tic, for i=1:100, H=fhog(I,8,9); end; disp(100/toc) % >125 fps
%  figure(1); im(I); V=hogDraw(H,25,1); figure(2); im(V)
%
% EXAMPLE
%  % comparison to features.cc (requires DPM code release version 5)
%  I=imResample(single(imread('peppers.png'))/255,[480 640]); Id=double(I);
%  tic, for i=1:100, H1=features(Id,8); end; disp(100/toc)
%  tic, for i=1:100, H2=fhog(I,8,9,.2,1); end; disp(100/toc)
%  figure(1); montage2(H1); figure(2); montage2(H2);
%  D=abs(H1-H2); mean(D(:))
%
% See also hog, hogDraw, gradientHist
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 ), binSize=8; end
if( nargin<3 ), nOrients=9; end
if( nargin<4 ), clip=.2; end
if( nargin<5 ), crop=0; end

softBin = -1; useHog = 2; b = binSize;
[M,O] = gradientMag( I,0,0,0,1 );
H = gradientHist(M,O,binSize,nOrients,softBin,useHog,clip);
if( crop ), e=mod(size(I),b)<b/2; H=H(2:end-e(1),2:end-e(2),:); end

end
