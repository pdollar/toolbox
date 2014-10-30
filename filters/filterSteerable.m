function filterSteerable( theta )
% Steerable 2D Gaussian derivative filter (for visualization).
%
% This function is a demonstration of steerable filters.  The directional
% derivative of G in an arbitrary direction theta can be found by taking a
% linear combination of the directional derivatives dxG and dyG.
%
% USAGE
%  filterSteerable( theta )
%
% INPUTS
%  theta   - orientation in radians
%
% OUTPUTS
%
% EXAMPLE
%  filterSteerable( pi/4 );
%
% See also filterGauss
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% Get G
[x,y]=meshgrid(-1:.1:1, -1:.1:1 );
r = sqrt( x.^2 + y.^2 );
G = exp( -r .* r *2 );

% get first derivatives of G.  note: d/dx(G)=-2x*G
phi = atan2( y, x );
dxG = r .* cos(phi) .* G;
dyG = r .* sin(phi) .* G;

% get directional derivative by taking linear comb in theta
Gtheta = cos(theta)*dxG + sin(theta)*dyG;

% dislpay (scale for visualization purposes)
GS = cat(3,G,dxG*2,dyG*2,Gtheta*2);
figure(1); montage2( GS );
