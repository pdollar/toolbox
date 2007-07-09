% Calculates histograms at every point in an array I.
%
% The qth bin of each histogram contains the count of the number of
% locations in I that have value in between edges(q)<=v< edges(q+1).
% HS(i,j,...,k,:) will contain the histogram at location (i,j,...,k), as
% calculated by weighing values in I by placing wtMask at that
% location.  For example, if wtMask is ones(windowSize) then the
% histogram at every location will simply be a histogram of the pixels
% within that window.
%
% See histc2 for more details about edges and nbins.
%
% The shape flag specifies what to do at boundaries.  See convnFast for
% possible flags such as 'same', 'valid', 'full, or 'smooth'.
%
% USAGE
%  HS = histc_image( I, edges, wtMask, [shape] )
%
% INPUTS
%  I           - Array with integer values [see above]
%  edges       - either nbins+1 vec of quantization bounds, or scalar nbins
%  wtMask      - numeric array of weights, or cell array of sep kernels
%  shape       - ['full'], 'valid', 'same', or 'smooth'
%
% OUTPUTS
%  HS          - ~size(I)xQ array where each ~size(I) elt is a Q elem hist
%                (~size(I) because depends on val of shape)
%
% EXAMPLE
%  load trees; L=conv2(X,filterDog2d(10,4,1,0),'valid'); figure(1); im(L);
%  f1=filterGauss(25,[],25);  f2=ones(1,15);
%  HS1=histc_image(L, 15, {f1,f1'}, 'same');  figure(2); montage2(HS1,1);
%  HS2=histc_image(L, 15, {f2,f2'}, 'same');  figure(3); montage2(HS2,1);
%
% See also ASSIGNTOBINS, HISTC2

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function HS = histc_image( I, edges, wtMask, shape )

if( nargin<4 || isempty(shape) ); shape = 'full';  end;
if( ~iscell(wtMask) ); wtMask={wtMask}; end;

% split I into channels
I = assignToBins( I, edges );
nbins=length(edges)-1; if(nbins==0); nbins=edges; end;
nd = ndims(I); siz=size(I);  maxI = max(I(:));
if( nd==2 && siz(2)==1); nd=1; siz=siz(1); end;
QI = false( [siz maxI] );
inds = {':'}; inds = inds(:,ones(1,nd));
for i=1:nbins;  QI(inds{:},i)=(I==i); end;
HS = double( QI );

% convolve with wtMask to get histograms, scale appropriately
for i=1:length(wtMask)
  wtMaski = wtMask{i};
  for d=1:ndims(wtMaski); wtMaski = flipdim(wtMaski,d); end;
  wtMaski = wtMaski / sum(wtMaski(:));
  HS = convnFast( HS, wtMaski, shape );
end;


