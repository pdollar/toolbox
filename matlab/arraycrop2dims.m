% Pads or crops I appropriately so that size(IC)==dims.  
%
% For each dimension d, if size(I,d) is larger then dims(d) then
% symmetrically crops along d (if cropping amount is odd crops one more
% unit from the start of the dimension).  If size(I,d) is smaller then
% dims(d) then symmetrically pads along d with padEl (if padding amount is
% even then pads one more unit along the start of the dimension).
%
% USAGE
%  IC = arraycrop2dims( I, dims, [padEl] )
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
%  I=randn(10); delta=1; IC=arraycrop2dims(I,size(I)-2*delta);
%
% See also ARRAYCROP_FULL, PADARRAY

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function IC = arraycrop2dims( I, dims, padEl )

if( nargin<3 || isempty(padEl)); padEl=0; end;      
nd = ndims(I);  siz = size(I);
[dims,er] = checknumericargs( dims, size(siz), 0, 1 ); error(er);
if(any(dims==0)); IC=[]; return; end;

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

% call arraycrop_full 
IC = arraycrop_full( I, strLocs, endLocs, padEl );