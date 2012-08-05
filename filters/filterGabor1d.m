function [feven,fodd] = filterGabor1d( r, sig, omega, show )
% Creates an even/odd pair of 1D Gabor filters.
%
% USAGE
%  [feven,fodd] = filterGabor1d( r, sig, omega, [show] )
%
% INPUTS
%  r       - final filter will be 2r+1 (good choice for r is r=2*sig)
%  sig     - standard deviation of Gaussian mask
%  omega   - frequency of underlying sine/cosine in [1/(2r+1) r/(2r+1)]
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  feven   - even symmetric filter (-cosine masked with Gaussian)
%  fodd    - odd symmetric filter (-sine masked with Gaussian)
%
% EXAMPLE
%  sig = 15; f=filterGabor1d(2*sig,sig,1/sig,1);
%
% See also FILTERGABOR2D
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(show) ); show=0; end;

r = ceil(r);  n=2*r+1;
if( omega<1/(n) || omega>r/(n) )
  error(['omega=' num2str(omega) ' out of range =[' num2str([1 r]/n) ']']);
end;

% create even and odd pair
x = -r:r;
feven = -cos(2*pi*x*omega) .* exp(-(x.^2)/sig^2);
fodd  = -sin(2*pi*x*omega) .* exp(-(x.^2)/sig^2); %=imag(hilbert(feven));

% normalize to mean==0, but only in locs that are nonzero
inds = abs(feven)>.00001;  feven(inds) = feven(inds) - mean(feven(inds));
inds = abs(fodd)>.00001;  fodd(inds) = fodd(inds) - mean(fodd(inds));

% set L1norm to 0
feven = feven/norm(feven(:),1);
fodd = fodd/norm(fodd(:),1);

% visualization
if( show )
  filterVisualize( feven, show );
  filterVisualize( fodd, show+1 );
end
