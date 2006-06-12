% Apply warp (obtained by tps_getwarp) to a set of new points. 
%
% INPUTS
%   xs_source, ys_source        - correspondence points from source image
%   xs_dest, ys_dest            - correspondence points from destination image
%   wx, affinex, wy, affiney    - booksteain warping parameters
%   xs, ys                      - points to apply warp to
%   show                        - whether or not to show the output
%
% OUTPUTS
%   xs_p, ys_p                  - result of warp applied to xs, ys
%
% DATESTAMP
%   29-Sep-2005  2:00pm
% 
% See also TPS_GETWARP

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [ xs_p, ys_p ] = tps_interpolate( xs_source, ys_source, xs_dest, ys_dest, ...
                                                wx, affinex, wy, affiney, xs, ys, show )
    % interpolate points (xs,ys)
    xs_p = f( wx, affinex, xs_source, ys_source, reshape(xs,1,[]), reshape(ys,1,[]) );
    ys_p = f( wy, affiney, xs_source, ys_source, reshape(xs,1,[]), reshape(ys,1,[]) );
    
    % optionally show points (xs_p, ys_p)
    if (show)
        figure(1); 
        subplot(2,1,1); plot( xs, ys, '.', 'color', [0 0 1] );
        hold( 'on' ); plot( xs_source, ys_source, '+' ); hold( 'off' );
        subplot(2,1,2); plot( xs_p, ys_p, '.' );
        hold( 'on' ); plot( xs_dest, ys_dest, '+' ); hold( 'off' );
    end;

    
% find f(x,y) for xs and ys given W and original points
function zs = f( w, affine, xs_source, ys_source, xs, ys )
    n = size(w,1);   ns = size(xs,2);
    delta_xs = [ xs' * ones(1,n) ] - [ ones(ns,1) * xs_source ];
    delta_ys = [ ys' * ones(1,n) ] - [ ones(ns,1) * ys_source ];
    dist_sq = (delta_xs .* delta_xs + delta_ys .* delta_ys); 
    dist_sq = dist_sq + eye(size(dist_sq)) + eps; 
    U = dist_sq .* log( dist_sq ); U( find(isnan(U)) )=0;
    zs = sum((U.*(ones(ns,1)*w')),2) +affine(1)*ones(ns,1) +affine(2)*xs' +affine(3)*ys';
    
    
