% Used to visualize the Fourier spectra of a series of 1D filters.  
%
% INPUTS
%   FB  - filter bank to visualize
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FB_visualize_1D( FB )
    r = (size(FB,2)-1)/2;
    
    FBF=zeros(size(FB));
    for n=1:size(FB,1)
        FBF(n,:)=abs(fftshift(fft(FB(n,:))));
    end
    
    figure; 
    subplot(1,3,1); plot_vectors( -r:r, FB );
    subplot(1,3,2); plot_vectors( [-r:r]/(2*r+1), FBF );
    subplot(1,3,3); stem( [-r:r]/(2*r+1), max(FBF,[],1) );

    
function plot_vectors( x, ys )
    colors = ['r', 'g', 'b', 'c', 'm', 'y', 'k']; nc = length(colors);

    gcf; 
    hold('on'); 
    for n=1:size(ys,1) plot( x, ys(n,:), 'color', colors(mod((n-1),nc)+1) );  end;
    hold('off');
    
