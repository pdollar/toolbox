function [Feven,Fodd] = filterGabor2d( r, sig, lam, theta, omega, show )
% Creates an even/odd pair of 2D Gabor filters.
%
% Creates a pair of Gabor filters (one odd one even) at the specified
% orientation. For Thomas' ECCV98 filters, use sig=sqrt(2), lam=4.  Note
% that originally this function computed a quadratic masked with a
% Gaussian, and not a sin/cos masked with a Gaussian. Requires Matlab's
% 'Signal Processing Toolbox'.
%
% USAGE
%  [Feven,Fodd] = filterGabor2d( r, sig, lam, theta, [omega], [show] )
%
% INPUTS
%  r       - final mask will be 2r+1 x 2r+1
%  sig     - standard deviation of Gaussian mask
%  lam     - elongation of Gaussian mask
%  theta   - orientation (in degrees)
%  omega   - [1] wavlength of underlying sine (sould be >=1)
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  Feven   - even symmetric filter (-cosine masked with Gaussian)
%  Fodd    - odd symmetric filter (-sine masked with Gaussian)
%
% EXAMPLE
%  [Feven,Fodd] = filterGabor2d(15,sqrt(2),4,45,1,1);
%  [Feven,Fodd] = filterGabor2d(25,4,2,0,2,3);
%
% See also FILTERGABOR1D, FILTERGAUSS
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.12
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<5 || isempty(omega) ); omega=1; end
if( nargin<6 || isempty(show) ); show=0; end

% create even/odd Gabor filters
[x,y]=meshgrid(-r:r,-r:r);
mask = exp(-(y.^2)/(sig^2)-(x.^2)/(lam^2*sig^2));
Feven = -cos(2*pi*y/4/omega) .* mask;
%Feven = (4*(y.^2)/(sig^4)-2/(sig^2)).*mask; % original function was y.^2
Fodd = imag(hilbert(Feven));

% orient appropriately
Feven = imrotate(Feven,theta,'bil','crop');
Fodd = imrotate(Fodd,theta,'bil','crop');

% Set mean to 0 (should already be 0)
Feven=Feven-mean(Feven(:));
Fodd=Fodd-mean(Fodd(:));

% set L1norm to 0
Feven=Feven/norm(Feven(:),1);
Fodd=Fodd/norm(Fodd(:),1);

% display
if( show )
  filterVisualize( Feven, show );
  filterVisualize( Fodd, show+1 );
end
