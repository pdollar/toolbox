function mask = maskCircle( angleStart, angleSiz, r, nSamples )
% Creates an image of a 'pie slice' of a circle.
%
% Creates a 2D array of size (2rx2r) with values between 0 and 1.
% Specifically, mask has values 1 inside the pie slice of the circle
% defined by angleStart and angleSiz.  For example, using
% angleStart=-pi/4 and angleSiz=pi/2 would give a quarter circle facing
% right.  nsample conrols the accuracty of the circle at its boundaries.
% That is if nSamples>1, pixels at the boundary which will have fractions
% values (when a pixel should be say half inside the circle and half
% outside of the circle).  Note that running time is
% O(nSamples^2*radius^2), so don't use a value that is too high for either.
% A series of masks whose angles together go from 0-2pi will sum exactly to
% form a radius r circle. r may be either an integer, or an integer + .5. A
% pixel is considered to belong to the circle iff it is within the given
% angle and has a value strictly smaller then r.
% 
% USAGE
%  mask = maskCircle( angleStart, angleSiz, r, [nSamples] )
%
% INPUTS
%  angleStart   - start position of circle
%  angleSiz     - number of radians to continue circle for
%  r            - mask radius (integer or integer+.5)
%  nSamples     - [1] controls sampling accuracy
%
% OUTPUTS
%  mask         - the created image, size 2r by 2r
%
% EXAMPLE
%  mask1 = maskCircle( -pi/8, pi/4, 20, 20 ); figure(1); im(mask1); 
%  mask2 = maskCircle( pi/8, pi/8, 20, 20 );  figure(2); im(mask2); 
%  figure(3); im(mask1+mask2);
%
% See also MASKELLIPSE, MASKSPHERE
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(nSamples) ); nSamples = 1; end

% create circle
sampling = -(r-.5/nSamples):1/nSamples:(r-.5/nSamples);
mask = zeros(nSamples*r*2);     
[x,y] = meshgrid(sampling, -sampling);
mask( x.^2+y.^2<r^2 ) = 1;

% keep only values at appropriate angles
angles = atan2(y,x); angles(angles<0)=angles(angles<0)+2*pi;
angleEnd = mod( angleStart + angleSiz, 2*pi );
angleStart = mod( angleStart, 2*pi );
if (angleStart<angleEnd)
  mask( angles<angleStart | angles>=angleEnd ) = 0;
else
  mask( angles>=angleEnd & angles<angleStart ) = 0;
end

% shrink by counting samples per 'image' pixel
if (nSamples>1)
  mask = localSum( mask, nSamples, 'valid' );
  sampling= 1:nSamples:nSamples*r*2; 
  mask = mask(sampling,sampling) / nSamples^2;
end
