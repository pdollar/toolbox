function IC = arrayToDims( I, dims, padEl )
% Pads or crops I appropriately so that size(IC)==dims.
%
% For each dimension d, if size(I,d) is larger then dims(d) then
% symmetrically crops along d (if cropping amount is odd crops one more
% unit from the start of the dimension).  If size(I,d) is smaller then
% dims(d) then symmetrically pads along d with padEl (if padding amount is
% even then pads one more unit along the start of the dimension).
%
% USAGE
%  IC = arrayToDims( I, dims, [padEl] )
%
% INPUTS
%  I         - n dim array to crop window from (for arrays can only crop)
%  dims      - dimensions to make I
%  padEl     - [0] element with which to pad
%
% OUTPUTS
%  IC        - cropped array
%
% EXAMPLE
%  I=randn(10); delta=1; IC=arrayToDims(I,size(I)-2*delta);
%
% See also ARRAYCROP, PADARRAY
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(padEl)); padEl=0; end
nd = ndims(I);  siz = size(I);
[dims,er] = checkNumArgs( dims, size(siz), 0, 1 ); error(er);
if(any(dims==0)); IC=[]; return; end

% get start and end locations for cropping
strLocs = ones( 1, nd );  endLocs = siz;
for d=1:nd
  delta = siz(d) - dims(d);
  if ( delta~=0 )
    deltaHalf = floor( delta / 2 );
    deltaRem = delta - 2*deltaHalf;
    strLocs(d) = 1 + (deltaHalf + deltaRem);
    endLocs(d) = siz(d) - deltaHalf;
  end
end

% call arrayCrop
IC = arrayCrop( I, strLocs, endLocs, padEl );
