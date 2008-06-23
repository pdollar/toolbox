function [IR,boundX,boundY] = textureMap(I, rowDst, colDst, bbox, holeVal)
% Maps texture in I according to rowDst and colDst.
%
% I has (nrows*ncols) coordinates.  Each coordinate has an associated
% intensity value.  A transformation on I can be defined by giving the
% destination (r',c') of the intensity associated with coordinate (r,c) in
% I -- ie I(r,c).  Applying the transformation, we ask what intensity is
% associated with a coordinate (r0',c0') by interpolating between the
% intensities at the closest coordinates (r',c').  In the function below
% specify the destination of (r,c) by (rowDst(r,c), colDst(r,c)).
%
% If the inverse mapping is also available -- ie if we can go from the
% coordinates in the destination to the coordinates in the source, then a
% much more efficient procedure can be used to textureMap that involves
% interp2 instead of griddata.  See imtransform2  for example usage in
% this case.
%
% The bounding box of the image is set by the BBOX argument, a string that
% can be 'loose' (default) or 'crop'. When BBOX is 'loose', IR includes the
% whole transformed image, which generally is larger than I. When BBOX is
% 'crop' IR is cropped to include only the central portion of the
% transformed image and is the same size as I.
%
% USAGE
%  IR = textureMap( I, rowDst, colDst, [bbox], [holeVal] )
%
% INPUTS
%  I           - 2D input image
%  rowDst      - rowDst(i,j) is row loc where I(i,j) gets mapped to
%  colDst      - colDst(i,j) is col loc where I(i,j) gets mapped to
%  bbox        - ['loose'] see above for meaning of bbox 'loose' or 'crop'
%  holeVal     - [0] Value of the empty warps
%
% OUTPUTS
%  IR          - result of texture mapping
%  boundaryX   - returns the smallest/biggest x coordinate of the output
%  boundaryY   - returns the smallest/biggest y coordinate of the output
%
% EXAMPLE
%
% See also IMTRANSFORM2
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if(isa( I, 'uint8' )); I = double(I); end
if( nargin<4 || isempty(bbox)); bbox='loose'; end
if( nargin<5 || isempty(holeVal) ); holeVal=0; end
  
siz = size(I);
if( all(size(rowDst)~=siz) || all(size(colDst)~=siz))
  error( 'incorrect size for rowDst or colDst' );
end

% find sampling points
if( strcmp('loose',bbox) )
  minr = floor(min(rowDst(:)));   minc = floor(min(colDst(:)));
  maxr = ceil(max(rowDst(:)));    maxc = ceil(max(colDst(:)));
  [colGrid,rowGrid] = meshgrid( minc:maxc, minr:maxr );
  boundX=[minc maxc]; boundY=[minr maxr];
  
elseif( strcmp('crop',bbox) )
  [colGrid,rowGrid] = meshgrid( 1:size(I,2), 1:size(I,1) );
  boundX=[1 size(I,2)]; boundY=[1 size(I,1)];
else
  error('illegal value for bbox');
end

% Get values at colGrid and rowGrid
IR = griddata( colDst, rowDst, I, colGrid, rowGrid );
IR(isnan(IR)) = holeVal;
