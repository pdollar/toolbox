% Used to help visualize a 2D filter.  
%
% Marks local image maxima with a green '+' and minima with a red '+'. Also shows the fft
% response of the filter.  Can optionally also plot a scanline through either center row+2
% or center column+2.  
%
% INPUTS
%   F           - filter to visualize
%   plotline    - if 1, then draw line through center row+2, if 2 then 
%                 througt center col+2.  else no line. optional.
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function filter_visualize_2D( F, plotline )
    
    subplot(2,1,1);
    F( abs(F)<.00001 ) = 0; im(F);
    title(inputname(1));
    
    % plot maxes and mins in F
    localmaxes_BW = imregionalmax(F);    
    localmaxes_BW(1,1)=0; localmaxes_BW(end,end)=0;
    localmaxes_BW(1,end)=0; localmaxes_BW(end,1)=0;
    [localmaxes(:,1),localmaxes(:,2)] = find(localmaxes_BW);
    
    localmins_BW  = imregionalmin(F);  
    localmins_BW(1,1)=0; localmins_BW(end,end)=0;
    localmins_BW(1,end)=0; localmins_BW(end,1)=0;
    [localmins(:,1),localmins(:,2)] = find(localmins_BW);
    
    hold('on');  plot( localmaxes(:,2), localmaxes(:,1), 'g+');
    plot( localmins(:,2), localmins(:,1), 'r+'); hold('off'); 

    % show fft response
    subplot(2,1,2);
    FF = abs(fftshift(fft2(F)));
    im(FF); title('Fourier spectra');
    
    % plot scanline
    if (nargin==2)
        if (plotline==1)
            sc = F( (size(F,1)-1)/2 +2, : );  
        elseif (plotline==2)
            sc = F( :, (size(F,2)-1)/2 +2 );  
        else 
            return;
        end
        
        localmaxes_BW = imregionalmax(sc);  localmaxes = find(localmaxes_BW);
        localmins_BW  = imregionalmin(sc);  localmins  = find(localmins_BW) ;
        figure(2);  plot( sc ); hold('on'); 
        plot( localmaxes, sc(localmaxes), 'g+');
        plot( localmins, sc(localmins), 'r+');     
        hold('off');
    end
            
