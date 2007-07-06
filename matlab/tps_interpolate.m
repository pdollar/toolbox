% Apply warp (obtained by tps_getwarp) to a set of new points.
%
% USAGE
%  [xsR,ysR] = tps_interpolate( warp, xs, ys, [show] )
%
% INPUTS
%  warp     - [see tps_getwarp] bookstein warping parameters
%  xs, ys   - points to apply warp to
%  [show]   - will display results in figure(show)
%
% OUTPUTS
%  xsR, ysR - result of warp applied to xs, ys
%
% EXAMPLE
%
% See also TPS_GETWARP

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [xsR,ysR] = tps_interpolate( warp, xs, ys, show )

if( nargin<4 || isempty(show)); show = 1; end

wx = warp.wx; affinex = warp.affinex;
wy = warp.wy; affiney = warp.affiney;
xsS = warp.xsS; ysS = warp.ysS;
xsD = warp.xsD; ysD = warp.ysD;

% interpolate points (xs,ys)
xsR = f( wx, affinex, xsS, ysS, xs(:)', ys(:)' );
ysR = f( wy, affiney, xsS, ysS, xs(:)', ys(:)' );

% optionally show points (xsR, ysR)
if( show )
  figure(show);
  subplot(2,1,1); plot( xs, ys, '.', 'color', [0 0 1] );
  hold('on');  plot( xsS, ysS, '+' );  hold('off');
  subplot(2,1,2); plot( xsR, ysR, '.' );
  hold('on');  plot( xsD, ysD, '+' );  hold('off');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% find f(x,y) for xs and ys given W and original points
function zs = f( w, aff, xsS, ysS, xs, ys )

n = size(w,1);   ns = size(xs,2);
del_xs = xs'*ones(1,n) - ones(ns,1)*xsS;
del_ys = ys'*ones(1,n) - ones(ns,1)*ysS;
dist_sq = (del_xs .* del_xs + del_ys .* del_ys);
dist_sq = dist_sq + eye(size(dist_sq)) + eps;
U = dist_sq .* log( dist_sq ); U( isnan(U) )=0;
zs = aff(1)*ones(ns,1)+aff(2)*xs'+aff(3)*ys';
zs = zs + sum((U.*(ones(ns,1)*w')),2);
