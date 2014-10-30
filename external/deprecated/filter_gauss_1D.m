% 1D Gaussian filter.
%
% Equivalent to (but faster then):
%  f = fspecial('Gaussian',[2*r+1,1],sigma);
%  f = filter_gauss_nD( 2*r+1, r+1, sigma^2 );
%
% USAGE
%  f = filter_gauss_1D( r, sigma, [show] )
%
% INPUTS
%  r       - filter size=2r+1, if r=[] -> r=ceil(2.25*sigma)
%  sigma   - standard deviation of filter
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  f       - 1D Gaussian filter
%
% EXAMPLE
%  f1 = filter_gauss_1D( 10, 2, 1 );
%  f2 = filter_gauss_nD( 21, [], 2^2, 2);
%
% See also FILTER_BINOMIAL_1D, FILTER_GAUSS_ND, FSPECIAL

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function f = filter_gauss_1D( r, sigma, show )

if( nargin<3 || isempty(show) ); show=0; end
if( isempty(r) ); r = ceil(sigma*2.25); end
if( mod(r,1)~=0 ); error( 'r must be an integer'); end

% compute filter
x = -r:r;
f = exp(-(x.*x)/(2*sigma*sigma))';
f(f<eps*max(f(:))*10) = 0;
sumf = sum(f(:));  if(sumf~=0); f = f/sumf; end

% display
if(show); filter_visualize_1D( f, show ); end
