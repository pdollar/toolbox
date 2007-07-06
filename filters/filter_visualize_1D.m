% Used to visualize a 1D filter.
%
% Marks local filter maxima with a green '+' and minima with a red '+'.
% Also shows the fft response of the filter.
%
% USAGE
%  filter_visualize_1D( f, [show] )
%
% INPUTS
%  f       - filter to visualize
%  show    - [1] figure to use for display (0->uses current)
%
% OUTPUTS
%
% EXAMPLE
%  f = filter_binomial_1D( 10, 0 );
%  filter_visualize_1D( f, 1 )
%
% See also FILTER_VISUALIZE_2D

% Piotr's Image&Video Toolbox      Version 1.03   PPD VR
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function filter_visualize_1D( f, show )

if( nargin<2 || isempty(show) ); show=1; end;
if( show>0); figure( show ); clf; end;

r = (length(f)-1)/2;
f( abs(f)<.00001 ) = 0;

% show original filter
subplot(2,1,1); plot(-r:r, f);
hold('on'); plot(0,0,'m+');
h = line([-r,r],[0,0]); set(h,'color','green')
xlim( [-r, r] );
title(inputname(1));

% plot local mins/maxs in f
locMaxs = find(imregionalmax(f));
locMins = find(imregionalmin(f));
plot( locMaxs-r-1, f(locMaxs), 'g+');
plot( locMins-r-1, f(locMins), 'r+');
hold('off');

% plot fft magnitude of f
subplot(2,1,2);
stem( (-r:r) / (2*r+1), abs( fftshift( fft( f ) )) );
title('Fourier spectra');
