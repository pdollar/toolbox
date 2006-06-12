% Interpolate I_source according to the warp from I_source->I_dest.  
%
% Use tps_getwarp to obtain the warp.
%
% INPUTS
%   I_source                    - image to interpolate
%   xs_source, ys_source        - correspondence points from source image
%   xs_dest, ys_dest            - correspondence points from destination image
%   wx, affinex, wy, affiney    - booksteain warping parameters
%
% OUTPUTS
%   IR      - warped image
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also TPS_GETWARP

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function IR = tps_interpolateimage( I_source, xs_source, ys_source, ...
                                    xs_dest, ys_dest, wx, affinex, wy, affiney )
    % warp grid points
    [ grid_xs, grid_ys ] = meshgrid( 1:size(I_source,2), 1:size(I_source,1) );
    [ grid_xs_target, grid_ys_target ] = tps_interpolate( xs_source, ys_source, ...
                xs_dest, ys_dest, wx, affinex, wy, affiney, grid_xs(:), grid_ys(:), 0 );
    grid_xs_target = reshape( grid_xs_target, size(I_source) );  
    grid_ys_target = reshape( grid_ys_target, size(I_source) );

    % use texture mapping to generate target image
    IR = texture_map( double(I_source), grid_ys_target, grid_xs_target, 'crop' );
