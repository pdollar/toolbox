% Steerable Gaussian derivative filter.
%
% This function is meant for visualization only.  It is a demonstration of steerable
% filters.
%
% Analytically find Gx = dxG and Gy = dxG.  Then find the derivative of G in some
% arbitrary direction theta by taking a linear combination of Gx and Gy.  
%
% INPUTS
%   theta   - orientation
%
% EXAMPLE
%   filter_steerable( 30 )
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function filter_steerable( theta )
    % Get G (could alternatively use fspecial but need phi)
    [x,y]=meshgrid(-1:.1:1, -1:.1:1 );
    r = sqrt( x.^2 + y.^2 );
    G = exp( -r .* r *2 );

    % get first derivative in x, y, and linear comb in theta
    phi = atan2( y, x );
    Gx = r .* cos(phi) .* G;  
    Gy = r .* sin(phi) .* G;
    Gtheta = cos(theta)*Gx + sin(theta)*Gy;
    
    % show (scale for visualization purposes)
    figure(1); im( [G Gx*2 Gy*2 Gtheta*2 ]  );
