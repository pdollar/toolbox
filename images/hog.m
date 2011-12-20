function H = hog( I, varargin )
% Efficiently compute histogram of oriented gradient (HOG) features.
%
% Code to compute HOG features as described in "Histograms of Oriented
% Gradients for Human Detection" by Dalal & Triggs, CVPR05. Various speedup
% tricks adopted from the HOG code feature.cpp by Deva Ramanan.
%
% If I has dimensions [mxn], the size of the computed feature vector H is
% [m/sBin-2 n/sBin-2 oBin*4]. For each non-overlapping sBin x sBin region,
% computes a histogram of gradients, with each gradient quantized by it's
% angle and weighed by its magnitude. For color images, the gradient is
% computed separately for each color channel and the one with maximum
% magnitude is used. The centered gradient is used except at boundaries
% (where uncentered gradient is used). Trilinear interpolation is used to
% place each gradient in the appropriate spatial and orientation bin. For
% each resulting histogram (with oBin bins), four different normalizations
% are computed using adjacent histograms, resulting in an oBins*4 length
% feature vector for each region. Boundary regions are discarded.
%
% The computed features are NOT identical to those described in the CVPR05
% paper. Specifically, there is no Gaussian spatial window, and other minor
% details differ. The choices were made for speed of the resulting code:
% ~.1s for a 640x480x3 color image on a standard machine from 2005.
%
% USAGE
%  H = hog( I, [sBin], [oBin] )
%
% INPUTS
%  I        - [mxn] color or grayscale input image (must have type double)
%  sBin     - [8] spatial bin size
%  oBin     - [9] number of orientation bins
%
% OUTPUTS
%  H        - [m/sBin-2 n/sBin-2 oBin*4] computed hog features
%
% EXAMPLE
%  I=double(imread('cameraman.tif')); figure(1); im(I)
%  tic, H=hog(I,8,9); toc, V=hogDraw(H,25); figure(2); im(V)
%
% See also hogDraw
%
% Piotr's Image&Video Toolbox      Version 2.62
% Copyright 2011 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

H = hog1( I, varargin{:} );
