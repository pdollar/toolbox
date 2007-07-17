% Interpolate Isrc according to the warp from Isrc->Idst.
%
% Use tpsGetWarp to obtain the warp.
%
% USAGE
%  IR = tpsInterpolateIm( Isrc, warp, [holeValue] )
%
% INPUTS
%  Isrc        - image to interpolate
%  warp        - [see tpsGetWarp] bookstein warping parameters
%  holeValue   - [0] Value of the empty warps
%
% OUTPUTS
%  IR          - warped image
%
% EXAMPLE
%  xsS=[0 0 1 1 2 2]; ysS=[0 2 0 2 0 2]; ysD=[0 2 .5 1.5 0 2];
%  warp = tpsGetWarp(0,xsS*100,ysS*100,xsS*100,ysD*100);
%  load clown; I=padarray(X,[1 1],0,'both'); clear X caption map;
%  IR = tpsInterpolateIm( I, warp );
%  figure(1); clf; im(I); figure(2); clf; im(IR);
%
% See also TPSGETWARP, TEXTUREMAP

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [IR,boundX,boundY] = tpsInterpolateIm( Isrc, warp, holeValue )

if nargin<3 || isempty(holeValue); holeValue=0; end

% warp grid points
[ gxs, gys ] = meshgrid( 1:size(Isrc,2), 1:size(Isrc,1) );
[ gxsTar, gysTar ] = tpsInterpolate( warp, gxs(:), gys(:), 0 );
gxsTar = reshape( gxsTar, size(Isrc) );
gysTar = reshape( gysTar, size(Isrc) );

% use texture mapping to generate target image
[IR,boundX,boundY] = textureMap( double(Isrc), gysTar, gxsTar, 'loose', holeValue );
