function FbVisualize( FB, show )
% Used to visualize a series of 1D/2D/3D filters. 
%
% For 1D and 2D filterabnks also shows the Fourier spectra of the filters.
%
% USAGE
%  FbVisualize( FB, [show] )
%
% INPUTS
%  FB      - filter bank to visualize (either 2D, 3D, or 4D array)
%  show    - [1] figure to use for display
%
% OUTPUTS
%
% EXAMPLE
%  FB=FbMake(1,1,0);  FbVisualize( FB, 1 );  %1D
%  load FbDoG.mat;    FbVisualize( FB, 2 );  %2D
%  FB=FbMake(3,1,0);  FbVisualize( FB, 3 );  %3D
%
% See also FBAPPLY2D, FILTERVISUALIZE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 || isempty(show) ); show=1; end
if( show<=0); return; end;

% get Fourier Spectra for 1D and 2D filterbanks
nd = ndims(FB)-1;
if( nd==1 || nd==2 )
  FBF=zeros(size(FB));
  if( nd==1 )
    for n=1:size(FB,1);  FBF(n,:)=abs(fftshift(fft(FB(n,:)))); end
  else
    for n=1:size(FB,3);  FBF(:,:,n)=abs(fftshift(fft2(FB(:,:,n)))); end
  end
end

% display
figure(show); clf; 
if( nd==1 )
  r = (size(FB,2)-1)/2;
  subplot(1,3,1); plot( -r:r, FB );
  subplot(1,3,2); plot( (-r:r)/(2*r+1), FBF );
  subplot(1,3,3); stem( (-r:r)/(2*r+1), max(FBF,[],1) );
  
elseif( nd==2 )
  subplot(1,3,1); montage2(FB);  title('filter bank');
  subplot(1,3,2); montage2(FBF);
  title('filter bank fft');
  subplot(1,3,3); im(sum(FBF,3));  title('filter bank fft coverage');
  
elseif( nd==3 )
  n = size(FB,4); nn = ceil( sqrt(n) ); mm = ceil( n/nn );
  for i=1:n 
    subplot(nn,mm,i); 
    filterVisualize( FB(:,:,:,i), 0 );
  end
end
