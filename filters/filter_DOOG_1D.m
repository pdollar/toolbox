% 1D difference of offset Gaussian (DooG) filters.
%
% Creates a 2D derivative of Gaussian kernel.  Use primarily for visualization purposes.
% For filtering better to use the indvidiual seperable kernels for efficiency purposes.
% 
% INPUTS
%   r       - final mask will have length 2r+1
%   sig     - sigma for Gaussian 
%   deriv   - order of derivative 
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   dG      - The derivative of Gaussian mask
%
% EXAMPLE
%   dG = filter_DOOG_1D( 11, 2, 3, 1 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also FILTER_DOOG_2D, FILTER_DOOG_3D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function dG = filter_DOOG_1D( r, sig, deriv, show )
    if( nargin<4 || isempty(show) ) show=0; end;

    % get initial Gaussian
    dG = fspecial( 'Gaussian', [1,2*r+1], sig );  
    
    % apply derivativfe operator appropriate number of times
    dx = .5*[-1 0 1];
    for i=1:deriv dG = conv2( dG, dx, 'same' ); end;

    % normalize (don't need to adjust mean since DOOG always have 0 mean)
    L1norm = norm(dG(:),1);
    dG=dG/L1norm;

    % display
    if ( show )
        figure(show); filter_visualize_1D( dG );
    end
    
