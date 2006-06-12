% Creates an ellipse representing the 2D Gaussian distribution.
% 
% Creates an ellipse representing the 2D Gaussian distribution with mean mu and covariance
% matrix C.  Returns 5 parameters that specify the ellipse: a semimajor axis of ra, a
% semiminor axis of radius rb, angle phi, centered at (crow,ccol).  
%
% INPUTS
%   mu  - 1x2 vector representing the center of the ellipse
%   C   - 2x2 cov matrix
%   d   - [optional] Number of std to create the ellipse to (2 is default)
%
% OUTPUTS
%   crow    - the row location of the center of the ellipse
%   ccol    - the column location of the center of the ellipse
%   ra      - semi-major axis length (in pixels) of the ellipse
%   rb      - semi-minor axis length (in pixels) of the ellipse
%   phi     - rotation angle (in radians) of the semimajor axis from the x-axis
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also PLOT_ELLIPSE, PLOT_GAUSSELLIPSES, MASK_ELLIPSE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [ crow, ccol, ra, rb, phi ] = gauss2ellipse( mu, C, d )
    if (nargin<3 || isempty(d) ) d=2; end;

    % error check
    if (~all(size(mu)==[1,2]) || ~all(size(C)==[2,2])) 
        error('Works only for 2D Gaussians'); end
    
    % decompose using SVD
    [R,D,R] = svd(C);
    normstd = sqrt( diag( D ) );

    
    % get angle of rotation (in row/column format)
    phi = acos(R(1,1));
    if (R(2,1) < 0) phi = 2*pi - phi; end
    phi = pi/2 - phi;
    
    % get ellipse radii
    ra = d*normstd(1);
    rb = d*normstd(2); 

    % center of ellipse
    crow = mu(1);
    ccol = mu(2);
