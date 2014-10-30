function [cRow, cCol, ra, rb, phi] = gauss2ellipse( mu, C, rad )
% Creates an ellipse representing the 2D Gaussian distribution.
%
% Creates an ellipse representing the 2D Gaussian distribution with mean mu
% and covariance matrix C.  Returns 5 parameters that specify the ellipse.
%
% USAGE
%  [cRow, cCol, ra, rb, phi] = gauss2ellipse( mu, C, [rad] )
%
% INPUTS
%  mu      - 1x2 vector representing the center of the ellipse
%  C       - 2x2 cov matrix
%  rad     - [2] Number of std to create the ellipse to
%
% OUTPUTS
%  cRow    - the row location of the center of the ellipse
%  cCol    - the column location of the center of the ellipse
%  ra      - semi-major axis length (in pixels) of the ellipse
%  rb      - semi-minor axis length (in pixels) of the ellipse
%  phi     - rotation angle (radians) of semimajor axis from x-axis
%
% EXAMPLE
%  [cRow, cCol, ra, rb, phi] = gauss2ellipse( [5 5], [1 0; .5 2] )
%  plotEllipse( cRow, cCol, ra, rb, phi );
%
% See also PLOTELLIPSE, PLOTGAUSSELLIPSES, MASKELLIPSE
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if (nargin<3 || isempty(rad) ); rad=2; end;

% error check
if (~all(size(mu)==[1,2]) || ~all(size(C)==[2,2]))
  error('Works only for 2D Gaussians'); end

% decompose using SVD
[~,D,R] = svd(C);
normstd = sqrt( diag( D ) );

% get angle of rotation (in row/column format)
phi = acos(R(1,1));
if (R(2,1) < 0); phi = 2*pi - phi; end
phi = pi/2 - phi;

% get ellipse radii
ra = rad*normstd(1);
rb = rad*normstd(2);

% center of ellipse
cRow = mu(1);
cCol = mu(2);
