% Plots 2D ellipses derived from 2D Gaussians specified by mus & Cs.  
%
% INPUTS
%   mu      - kx2 matrix of means
%   Cs      - 2 x 2 x k  covariance matricies
%   d       - [optional] Number of std to create the ellipse to (2 is default)
%
% EXAMPLE
%   plot_gaussellipses( [ 10 10 ], eye(2), 2 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also PLOT_ELLIPSE, GAUSS2ELLIPSE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function plot_gaussellipses( mus, Cs, d )
    if (nargin<3 || isempty(d) ) d=2; end;
    colors = ['b', 'g', 'r', 'c', 'm', 'y', 'k']; nc = length(colors);
    
    washeld = ishold; if (~washeld) hold('on'); end;
    for i=1:size( mus,1)
        [ crow, ccol, ra, rb, phi ] = gauss2ellipse( mus(i,:), Cs(:,:,i), d );
        plot_ellipse( crow, ccol, ra, rb, phi, colors( mod(i-1,nc)+1) ); 
    end
    if (~washeld) hold('off'); end;
           
