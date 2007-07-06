% Calculates histograms at every point in an array I.
%
% The qth bin of each histogram contains the count of the number of
% locations in I that have value in between edges(q)<=v< edges(q+1).
% HS(i,j,...,k,:) will contain the histogram at location (i,j,...,k), as
% calculated by weighing values in I by placing weightMask at that
% location.  For example, if weightMask is ones(windowSize) then the
% histogram at every location will simply be a histogram of the pixels
% within that window.
%
% See histc_1D for more details about edges and nbins.
%
% The shape flag specifies what to do at boundaries.  See convn_fast for
% possible flags such as 'same', 'valid', 'full, or 'smooth'.
%
% USAGE
%  HS = histc_image( I, edges, weightMask, [shape] )
%
% INPUTS
%  I           - Array with integer values [see above]
%  edges       - either nbins+1 vec of quantization bounds, or scalar nbins
%  weightMask  - numeric array of weights, or cell array of sep kernels
%  shape       - ['full'] 'valid', 'full', 'same', or 'smooth'
%
% OUTPUTS
%  HS          - ~size(I)xQ array where each ~size(I) elt is a Q elem hist
%                (~size(I) because depends on val of shape)
%
% EXAMPLE
%  load trees;
%  L = conv2(X, filterDog2d(10,4,1,0), 'valid' );
%  f1=filterGauss(25,[],25);  HS1 = histc_image( L, 15, {f1,f1'}, 'same' );
%  f2=ones(1,15);             HS2 = histc_image( L, 15, {f2,f2'}, 'same' );
%  figure(1); im(X); figure(2); im(L);   figure(3); montage2(HS1,1,1);
%  figure(4); montage2(HS2,1,1);         figure(5); montage2(HS1-HS2,1,1);
%
% See also ASSIGN2BINS, HISTC_1D

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function HS = histc_image( I, edges, weightMask, shape )

if( nargin<4 || isempty(shape) ); shape = 'full';  end;
if( ~iscell(weightMask) ); weightMask={weightMask}; end;

% split I into channels
I = assign2bins( I, edges );
nbins=length(edges)-1; if(nbins==0); nbins=edges; end;
nd = ndims(I); siz=size(I);  maxI = max(I(:));
if( nd==2 && siz(2)==1); nd=1; siz=siz(1); end;
QI = false( [siz maxI] );
inds = {':'}; inds = inds(:,ones(1,nd));
for i=1:nbins;  QI(inds{:},i)=(I==i); end;
HS = double( QI );

% convolve with weightMask to get histograms, scale appropriately
for i=1:length(weightMask)
  weightMaski = weightMask{i};
  for d=1:ndims(weightMaski); weightMaski = flipdim(weightMaski,d); end;
  weightMaski = weightMaski / sum(weightMaski(:));
  HS = convn_fast( HS, weightMaski, shape );
end;
    

