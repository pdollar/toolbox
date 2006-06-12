% 3D difference of offset Gaussian (DooG) filters.
%
% Creates a 3D derivative of Gaussian kernel.  Use primarily for visualization purposes.
% For filtering better to use the indvidiual seperable kernels for efficiency purposes.
% 
% INPUTS
%   r       - final mask will be NxNxN where N=2r+1
%   sigmas  - sigmas for 3D Gaussian
%   nderivs - order of derivative along each dimension
%   show    - [optional] whether or not to visually display the kernel
%
% OUTPUTS
%   dG      - The derivative of Gaussian mask
%
% EXAMPLE
%   dG = filter_DOOG_3D( 50, [4,4,10], [1,1,0], 1 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FILTER_DOOG_1D, FILTER_DOOG_2D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function dG = filter_DOOG_3D( r, sigmas, nderivs, show )
    if( nargin<4 || isempty(show) ) show=0; end;
    N = 2*r+1;

    % create 1D Gaussian and derivative masks
    gauss_x = fspecial( 'Gaussian', [1,N], sigmas(1) );
    gauss_y = fspecial( 'Gaussian', [N,1], sigmas(2) );
    gauss_t = fspecial( 'Gaussian', [N,1], sigmas(3) );
    gauss_t = permute( gauss_t', circshift(1:3,[1,2-1]) );    
    dx = .5*[-1 0 1]; dy = dx'; dt = .5* cat(3, -1, cat(3,0,1));

    % create Gaussian kernel
    dG =convn( gauss_t, gauss_y*gauss_x );
    
    % take derivative of kernel appropriately
    for i=1:nderivs(1) dG = convn( dG, dx, 'same' ); end;
    for i=1:nderivs(2) dG = convn( dG, dy, 'same' ); end;
    for i=1:nderivs(3) dG = convn( dG, dt, 'same' ); end;    
    
    % normalize    
    L1norm = norm(dG(:),1);
    dG=dG/L1norm;
    
    % display
    if (show)
        figure(show); clf; montage2(dG,1);
        figure(show+1); clf; filter_visualize_3D( dG, .1 );
    end
    
