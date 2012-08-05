function mask = maskEllipse( mRows, nCols, varargin )
% Creates a binary image of an ellipse.
%
% Creates a binary image of size (mRows x nCols), with all pixels set to 0
% outside the ellipse and 1 inside.  The ellipse is given by 5 parameters,
% a semimajor axis of ra, a semminor axis of radius rb, angle phi (in
% radians), and center (cRow,cCol). An alternative method of specifying the
% ellipse parameters is in terms of a 2D Gaussian. For more info on how a
% Gaussian relates to an ellipse see gauss2ellipse.
%
% USAGE
%  mask = maskEllipse( mRows, nCols, cRow, cCol, ra, rb, phi )
%  mask = maskEllipse( mRows, nCols, mu, C, [rad] )
%
% INPUTS [version 1]
%  mRows   - number of rows in mask
%  nCols   - number of columns in mask
%  cRow    - the row location of the center of the ellipse
%  cCol    - the column location of the center of the ellipse
%  ra      - semi-major axis length (in pixels) of the ellipse
%  rb      - semi-minor axis length (in pixels) of the ellipse
%  phi     - rotation angle (in radians) of semimajor axis to x-axis
%
% INPUTS [version 2]
%  mRows   - number of rows in mask
%  nCols   - number of columns in mask
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
% Piotr's Image&Video Toolbox      Version 2.40
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin==7 )
  [cRow, cCol, ra, rb, phi] = deal( varargin{:} );
elseif( nargin==4 )
  [mu, C] = deal( varargin{:} );
  [cRow, cCol, ra, rb, phi] = gauss2ellipse( mu, C );
elseif( nargin==5 )
  [mu, C, rad] = deal( varargin{:} );
  [cRow, cCol, ra, rb, phi] = gauss2ellipse( mu, C, rad );
else
  error( ['Incorrect number of input arguments: ' int2str(nargin)] );
end;

% compute the leftmost and rightmost points of the ellipse
raCos=ra*cos(pi-phi); rbCos=rb*cos(pi-phi);
raSin=ra*sin(pi-phi); rbSin=rb*sin(pi-phi);
d = sqrt(raCos*raCos + rbSin*rbSin);
cRad = abs(raCos*raCos/d + rbSin*rbSin/d);
c0 = max( ceil(cCol-cRad), 1 );
c1 = min( floor(cCol+cRad), nCols );
B = rbSin / raCos; B2=B*B;

% compute and add the top/bottom points for each c
mask = zeros( mRows, nCols );
for c=c0:c1
  A=(c-cCol)/raCos; C=sqrt(max(0,B2-A*A+1));
  r0 = cRow - raSin*(A-B*C)/(B2+1) + rbCos*(A*B+C)/(B2+1);
  r1 = cRow - raSin*(A+B*C)/(B2+1) + rbCos*(A*B-C)/(B2+1);
  if(r0>r1), tmp=r0; r0=r1; r1=tmp; end
  r0 = max( ceil(r0-.0001), 1 );
  r1 = min( floor(r1+.0001), mRows );
  mask( r0:r1, c ) = 1;
end
