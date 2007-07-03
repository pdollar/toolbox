% Used to visualize the Fourier spectra of a series of 2D filters.
%
% Should be used for a FB that contains the oriented filters.
%
% USAGE
%  FB_visualize_2D( FB, [show] )
%
% INPUTS
%  FB      - filter bank to visualize
%  show    - [1] figure to use for display
%
% OUTPUTS
%
% EXAMPLE
%  load FB_DoG.mat;  FB_visualize_2D( FB )

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FB_visualize_2D( FB, show )

if( nargin<2 || isempty(show) || show<1 ); show=1; end;

FBF=zeros(size(FB));
for n=1:size(FB,3)
  FBF(:,:,n)=abs(fftshift(fft2(FB(:,:,n))));
end

figure(show); 
subplot(1,3,1); montage2(FB,1);  title('filter bank');
subplot(1,3,2); montage2(FBF,1); title('filter bank fft');
subplot(1,3,3); im(sum(FBF,3));  title('filter bank fft coverage');
