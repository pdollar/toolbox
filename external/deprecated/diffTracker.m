function [delta,err] = diffTracker( I0, I1, sig, ss )
% Fast, robust estimation of translation/scale change between two images.
%
% Approximates the translational offset between two images by assuming the
% images lie on linear manifold. Specifically, assumes that if I0 and I1
% are a pair of images related by a translation [dx dy], then (I0+I1)/2 is
% the image exactly halfway between I0 and I1 (ie I0 translated by [dx/2
% dy/2]). The above only holds for small translations and spatially smooth
% images. As such the input images typically need to be spatially smoothed
% first, the amount of necessary smoothing will increase as the size of
% translation increases (experiment for best results). The code is quite
% fast, the bottleneck is the spatial smoothing.
%
% The actual computation is performed as follows. First we generate an
% artificial translation of I0 by 1 pixel in x and y, and store the results
% in Tx and Ty. Also, if ss>1, we generate an artificial scaling Ts of I0
% by upsampling by a factor of ss. The linearity assumption tells us that:
%  I1 = I0 + (I0-Tx) * dx + (I0-Ty) * dy +  (I0-Ts) * ds
% Only dx, dy and possibly ds are unknown in the resulting overcomplete set
% of linear equations, least squares is then used. The error of the
% estimate can be used as a measure of the quality of the linear fit.
%
% This function was inspired by the beautiful work ok Yang et al.:
%   H. Yang, M. Pollefeys, G. Welch, J. Frahm, and A. Ilie. Differential
%   camera tracking through linearizing the local appearance manifold.
%   CVPR, 2007.
%
% USAGE
%  [delta,err] = diffTracker( I0, I1, [sig], [ss] )
%
% INPUTS
%  I0       - reference grayscale double image
%  I1       - translated version of I0
%  sig      - [0] amount of Gaussian spatial smoothing to apply
%  ss       - [0] scale step for artificial scaling (if >1)
%
% OUTPUTS
%  delta    - estimated dx/dy/ds
%  err      - squared error of estimate
%
% EXAMPLE - translation only
%  I = double(imread('cameraman.tif'))/255; dx=3; dy=5;
%  I0=I(1+dy:end,1+dx:end); figure(1); im(I0);
%  I1=I(1:end-dy,1:end-dx); figure(2); im(I1);
%  tic, [delta,err] = diffTracker( I0, I1, 10 ), toc
%
% EXAMPLE - translation and scale
%  I0 = double(imread('coins.png'))/255; dx=9; dy=-2; ds=1.10;
%  H1 = [eye(2)*ds -[dy; dx]; 0 0 1];
%  I1 = imtransform2(I0,H1);
%  tic, [ds,err] = diffTracker( I0, I1, 25, 1.05 ), toc
%  H2 = [eye(2)*ds(3) -[ds(2); ds(1)]; 0 0 1];
%  I2 = imtransform2(I0,H2);
%  figure(1); im(I0); figure(2); im(I1); figure(3); im(I2);
%
% See also
%
% Piotr's Image&Video Toolbox      Version 2.61
% Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% get inputs
if(nargin<3 || isempty(sig)), sig=0; end
if(nargin<4 || isempty(ss)), ss=0; end

% smooth images, keep only valid region
if( sig>0 ), f=filterGauss(2*ceil(sig*2.25)+1,[],sig^2);
  I0 = conv2(conv2(I0,f','valid'),f,'valid');
  I1 = conv2(conv2(I1,f','valid'),f,'valid');
end

% I0 translated by 1 pixel both in x and y, crop I0/I1 so dims match
if(ss>1), Ts=arrayToDims(imResample(I0,ss),size(I0)); end
Ty = I0(2:end,1:end-1); Tx = I0(1:end-1,2:end);
I0 = I0(1:end-1,1:end-1); I1 = I1(1:end-1,1:end-1);

% I1 = I0 + (I0-Tx)*dx + (I0-Ty)*dy + (I0-Ts)*ds, recover delta accordingly
dI1=I1(:)-I0(:); dIy=I0(:)-Ty(:); dIx=I0(:)-Tx(:);
if(ss>1), Ts=Ts(1:end-1,1:end-1); dIs=I0(:)-Ts(:); else dIs=[]; end
delta = -[dIx dIy dIs] \ dI1;

% compute squared error (if over certain threshold may wish to discard)
if(nargout>1), err=sum((-[dIx dIy dIs]*delta - dI1).^2) / length(dI1); end

% put scale delta into units independent of ss
if(ss>1), delta(3)=ss^delta(3); end

end
