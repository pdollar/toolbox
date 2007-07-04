% 2D difference of offset Gaussian (DooG) filters.
%
% Creates a 2D derivative of Gaussian kernel.  Use primarily for
% visualization purposes. For filtering better to use the indvidiual
% seperable kernels for efficiency purposes.
% 
% USAGE
%  dG = filter_DOOG_2D( r, sigmas, nderivs, [show] )
%
% INPUTS
%  r       - final mask will be NxN where N=2r+1
%  sigmas  - sigmas for 2D Gaussian
%  nderivs - order of derivative along each dimension
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  dG      - The derivative of Gaussian mask
%
% EXAMPLE
%  dG = filter_DOOG_2D( 20, [3 3], [1,1], 1 );
%
% See also FILTER_DOOG_1D, FILTER_DOOG_3D, FILTER_DOG_2D, FILTER_GABOR_2D

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function dG = filter_DOOG_2D( r, sigmas, nderivs, show )

if( nargin<4 || isempty(show) ); show=0; end;

% get initial Gaussian
dG1 = fspecial( 'Gaussian', [2*r+1,1], sigmas(2) );  
dG2 = fspecial( 'Gaussian', [1,2*r+1], sigmas(1) );  
dG = dG1 * dG2;   

% take derivative of kernel appropriately
dx = .5*[-1 0 1];
for i=1:nderivs(1); dG = conv2( dG, dx, 'same' ); end;
for i=1:nderivs(2); dG = conv2( dG, dx', 'same' ); end;

% normalize (don't need to adjust mean since DOOG always have 0 mean)
dG=dG/norm(dG(:),1);

% display
if( show )
  filter_visualize_2D( dG, 0, show );
  title( ['sigs=[' num2str(sigmas) '], derivs=[' num2str( nderivs ) ']']);
end