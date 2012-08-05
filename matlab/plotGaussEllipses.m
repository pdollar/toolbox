function hs = plotGaussEllipses( mus, Cs, rad )
% Plots 2D ellipses derived from 2D Gaussians specified by mus & Cs.
%
% USAGE
%  hs = plotGaussEllipses( mus, Cs, [rad] )
%
% INPUTS
%  mus     - k x 2 matrix of means
%  Cs      - 2 x 2 x k  covariance matricies
%  rad     - [2] Number of std to create the ellipse to
%
% OUTPUTS
%  hs      - handles to ellipses
%
% EXAMPLE
%  plotGaussEllipses( [ 10 10; 10 10 ], cat(3,eye(2),eye(2)*2) );
%
% See also PLOTELLIPSE, GAUSS2ELLIPSE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if (nargin<3 || isempty(rad) ); rad=2; end
colors = ['b', 'g', 'r', 'c', 'm', 'y', 'k']; nc = length(colors);

washeld = ishold; if (~washeld); hold('on'); end
hs = zeros( size(mus,1),1 );
for i=1:size( mus,1)
  [ cRow, ccol, ra, rb, phi ] = gauss2ellipse( mus(i,:), Cs(:,:,i), rad );
  hs(i)=plotEllipse( cRow, ccol, ra, rb, phi, colors( mod(i-1,nc)+1) );
end
if (~washeld); hold('off'); end
