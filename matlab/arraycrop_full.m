% Used to crop a rectangular region from an n dimensional array.  
% 
% Guarantees that the resulting array will have dims as specified by rect
% by filling in locations with padEl if the locations are outside of array.
%
% USAGE
%  I = arraycrop_full( I, strLocs, endLocs, [padEl] )
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
%  I=randn(10);  IC=arraycrop_full( I, [-1 1], [10 10], 0 );
%
% See also PADARRAY, ARRAYCROP2DIMS

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = arraycrop_full( I, strLocs, endLocs, padEl )

if( nargin<4 || isempty(padEl)); padEl=0; end;
nd = ndims(I);  siz = size(I);
[strLocs,er] = checknumericargs( strLocs, size(siz), 0, 0 ); error(er);
[endLocs,er] = checknumericargs( endLocs, size(siz), 0, 0 ); error(er);
if( any(strLocs>endLocs)); error('strLocs must be <= endLocs'); end;
padEl = feval( class(I), padEl );

% crop a real rect [accelerate implementation if nd==2 or nd==3]
strL1 = max(strLocs,1);  endL1 = min(endLocs, siz);
if( nd==2 )
  I = I( strL1(1):endL1(1), strL1(2):endL1(2) );
elseif( nd==3 )
  I = I(strL1(1):endL1(1), strL1(2):endL1(2), strL1(3):endL1(3) );
else
  extract = cell( nd, 1 );
  for d=1:nd; extract{d} = strL1(d):endL1(d); end
  I = I( extract{:} );
end

% then pad as appropriate (essentially inlined padarray)
padPre = 1 - min( strLocs, 1 );
padPost = max( endLocs, siz ) - siz;
if (any(padPre~=0) || any(padPost~=0))
  idx = cell(1,nd); sizPadded = zeros(1,nd); siz = size(I);
  for d=1:nd
    idx{d} = (1:siz(d)) + padPre(d);
    sizPadded(d) = siz(d) + padPre(d) + padPost(d);
  end
  Ib = repmat( padEl, sizPadded );
  Ib(idx{:}) = I;  I = Ib;
end
    
    
% %%% Alternate method not based on padarray (slower)
% for d=1:nd
%   if (strLocs(d) <= 0 )
%     dims = size(I);  dims(d) = 1-strLocs(d);
%     A = repmat( padEl, dims ); %;  A = A( ones(dims) );
%     I = cat(d,A,I); 
%   end
%   if (endLocs(d) - siz(d) > 0)
%     dims = size(I);  dims(d) = endLocs(d) - siz(d);
%     A = repmat( padEl, dims );
%     I = cat(d,I,A);
%   end
% end