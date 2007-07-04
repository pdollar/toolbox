% Used to visualize the Fourier spectra of a series of 1D filters.  
%
% USAGE
%  FB_visualize_1D( FB, [show] )
%
% INPUTS
%  FB      - filter bank to visualize
%  show    - [1] figure to use for display
%
% OUTPUTS
%
% EXAMPLE
%  FB=FB_make_1D;  FB_visualize_1D( FB )

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FB_visualize_1D( FB, show )

if( nargin<2 || isempty(show) ); show=1; end;
if( show<=0); return; end;

FBF=zeros(size(FB));
for n=1:size(FB,1)
  FBF(n,:)=abs(fftshift(fft(FB(n,:))));
end

figure(show); 
r = (size(FB,2)-1)/2;
subplot(1,3,1); plot( -r:r, FB );
subplot(1,3,2); plot( (-r:r)/(2*r+1), FBF );
subplot(1,3,3); stem( (-r:r)/(2*r+1), max(FBF,[],1) );
