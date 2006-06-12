% Used to visualize the Fourier spectra of a series of 2D filters.
%
% Used to visualize the Fourier spectra of a series of filters.  Generally best if called
% only on the part of the FB that contains the oriented filters.
%
% INPUTS
%   FB  - filter bank to visualize
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FB_visualize_2D( FB )
    FBF=zeros(size(FB));
    for n=1:size(FB,3)
        FBF(:,:,n)=abs(fftshift(fft2(FB(:,:,n))));
    end
    
    figure; 
    subplot(1,3,1); montage2(FB);
    subplot(1,3,2); montage2(FBF);
    subplot(1,3,3); im(sum(FBF,3));
