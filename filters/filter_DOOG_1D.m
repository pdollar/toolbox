% 1D difference of offset Gaussian (DooG) filters.
%
% Creates a 1D derivative of Gaussian kernel.
%
%
% 
% USAGE
%  dG = filter_DOOG_1D( r, sig, nderiv, [show] )
%
% INPUTS
%  r       - final mask will have length N=2r+1
%  sig     - sigma for 1D Gaussian 
%  nderiv  - order of derivative 
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  dG      - The derivative of Gaussian mask
%
% EXAMPLE
%  dG = filter_DOOG_1D( 21, 2, 3, 1 );
%
% See also FILTER_DOOG_2D, FILTER_DOOG_3D

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function dG = filter_DOOG_1D( r, sig, nderiv, show )

if( nargin<4 || isempty(show) ); show=0; end;

% get initial Gaussian
dG = fspecial( 'Gaussian', [1,2*r+1], sig );  

% take derivative of kernel appropriately
dx = .5*[-1 0 1];
for i=1:nderiv; dG = conv2( dG, dx, 'same' ); end;

% normalize (don't need to adjust mean since DOOG always have 0 mean)
dG=dG/norm(dG(:),1);

% display
if( show )
  filter_visualize_1D( dG, show );
  title( ['sigs=[' num2str(sig) '], derivs=[' num2str( nderiv ) ']']);
end