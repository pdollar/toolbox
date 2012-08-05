function G = filterDog2d( r, var, order, show )
% Difference of Gaussian (Dog) Filter.
%
% Adapted from code by Serge Belongie.  Takes a "Difference of Gaussian" -
% all centered on the same point but with different values for sigma. Also
% serves as an approximation to an Laplacian of Gaussian (LoG) filter (if
% order==1).
%
% USAGE
%  G = filterDog2d( r, var, order, [show] )
%
% INPUTS
%  r       - Final filter will be 2*r+1 on each side
%  var     - variance of central Gaussian
%  order   - should be either 1-LoG or 2-difference of 3 Gaussians
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  G       - filter
%
% EXAMPLE
%  G = filterDog2d( 40, 40, 1, 1 ); %order=1 (LoG)
%  G = filterDog2d( 40, 40, 2, 3 ); %order=2
%
% See also FILTERDOOG, FILTERGAUSS
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(show) ); show=0; end

% create filter
N = 2*r+1;
if (order==1)
  Ga = filterGauss( [N N], [], .71*var );
  Gb = filterGauss( [N N], [], 1.14*var );
  a=1; b=-1; G = a*Ga + b*Gb;

elseif (order==2)
  Ga = filterGauss( [N N], [], 0.62*var );
  Gb = filterGauss( [N N], [], var );
  Gc = filterGauss( [N N], [], 1.6*var );
  a=-1; b=2; c=-1; G = a*Ga + b*Gb + c*Gc;

else
  error('order must be 1 or 2');
end

% normalize
G=G-mean(G(:));
G=G/norm(G(:),1);

% display
if(show); filterVisualize( G, show, 'row' ); end
