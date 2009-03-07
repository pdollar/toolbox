function confMatrixShow( CM, types, pvPairs, nDigits, showCnts )
% Used to display a confusion matrix.
%
% See confMatrix for general format and info on confusion matricies. This
% function normalizes the CM before displaying, hence all values range in
% [0,1] and rows sum to 1.
%
% USAGE
%  confMatrixShow( CM, [types], [pvPairs], [nDigits], [showCnts] )
%
% INPUTS
%  CM          - [nTypes x nTypes] confusion array -- see confMatrix
%  types       - [] cell array of length nTypes of text labels
%  pvPairs     - [] parameter / value list for text.m
%  nDigits     - [2] number of digits after decimal to display
%  showCnts    - [0] show total count per row to the right
%
% OUTPUTS
%
% EXAMPLE
%  CM = randint2(6,6,[1,100])+eye(6)*500;
%  types = { 'anger','disgust','fear','joy','sadness','surprise' };
%  confMatrixShow( CM, types, {'FontSize',20}, [], 0 )
%  title('confusion matrix','FontSize',24);
%
% See also CONFMATRIX, IMLABEL
%
% Piotr's Image&Video Toolbox      Version 2.20
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<2 ); types=[]; end
if( nargin<3 || isempty(pvPairs)); pvPairs = {'FontSize',20}; end
if( nargin<4 || isempty(nDigits)); nDigits=2; end
if( nargin<5 || isempty(showCnts)); showCnts=0; end
if( nDigits<1 || nDigits>10 ); error('too few or too many digits'); end
if( any(CM)<0 ); error( 'CM must have non-negative entries' ); end

%%% normalize and convert to integer matrix
cnts = sum(CM,2);
CM = CM ./ repmat( cnts+eps, [1 size(CM,2)] );
CM = round(CM*10^nDigits);

%%% display as image
clf; imagesc(10^nDigits-CM,[0,10^nDigits]);
colormap gray; axis square;
set(gca,'XTick',[]); set(gca,'YTick',[]);

%%% now write text of actual confusion value
nTypes = size(CM,1);
txtAlign = {'VerticalAlignment','middle', 'HorizontalAlignment','center'};
for i=1:nTypes
  for j=1:nTypes
    if( CM(i,j)>10^nDigits/2 ); color = 'w'; else color = 'k'; end
    if( CM(i,j)==10^nDigits )
      label = ['1.' repmat('0',[1 nDigits-1]) ];
    elseif( CM(i,j)==0 )
      label = '';
    else
      label = ['.' int2str2( CM(i,j),nDigits) ];
    end
    text(j,i,label,'color',color,txtAlign{:},pvPairs{:});
  end;
end

%%% now add type labels
if( ~isempty(types) )
  imLabel( types, 'left', 0, pvPairs );
  imLabel( types, 'bottom', -35, pvPairs );
  if(showCnts), imLabel(int2str2(cnts),'right',0,pvPairs); end
end
