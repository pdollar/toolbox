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
%  pvPairs     - [{'FontSize',20}] parameter / value list for text.m
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
% See also confMatrix, imLabel, dispMatrixIm
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.50
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 ); types=[]; end
if( nargin<3 || isempty(pvPairs)); pvPairs = {'FontSize',20}; end
if( nargin<4 || isempty(nDigits)); nDigits=2; end
if( nargin<5 || isempty(showCnts)); showCnts=0; end
if( nDigits<1 || nDigits>10 ); error('too few or too many digits'); end
if( any(CM(:)<0) ); error( 'CM must have non-negative entries' ); end

% normalize and round appropriately
cnts = sum(CM,2);
CM = CM ./ repmat( cnts+eps, [1 size(CM,2)] );
CM = round(CM*10^nDigits) / 10^nDigits;

% display as image using dispMatrixIm
dispMatrixIm(CM,'maxM',1,'maxLen',nDigits+1,'show0',0,...
  'fStr','%f','invert',1,'pvPairs',pvPairs); axis square;

% now add type labels
if( ~isempty(types) )
  imLabel( types, 'left', 0, pvPairs );
  imLabel( types, 'bottom', -35, pvPairs );
  if(showCnts), imLabel(int2str2(cnts),'right',0,pvPairs); end
end
