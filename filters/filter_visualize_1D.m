% Used to help visualize the a 1D filter.
%
% Marks local image maxima with a green '+' and minima with a red '+'.  Also shows the fft
% response of the filter.
%
% INPUTS
%   f   - filter to visualize
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function filter_visualize_1D( f )
    r = (length(f)-1)/2;

    f( abs(f)<.00001 ) = 0; 
    subplot(2,1,1); plot(-r:r, f);
    hold('on'); plot(0,0,'m+'); 
    h = line([-r,r],[0,0]); set(h,'color','green')
    hold('off'); xlim( [-r, r] );
    
    % plot local maxes and mins in f
    localmaxes_BW = imregionalmax(f);  localmaxes = find(localmaxes_BW);
    localmins_BW  = imregionalmin(f);  localmins  = find(localmins_BW);
    
    hold('on'); 
    plot( localmaxes-r-1, f(localmaxes), 'g+');
    plot( localmins-r-1, f(localmins), 'r+');     
    hold('off');
    
    % plot fft magnitude (fft magnitude of feven & fodd is same)
    subplot(2,1,2); stem( [-r:r] / (2*r+1), abs( fftshift( fft( f ) )) ); 
