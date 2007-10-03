% Apply warp (obtained by tpsGetWarp) to a set of new points.
%
% USAGE
%  [xsR,ysR] = tpsInterpolate( warp, xs, ys, [show] )
%
% INPUTS
%  warp     - [see tpsGetWarp] bookstein warping parameters
%  xs, ys   - points to apply warp to
%  show     - [1] will display results in figure(show)
%
% OUTPUTS
%  xsR, ysR - result of warp applied to xs, ys
%
% EXAMPLE
%
% See also TPSGETWARP

% Piotr's Image&Video Toolbox      Version 2.0
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [xsR,ysR] = tpsInterpolate( warp, xs, ys, show )

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
delXs = xs'*ones(1,n) - ones(ns,1)*xsS;
delYs = ys'*ones(1,n) - ones(ns,1)*ysS;
distSq = (delXs .* delXs + delYs .* delYs);
distSq = distSq + eye(size(distSq)) + eps;
U = distSq .* log( distSq ); U( isnan(U) )=0;
zs = aff(1)*ones(ns,1)+aff(2)*xs'+aff(3)*ys';
zs = zs + sum((U.*(ones(ns,1)*w')),2);
