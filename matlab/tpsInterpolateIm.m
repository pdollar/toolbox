function [IR,boundX,boundY] = tpsInterpolateIm( Isrc, warp, holeVal )
% Interpolate Isrc according to the warp from Isrc->Idst.
%
% Use tpsGetWarp to obtain the warp.
%
% USAGE
%  IR = tpsInterpolateIm( Isrc, warp, [holeVal] )
%
% INPUTS
%  Isrc        - image to interpolate
%  warp        - [see tpsGetWarp] bookstein warping parameters
%  holeVal     - [0] Value of the empty warps
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
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(holeVal) ); holeVal=0; end

% warp grid points
[ gxs, gys ] = meshgrid( 1:size(Isrc,2), 1:size(Isrc,1) );
[ gxsTar, gysTar ] = tpsInterpolate( warp, gxs(:), gys(:), 0 );
gxsTar = reshape( gxsTar, size(Isrc) );
gysTar = reshape( gysTar, size(Isrc) );

% use texture mapping to generate target image
[IR,boundX,boundY]=textureMap(double(Isrc),gysTar,gxsTar,'loose',holeVal);
