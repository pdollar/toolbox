% Given two sets of corresponding points, calculates warp between them.
%
% Uses booksteins PAMI89 method.  Can then apply warp to a new set of
% points (tps_interpolate), or even an image (tps_interpolateiamge).
%  "Principal Warps: Thin-Plate Splines and the Decomposition of
%  Deformations".  Bookstein.  PAMI 1989.
%
% USAGE
%  [warp,L,LnInv,bendE] = tps_getwarp( lambda, xsS, ysS, xsD, ysD )
%
% INPUTS
%  lambda      - rigidity of warp (inf means warp becomes affine)
%  xsS, ysS    - [1xn] correspondence points from source image
%  xsD, ysD    - [1xn] correspondence points from destination image
%
% OUTPUTS
%  warp        - bookstein warping parameters
%  L, LnInv    - see bookstein
%  bendE       - bending energy
%
% EXAMPLE - 1
%  xsS=[0 -1 0 1];  ysS=[1 0 -1 0];  xsD=xsS;  ysD=[3/4 1/4 -5/4 1/4];
%  warp = tps_getwarp( 0, xsS, ysS, xsD, ysD );
%  [gxs, gys] = meshgrid(-1.25:.25:1.25,-1.25:.25:1.25);
%  tps_interpolate( warp, gxs, gys, 1 );
%
% EXAMPLE - 2
%  xsS = [3.6929 6.5827 6.7756 4.8189 5.6969];
%  ysS = [10.3819 8.8386 12.0866 11.2047 10.0748];
%  xsD = [3.9724 6.6969 6.5394 5.4016 5.7756];
%  ysD = [6.5354 4.1181 7.2362 6.4528 5.1142];
%  warp = tps_getwarp( 0, xsS, ysS, xsD, ysD );
%  [gxs, gys] = meshgrid(3.5:.25:7, 8.5:.25: 12.5);
%  tps_interpolate( warp, gxs, gys, 1 );
%
% See also TPS_INTERPOLATE, TPS_INTERPOLATEIMAGE, TPS_RANDOM

% Piotr's Image&Video Toolbox      Version 1.03   PPD VR
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [warp,L,LnInv,bendE] = tps_getwarp( lambda, xsS, ysS, xsD, ysD )

dim = size( xsS );
if( all(size(xsS)~=dim) || all(size(ysS)~=dim) || all(size(xsD)~=dim))
  error( 'argument sizes do not match' );
end

% get L
n = size(xsS,2);
delta_xs = xsS'*ones(1,n) - ones(n,1) * xsS;
delta_ys = ysS'*ones(1,n) - ones(n,1) * ysS;
R_sq = (delta_xs .* delta_xs + delta_ys .* delta_ys);
R_sq = R_sq+eye(n); K = R_sq .* log( R_sq ); K( isnan(K) )=0;
K = K + lambda * eye( n );
P = [ ones(n,1), xsS', ysS' ];
L = [ K, P; P', zeros(3,3) ];
LInv = L^(-1);
LnInv = LInv(1:n,1:n);

% recover W's
wx = LInv * [xsD 0 0 0]';
affinex = wx(n+1:n+3);
wx = wx(1:n);
wy = LInv * [ysD 0 0 0]';
affiney = wy(n+1:n+3);
wy = wy(1:n);

% record warp
warp.wx = wx; warp.affinex = affinex;
warp.wy = wy; warp.affiney = affiney;
warp.xsS = xsS; warp.ysS = ysS;
warp.xsD = xsD; warp.ysD = ysD;

% get bending energy (without regulariztion)
w = [wx'; wy'];
K = K - lambda * eye( n );
bendE = trace(w*K*w')/2;
