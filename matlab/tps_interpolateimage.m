% Interpolate Isrc according to the warp from Isrc->Idst.
%
% Use tps_getwarp to obtain the warp.
%
% USAGE
%  IR = tps_interpolateimage( Isrc, warp )
%
% INPUTS
%  Isrc   - image to interpolate
%  warp   - [see tps_getwarp] bookstein warping parameters
%
% OUTPUTS
%  IR     - warped image
%
% EXAMPLE
%  xsS=[0 0 1 1 2 2]; ysS=[0 2 0 2 0 2]; ysD=[0 2 .5 1.5 0 2];
%  warp = tps_getwarp(0,xsS*100,ysS*100,xsS*100,ysD*100);
%  load clown; I=padarray(X,[1 1],0,'both'); clear X caption map;
%  IR = tps_interpolateimage( I, warp );
%  figure(1); clf; im(I); figure(2); clf; im(IR);
%
% See also TPS_GETWARP

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function IR = tps_interpolateimage( Isrc, warp )

% warp grid points
[ gxs, gys ] = meshgrid( 1:size(Isrc,2), 1:size(Isrc,1) );
[ gxsTar, gysTar ] = tps_interpolate( warp, gxs(:), gys(:), 0 );
gxsTar = reshape( gxsTar, size(Isrc) );
gysTar = reshape( gysTar, size(Isrc) );

% use texture mapping to generate target image
IR = texture_map( double(Isrc), gysTar, gxsTar, 'loose' );
