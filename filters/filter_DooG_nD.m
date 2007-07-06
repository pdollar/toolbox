% n-dim difference of offset Gaussian DooG filter (Gaussian derivative).
%
% Creates a nd derivative of Gaussian kernel.  For all but d==1 use
% primarily for visualization purposes -- for filtering better to use the
% indvidiual seperable kernels for efficiency purposes.
%
% USAGE
%  dG = filter_DooG_nD( dims, sigmas, nderivs, [show] )
%
% INPUTS
%  dims    - nd element vector of dimensions of final Gaussian
%  sigmas  - sigmas for nd Gaussian
%  nderivs - order of derivative along each of the nd dimensions
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  dG      - The derivative of Gaussian filter
%
% EXAMPLE
%  dG1 = filter_DooG_nD( 43, 2, 3, 1 ); %1D
%  dG2 = filter_DooG_nD( [41 41], [3 3], [1,1], 2 ); %2D
%  dG3 = filter_DooG_nD( [101 101 101], [4,4,10], [1,1,0], 3 ); %3D
%
% See also FILTER_GAUSS_ND, NORMPDF2, FILTER_DOG_2D, FILTER_GABOR_2D

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!
 
function dG = filter_DooG_nD( dims, sigmas, nderivs, show )

nd = length( dims );
if( nargin<4 || isempty(show) ); show=0; end;
if( length(sigmas)~=nd ); error('invalid sigmas'); end
if( length(nderivs)~=nd ); error('invalid nderivs'); end

% get initial Gaussian
dG = filter_gauss_nD( dims, [], sigmas.^2, 0 );

% compute derivatives along each axis
for d=1:nd
  if( d==1 );
    dOp=.5*[-1 0 1]';
  else
    dOp = .5*permute( [-1 0 1]', d:-1:1 );
  end
  if( nd==1 || nd==2 )
    for i=1:nderivs(d); dG = conv2( dG, dOp, 'same' ); end
  else
    for i=1:nderivs(d); dG = convn( dG, dOp, 'same' ); end
  end
end

% normalize (don't need to adjust mean since DOOG always have 0 mean)
dG=dG/norm(dG(:),1);

% display
if( show && nd<=3 )
  if( nd==1 )
    filter_visualize_1D( dG, show );
  elseif( nd==2 )
    filter_visualize_2D( dG, '', show )
  elseif( nd==3 )
    filter_visualize_3D( dG, .1, show );
  end
  title( ['sigs=[' num2str(sigmas) '], derivs=[' num2str( nderivs ) ']']);
end

