% Used to visualize a 2D filter.
%
% Marks local image maxima with a green '+' and minima with a red '+'. Also
% shows the fft response of the filter.  Can optionally also plot a
% scanline through either center row/column.
%
% USAGE
%  filter_visualize_2D( F, scanline, [show] )
%
% INPUTS
%  F         - filter to visualize
%  scanline  - [0] 'row' OR 'col': display centeral row OR col line
%  show      - [1] figure to use for display (0->uses current)
%
% OUTPUTS
%
% EXAMPLE
%  F = filter_DOG_2D( 15, 10, 1 );
%  filter_visualize_2D( F, 'row', 1 );
%
% See also FILTER_VISUALIZE_1D, FILTER_VISUALIZE_3D

% Piotr's Image&Video Toolbox      Version 1.03   PPD VR
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function filter_visualize_2D( F, scanline, show )

if( nargin<2 || isempty(scanline) ); scanline=''; end
if( nargin<3 || isempty(show) ); show=1; end
if( show>0); figure( show ); clf; end

F( abs(F)<.00001 ) = 0;

% image of filter
subplot(2,1,1); im(F);
title(inputname(1));
hold('on');

% plot maxes and mins in F
locMaxs = imregionalmax(F); locMaxs([1 end],[1 end])=0;
[locMaxs1,locMaxs2] = find(locMaxs);
plot( locMaxs2, locMaxs1, 'g+');
locMins = imregionalmin(F); locMins([1 end],[1 end])=0;
[locMins1,locMins2] = find(locMins);
plot( locMins2, locMins1, 'r+');

% show fft response
subplot(2,1,2);
FF = abs(fftshift(fft2(F)));
im(FF); title('Fourier spectra');

% optionally plot central row/col scanline
if(strcmp(scanline,'row') || strcmp(scanline,'col'))
  if( strcmp(scanline,'row') )
    sc = F( round((size(F,1)-1)/2+1), : );
  else
    sc = F( :, round((size(F,2)-1)/2+1) );
  end
  figure(show+1);  plot( sc ); hold('on');  title(scanline);
  locMaxs = find(imregionalmax(sc));
  locMins = find(imregionalmin(sc));
  plot( locMaxs, sc(locMaxs), 'g+');
  plot( locMins, sc(locMins), 'r+');
  hold('off');
end
