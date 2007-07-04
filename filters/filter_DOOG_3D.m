% 3D difference of offset Gaussian (DooG) filters.
%
% Creates a 3D derivative of Gaussian kernel.  Use primarily for
% visualization purposes. For filtering better to use the indvidiual
% seperable kernels for efficiency purposes.
% 
% USAGE
%  dG = filter_DOOG_3D( r, sigmas, nderivs, [show] )
%
% INPUTS
%  r       - final mask will be NxNxN where N=2r+1
%  sigmas  - sigmas for 3D Gaussian
%  nderivs - order of derivative along each dimension
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  dG      - The derivative of Gaussian filter
%
% EXAMPLE
%  dG = filter_DOOG_3D( 50, [4,4,10], [1,1,0], 1 );
%
% See also FILTER_DOOG_1D, FILTER_DOOG_2D

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function dG = filter_DOOG_3D( r, sigmas, nderivs, show )

if( nargin<4 || isempty(show) ); show=0; end;

% get initial Gaussian
N = 2*r+1;
dG = filter_gauss_nD( [N N N], [], sigmas.^2, 0 );

% take derivative of kernel appropriately
dx = .5*[-1 0 1]; dy = dx'; dt = .5* cat(3, -1, cat(3,0,1));
for i=1:nderivs(1); dG = convn( dG, dx, 'same' ); end;
for i=1:nderivs(2); dG = convn( dG, dy, 'same' ); end;
for i=1:nderivs(3); dG = convn( dG, dt, 'same' ); end;    

% normalize (don't need to adjust mean since DOOG always have 0 mean)
dG=dG/norm(dG(:),1);

% display
if( show )
  filter_visualize_3D( dG, .1, show );
  title( ['sigs=[' num2str(sigmas) '], derivs=[' num2str( nderivs ) ']']);
end;