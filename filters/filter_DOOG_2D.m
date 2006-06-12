% 2D difference of offset Gaussian (DooG) filters.
%
% Creates a 2D derivative of Gaussian kernel.  Use primarily for visualization purposes.
% For filtering better to use the indvidiual seperable kernels for efficiency purposes.
% 
% INPUTS
%   r       - final mask will be 2r+1 x 2r+1
%   sigx    - sigma for Gaussian in x direction
%   sigy    - sigma for Gaussian in y direction
%   nderivs - order of derivative along each dimension
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   dG      - The derivative of Gaussian mask
%
% EXAMPLE
%   dG = filter_DOOG_2D( 20, 3, 3, [1,1], 1 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FILTER_DOOG_1D, FILTER_DOOG_3D, FILTER_DOG_2D, FILTER_GABOR_2D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function dG = filter_DOOG_2D( r, sigx, sigy, nderivs, show )
    if( nargin<5 || isempty(show) ) show=0; end;

    % get initial Gaussian
    dG1 = fspecial( 'Gaussian', [2*r+1,1], sigy );  
    dG2 = fspecial( 'Gaussian', [1,2*r+1], sigx );  
    dG = dG1 * dG2;   

    % apply derivativfe operator appropriate number of times
    dx = .5*[-1 0 1];
    for i=1:nderivs(1) dG = conv2( dG, dx, 'same' ); end;
    for i=1:nderivs(2) dG = conv2( dG, dx', 'same' ); end;
    
    % normalize (don't need to adjust mean since DOOG always have 0 mean)
    L1norm = norm(dG(:),1);
    dG=dG/L1norm;

    % showlay
    if (show)
        figure(show); filter_visualize_2D( dG, 0 );
        title( ['sigx = ' num2str(sigx) ',  sigy = ' num2str(sigy) ',  deriv order = [' num2str( nderivs ) ']' ] );
    end
    
