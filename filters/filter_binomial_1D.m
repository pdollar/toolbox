% 1D binomial filter (approximation to Gaussian filter)
%
% Creates a binomial filter of size 2*r+1 x 1.  This can be used to approximate the
% Gaussian distribution with sigma=sqrt((2*r+1)/4). For large r, should give same output
% as:
%   g = fspecial( 'Gaussian', [2*r+1,1],sqrt((2*r+1)/4) );
% Given sigma, use r ~= 2*sigma^2.
%
% Use F = f*f' to get the equivalent 2d filter. 
%
% INPUTS
%   r       - mask will have length 2r+1 and var=(2*r+1)/4
%   show    - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   f       - 1D binomial filter
%
% EXAMPLE
%   r = 10;
%   fbinom = filter_binomial_1D( r, 1 );
%   fgauss = filter_gauss_1D( r, sqrt((2*r+1)/4), 2 );
%
% DATESTAMP
%   11-Oct-2005  7:00pm
%   
% See also FILTER_GAUSS_1D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function f = filter_binomial_1D( r, show )
    if( nargin<2 ) show=0; end;
    if( mod(r,1)~=0 ) error( 'r must be an integer'); end;
    
    f = diag(fliplr(pascal(2*r+1))) / 4^r;

    % display
    if ( show )
        figure(show); filter_visualize_1D( f );
    end
