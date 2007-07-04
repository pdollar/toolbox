% Creates an even/odd pair of 2D Gabor filters.
%
% Creates a pair of Gabor filters (one odd one even) at the specified
% orientation. For Thomas' ECCV98 filters, use sig=sqrt(2), lam=4.  Note
% that originally this function computed a quadratic masked with a
% Gaussian, and not a sin/cos masked with a Gaussian.
%
% USAGE
%  [Feven,Fodd] = filter_gabor_2D( r, sig, lam, theta, [omega], [show] )
%
% INPUTS
%  r       - final mask will be 2r+1 x 2r+1
%  sig     - standard deviation of Gaussian mask
%  lam     - elongation of Gaussian mask
%  theta   - orientation (in degrees)
%  omega   - wavlength of underlying sine (sould be >1)
%  show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%  Feven   - even symmetric filter (-cosine masked with Gaussian)
%  Fodd    - even symmetric filter (-sine masked with Gaussian)
%
% EXAMPLE
%  [Feven,Fodd] = filter_gabor_2D(15,sqrt(2),4,45,1,1);
%  [Feven,Fodd] = filter_gabor_2D(25,4,2,0,2,3);
%
% See also FILTER_GABOR_1D, FILTER_GAUSS_ND

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [Feven,Fodd] = filter_gabor_2D( r, sig, lam, theta, omega, show )

if( nargin<5 || isempty(omega) ); omega=1; end;
if( nargin<6 || isempty(show) ); show=0; end;

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
  filter_visualize_2D( Feven, 0, show );
  filter_visualize_2D( Fodd, 0, show+1 );  
end;
