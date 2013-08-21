function H = hog( I, binSize, nOrients, clip, crop )
% Efficiently compute histogram of oriented gradient (HOG) features.
%
% Heavily optimized code to compute HOG features described in "Histograms
% of Oriented Gradients for Human Detection" by Dalal & Triggs, CVPR05.
% This function is made largely obsolete by fhog, see fhog.m for details.
%
% If I has dimensions [hxw], the size of the computed feature vector H is
% floor([h/binSize w/binSize nOrients*4]). For each binSize x binSize
% region, computes a histogram of gradients, with each gradient quantized
% by its angle and weighed by its magnitude. For color images, the gradient
% is computed separately for each color channel and the one with maximum
% magnitude is used. The centered gradient is used except at boundaries
% (where uncentered gradient is used). Trilinear interpolation is used to
% place each gradient in the appropriate spatial and orientation bin.
%
% For each resulting histogram (with nOrients bins), four different
% normalizations are computed using adjacent histograms, resulting in a
% nOrients*4 length feature vector for each region. To compute the
% normalizations, first for each block of adjacent 2x2 histograms we
% compute their L2 norm (over all 4*nOrient bins). Each histogram (except
% at boundaries) thus has 4 different normalization values associated with
% it. Each histogram bin is then normalized by each of the 4 different L2
% norms, resulting in a 4 times expansion of the number of bins. Finally,
% any bin whose value is bigger than "clip" is set to "clip".
%
% The computed features are NOT identical to those described in the CVPR05
% paper. Specifically, there is no Gaussian spatial window, and other minor
% details differ. The choices were made for speed of the resulting code:
% ~.008s for a 640x480x3 color image on a standard machine from 2011.
%
% This function is essentially a wrapper for calls to gradientMag()
% and gradientHist(). Specifically, it is equivalent to the following:
%  [M,O] = gradientMag( I ); softBin = 1; useHog = 1;
%  H = gradientHist(M,O,binSize,nOrients,softBin,useHog,clip);
% See gradientHist() for more general usage.
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  H = hog( I, [binSize], [nOrients], [clip], [crop] )
%
% INPUTS
%  I        - [hxw] color or grayscale input image (must have type single)
%  binSize  - [8] spatial bin size
%  nOrients - [9] number of orientation bins
%  clip     - [.2] value at which to clip histogram bins
%  crop     - [0] if true crop boundaries
%
% OUTPUTS
%  H        - [h/binSize w/binSize nOrients*4] computed hog features
%
% EXAMPLE
%  I=imResample(single(imread('peppers.png')),[480 640])/255;
%  tic, for i=1:125, H=hog(I,8,9); end; toc % ~1s for 125 iterations
%  figure(1); im(I); V=hogDraw(H,25); figure(2); im(V)
%
% See also hogDraw, gradientHist
%
% Piotr's Image&Video Toolbox      Version 3.23
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 ), binSize=8; end
if( nargin<3 ), nOrients=9; end
if( nargin<4 ), clip=.2; end
if( nargin<5 ), crop=0; end

softBin = 1; useHog = 1; b = binSize;
[M,O] = gradientMag( I );
H = gradientHist(M,O,binSize,nOrients,softBin,useHog,clip);
if( crop ), e=mod(size(I),b)<b/2; H=H(2:end-e(1),2:end-e(2),:); end

end
