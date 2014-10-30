function H = histcImWin( I, edges, wtMask, shape )
% Calculates local histograms at every point in an image I.
%
% H(i,j,...,k,:) will contain the histogram at location (i,j,...,k), as
% calculated by weighing values in I by placing wtMask at that
% location.  For example, if wtMask is ones(windowSize) then the
% histogram at every location will simply be a histogram of the pixels
% within that window.  See histc2 for more information about histgorams.
% See convnFast for information on shape flags.
%
% USAGE
%  H = histcImWin( I, edges, wtMask, [shape] )
%
% INPUTS
%  I           - image (possibly multidimensional) [see above]
%  edges       - quantization bounds, see histc2
%  wtMask      - numeric array of weights, or cell array of sep kernels
%  shape       - ['full'], 'valid', 'same', or 'smooth'
%
% OUTPUTS
%  H           - [size(I)xnBins] array of size(I) histograms
%
% EXAMPLE
%  load trees; L=conv2(X,filterDog2d(10,4,1,0),'valid'); figure(1); im(L);
%  f1=filterGauss(25,[],25);  f2=ones(1,15);
%  H1 = histcImWin(L, 15, {f1,f1'}, 'same');  figure(2); montage2(H1);
%  H2 = histcImWin(L, 15, {f2,f2'}, 'same');  figure(3); montage2(H2);
%
% See also ASSIGNTOBINS, HISTC2, CONVNFAST, HISTCIMLOC
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(shape) ); shape = 'full';  end;
if( ~iscell(wtMask) ); wtMask={wtMask}; end;

% split I into channels
I = assignToBins( I, edges );
nBins=length(edges)-1; if(nBins==0); nBins=edges; end;
nd = ndims(I); siz=size(I);  maxI = max(I(:));
if( nd==2 && siz(2)==1); nd=1; siz=siz(1); end;
QI = false( [siz maxI] );
inds = {':'}; inds = inds(:,ones(1,nd));
for i=1:nBins;  QI(inds{:},i)=(I==i); end;
H = double( QI );

% convolve with wtMask to get histograms, scale appropriately
for i=1:length(wtMask)
  wtMaski = wtMask{i};
  for d=1:ndims(wtMaski); wtMaski = flipdim(wtMaski,d); end;
  wtMaski = wtMaski / sum(wtMaski(:));
  H = convnFast( H, wtMaski, shape );
end;
