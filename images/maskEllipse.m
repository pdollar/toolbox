function mask = maskEllipse( mrows, ncols, varargin )
% Creates a binary image of an ellipse.
%
% Creats a binary image of size (mrows x ncols), with all pixels off except
% inside of the specified ellipse.  The ellipse is given by 5 parameters, a
% semimajor axis of ra, a semminor axis of radius rb, angle phi (in
% radians), centered at (crow,ccol).An alternative method of specifying the
% ellipse parameters is in terms of the parameters of a 2d gaussian.  For
% more information on how a gaussian relates to an ellipse see
% gauss2ellipse.
%
% USAGE
%  mask = maskEllipse( mrows, ncols, crow, ccol, ra, rb, phi )
%  mask = maskEllipse( mrows, ncols, mu, C, [rad] )
%
% INPUTS [version 1]
%  mrows   - number of rows in mask
%  ncols   - number of columns in mask
%  crow    - the row location of the center of the ellipse
%  ccol    - the column location of the center of the ellipse
%  ra      - semi-major axis length (in pixels) of the ellipse
%  rb      - semi-minor axis length (in pixels) of the ellipse
%  phi     - rotation angle (in radians) of semimajor axis to x-axis
%
% INPUTS [version 2]
%  mrows   - number of rows in mask
%  ncols   - number of columns in mask
%  mu      - 1x2 vector representing the center of the ellipse
%  C       - 2x2 cov matrix
%  rad     - [2] Number of std to create the ellipse to
%
% OUTPUTS
%  mask    - created image mask
%
% EXAMPLE
%  mask = maskEllipse(  200, 200, 40, 100,  20, 15, pi/4 );
%  figure(1); im(mask); [mu,C] = imMlGauss( mask, 0, 2 );
%
% See also PLOTELLIPSE, GAUSS2ELLIPSE, MASKCIRCLE, MASKGAUSSIANS, IMMLGAUSS
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin==7 )
  [crow, ccol, ra, rb, phi] = deal( varargin{:} );
elseif( nargin==4 )
  [mu, C] = deal( varargin{:} );
  [crow, ccol, ra, rb, phi] = gauss2ellipse( mu, C );
elseif( nargin==5 )
  [mu, C, rad] = deal( varargin{:} );
  [crow, ccol, ra, rb, phi] = gauss2ellipse( mu, C, rad );
else
  error( ['Incorrect number of input arguments: ' int2str(nargin)] );
end;

% compute the leftmost and rightmost points of the ellipse
raCos=ra*cos(pi-phi); rbCos=rb*cos(pi-phi);
raSin=ra*sin(pi-phi); rbSin=rb*sin(pi-phi);
d = sqrt(raCos*raCos + rbSin*rbSin);
cRad = abs(raCos*raCos/d + rbSin*rbSin/d);
c0 = max( ceil(ccol-cRad), 1 );
c1 = min( floor(ccol+cRad), ncols );
B = rbSin / raCos; B2=B*B;

% compute and add the top/bottom points for each c
mask = zeros( mrows, ncols );
for c=c0:c1
  A=(c-ccol)/raCos; C=sqrt(max(0,B2-A*A+1));
  r0 = crow - raSin*(A-B*C)/(B2+1) + rbCos*(A*B+C)/(B2+1);
  r1 = crow - raSin*(A+B*C)/(B2+1) + rbCos*(A*B-C)/(B2+1);
  if(r0>r1), tmp=r0; r0=r1; r1=tmp; end
  r0 = max( ceil(r0-.0001), 1 );
  r1 = min( floor(r1+.0001), mrows );
  mask( r0:r1, c ) = 1;
end
