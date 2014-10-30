function I = arrayCrop( I, strLocs, endLocs, padEl )
% Used to crop a rectangular region from an n dimensional array.
%
% Guarantees that the resulting array will have dims as specified by rect
% by filling in locations with padEl if the locations are outside of array.
%
% USAGE
%  I = arrayCrop( I, strLocs, endLocs, [padEl] )
%
% INPUTS
%  I          - n dimensional array to crop window from
%  strLocs    - locs at which to start cropping along each dim
%  endLocs    - locs at which to end cropping along each dim
%  padEl      - [0] element with which to pad
%
% OUTPUTS
%  I          - cropped array
%
% EXAMPLE
%  I=randn(10);  IC=arrayCrop( I, [-1 1], [10 10], 0 );
%
% See also PADARRAY, ARRAYTODIMS
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.02
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(padEl)); padEl=0; end
nd = ndims(I);  siz = size(I);
[strLocs,er] = checkNumArgs(strLocs,size(siz),0,0); error(er);
[endLocs,er] = checkNumArgs(endLocs,size(siz),0,0); error(er);
if( any(strLocs>endLocs)); error('strLocs must be <= endLocs'); end

% crop a real rect [accelerate implementation if nd==2 or nd==3]
strL1 = max(strLocs,1);  endL1 = min(endLocs, siz);
if( nd==2 )
  I = I( strL1(1):endL1(1), strL1(2):endL1(2) );
elseif( nd==3 )
  I = I( strL1(1):endL1(1), strL1(2):endL1(2), strL1(3):endL1(3) );
else
  extract = cell( nd, 1 );
  for d=1:nd; extract{d} = strL1(d):endL1(d); end
  I = I( extract{:} );
end

% then pad as appropriate (essentially inlined padarray)
if( any(strLocs<1) || any(endLocs>siz) )
  padEl = feval( class(I), padEl );
  padPre = 1 - min( strLocs, 1 );
  sizPadded = endLocs-strLocs+1;
  idx=cell(1,nd);
  for d=1:nd; idx{d}=(1:size(I,d))+padPre(d); end
  Ib = repmat( padEl, sizPadded );
  Ib(idx{:})=I; I=Ib;
end
