% Creates a binary image of an ellipse.
%
% Creats a binary image of size (mrows x ncols), with all pixels off except inside of the
% specified ellipse.  The ellipse is given by 5 parameters,  a semimajor axis of ra, a
% semminor axis of radius rb, angle phi (in radians), centered at (crow,ccol).
%
% An alternative method of specifying the ellipse parameters is in terms of the parameters
% of a 2d gaussian.  For more information on how a gaussian relates to an ellipse see
% gauss2ellipse.
% 
% USAGE
%   mask = mask_ellipse( mrows, ncols, crow, ccol, ra, rb, phi )
%   mask = mask_ellipse( mrows, ncols, mu, C, d )
%
% INPUTS
%   % version 1
%   mrows   - number of rows in mask
%   ncols   - number of columns in mask
%   crow    - the row location of the center of the ellipse
%   ccol    - the column location of the center of the ellipse
%   ra      - semi-major axis length (in pixels) of the ellipse
%   rb      - semi-minor axis length (in pixels) of the ellipse
%   phi     - rotation angle (in radians) of the semimajor axis from the x-axis
%   % version 2
%   mrows   - number of rows in mask
%   ncols   - number of columns in mask
%   mu      - 1x2 vector representing the center of the ellipse
%   C       - 2x2 cov matrix
%   d       - [optional] Number of std to create the ellipse to (2 is default)
%
% OUTPUTS
%   mask    - created image mask
%
% EXAMPLE
%   mask = mask_ellipse(  200, 200, 40, 100,  20, 15, pi/4 );
%   figure(1); im(mask); [mu,C] = imageMLG( mask, 0, 2 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also PLOT_ELLIPSE, GAUSS2ELLIPSE, MASK_CIRCLE, MASK_GAUSSIANS, IMAGEMLG

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function mask = mask_ellipse( mrows, ncols, varargin )
    if( nargin==7 )
        [crow, ccol, ra, rb, phi] = deal( varargin{:} );
    elseif( nargin==4 )
        [mu, C] = deal( varargin{:} );
        [crow, ccol, ra, rb, phi] = gauss2ellipse( mu, C );
    elseif( nargin==5 )
        [mu, C, d] = deal( varargin{:} );
        [crow, ccol, ra, rb, phi] = gauss2ellipse( mu, C, d );
    else
        error( ['Incorrect number of input arguments: ' int2str(nargin)] );
    end;
        
        
    % get indicies of locations inside ellipse
    [n, locs] = mask_ellipse1( crow, ccol, ra, rb, phi, mrows, ncols );
    
    % create binary mask
    locs = double( locs(1:n,:) );
    inds = locs(:,1) + (mrows)*(locs(:,2)-1); 
    mask = zeros( mrows, ncols );
    mask( inds ) = 1;
