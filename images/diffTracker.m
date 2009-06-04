function [delta,err] = diffTracker( I0, I1, sigma )
% Fast, robust estimation of translational offset between a pair of images.
%
% Approximates the translational offset between two images by assuming the
% images lie on linear manifold. Specifically, assumes that if I0 and I1
% are a pair of images related by a translation [dx dy], then (I0+I1)/2 is
% the image exactly halfway between I0 and I1 (ie I0 translated by [dx/2
% dy/2]). The above only holds for small translations and spatially smooth
% images. As such the input images typically need to be spatially smoothed
% first, the amount of necessary smoothing will increase as the size of
% translation increases (experiment for best results). The code is quite
% fast, the bottleneck is the spatial smoothing. More accurate results can
% be optained by iterating between estimating the translation and applying
% the resulting translation.
%
% The actual computation is performed as follows. First we generate an
% artificial translation of I0 by 1 pixel in x and y, and store the results
% in Tx and Ty respectively. The linearity assumption then tells us that:
%  I1 = I0 + (I0-Tx) * dx + (I0-Ty) * dy
% Only dx and dy are unknown in the resulting overcomplete set of linear
% equations, least squares is then used. The error of the estimate can be
% used as a measure of the quality of the linear fit.
%
% This function was inspired by the beautiful work ok Yang et al.:
%   H. Yang, M. Pollefeys, G. Welch, J. Frahm, and A. Ilie. Differential
%   camera tracking through linearizing the local appearance manifold.
%   CVPR, 2007.
%
% USAGE
%  [delta,err] = diffTracker( I0, I1, sigma )
%
% INPUTS
%  I0       - reference grayscale double image
%  I1       - translated version of I0
%  sigma    - amount of Gaussian spatial smoothing to apply
%
% OUTPUTS
%  delta    - estimated dx/dy
%  err      - squared error of estimate
%
% EXAMPLE
%  I = imread('cameraman.tif'); dx=3; dy=5;
%  I0=I(1+dy:end,1+dx:end); figure(1); im(I0);
%  I1=I(1:end-dy,1:end-dx); figure(2); im(I1);
%  tic, [delta,err] = diffTracker( I0, I1, 10 ), toc
%
% See also
%
% Piotr's Image&Video Toolbox      Version 2.31
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% smooth images, keep only valid region
if( sigma>0 ), I0 = gaussSmooth( I0, sigma, 'valid' ); end
if( sigma>0 ), I1 = gaussSmooth( I1, sigma, 'valid' ); end

% I0 translated by 1 pixel both in x and y, crop I0/I1 so dims match
Ty = I0(2:end,1:end-1); Tx = I0(1:end-1,2:end);
I0 = I0(1:end-1,1:end-1); I1 = I1(1:end-1,1:end-1);

% I1 = I0 + (I0-Tx)*dx + (I0-Ty)*dy, recover delta accordingly
dI1=I1(:)-I0(:); dIy=I0(:)-Ty(:); dIx=I0(:)-Tx(:);
delta = -[dIx dIy] \ dI1;

% compute squared error (if over certain threshold may wish to discard)
err = sum((-[dIx dIy]*delta - dI1).^2) / length(dI1);

end
