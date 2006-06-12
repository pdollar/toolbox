% Maps texture in I according to row_dest and col_dest.
%
% I has (nrows*ncols) coordinates.  Each coordinate has an associated intensity value.  A
% transformation on I can be defined by giving the destination (r',c') of the intensity
% associated with coordinate (r,c) in I -- ie I(r,c).  Applying the transformation, we ask
% what intensity is associated with a coordinate (r0',c0') by interpolating between the 
% intensities at the closest coordinates (r',c').  In the function below specify the
% destination of (r,c) by (row_dest(r,c), col_dest(r,c)).
%
% If the inverse mapping is also available -- ie if we can go from the coordinates in the
% destination to the coordinates in the source, then a much more efficient procedure can
% be used to texture_map that involves interp2 instead of griddata.  See apply_homography
% for example usage in this case.
%
% The bounding box of the image is set by the BBOX argument, a string that can be 'loose'
% (default) or 'crop'. When BBOX is 'loose', IR includes the whole transformed image,
% which generally is larger than I. When BBOX is 'crop' IR is cropped to include only the
% central portion of the transformed image and is the same size as I. 
%
% INPUTS
%   I           - 2D input image
%   row_dest    - row_dest(i,j) is row loc where I(i,j) gets mapped to
%   col_dest    - col_dest(i,j) is col loc where I(i,j) gets mapped to
%   bbox        - [optional] see above for meaning of bbox ({'loose'},'crop')
%
% OUTPUTS
%   IR          - result of texture mapping
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also APPLY_HOMOGRAPHY

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function IR = texture_map( I, row_dest, col_dest, bbox )
    if( isa( I, 'uint8' ) ) I = double(I); end;
    if( nargin<4 || isempty(bbox)) bbox='loose'; end;
    
    siz = size(I);
    if ( all(size(row_dest)~=siz) || all(size(col_dest)~=siz))
        error( 'incorrect size for row_dest or col_dest' );
    end;

    
    % find sampling points
    if (strcmp('loose',bbox))
        minr = floor(min(row_dest(:)));   minc = floor(min(col_dest(:)));
        maxr = ceil(max(row_dest(:)));    maxc = ceil(max(col_dest(:)));   
        [col_grid,row_grid] = meshgrid( minc:maxc, minr:maxr );
    elseif (strcmp('crop',bbox))
        [col_grid,row_grid] = meshgrid( 1:size(I,2), 1:size(I,1) );
    else
        error('illegal value for bbox');
    end;

    % Get values at col_samples and row_samples
    IR = griddata( col_dest, row_dest, I, col_grid, row_grid );
    IR(isnan(IR)) = 0; 
