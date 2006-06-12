% Given two sets of corresponding points, calculates warp between them.
%
% Uses booksteins PAMI89 method.  Can then apply warp to a new set of
% points (tps_interpolate), or even an image (tps_interpolateiamge).
%
% INPUTS
%   lambda                      - contolls rigidity of warp 
%                                 (lambda->inf means warp becomes affine)
%   xs_source, ys_source        - correspondence points from source image
%   xs_dest, ys_dest            - correspondence points from destination image
%
% OUTPUTS
%   wx, affinex, wy, affiney    - booksteain warping parameters
%   L, Ln_inv                    - see bookstein
%   bend_energy                 - bending energy
%
% EXAMPLE
%   % example 1
%   xs = [ 0 -1 0 1 ]; ys = [1 0 -1 0]; xs_dest = xs; ys_dest = [3/4 1/4 -5/4 1/4];
%   [grid_xs, grid_ys] = meshgrid( -1.25:.25:1.25, -1.25:.25:1.25 );
%   [wx,ax,wy,ay,L,Ln_inv,benden] = tps_getwarp( 0, xs, ys, xs_dest, ys_dest );
%   tps_interpolate( xs, ys, xs_dest, ys_dest, wx, ax, wy, ay, grid_xs, grid_ys, 1 );
%   % example 2
%   xs = [3.6929 6.5827 6.7756 4.8189 5.6969 ]; 
%   ys = [10.3819 8.8386 12.0866 11.2047 10.0748 ]; 
%   xs_dest = [ 3.9724 6.6969 6.5394 5.4016 5.7756 ]; 
%   ys_dest = [ 6.5354 4.1181 7.2362 6.4528 5.1142 ]; 
%   [grid_xs, grid_ys] = meshgrid( 3.5:.25:7, 8.5:.25: 12.5  );
%   [wx,ax,wy,ay,L,Ln_inv,benden] = tps_getwarp( 0, xs, ys, xs_dest, ys_dest );
%   tps_interpolate( xs, ys, xs_dest, ys_dest, wx, ax, wy, ay, grid_xs, grid_ys, 1 );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also TPS_INTERPOLATE, TPS_INTERPOLATEIMAGE, TPS_RANDOM

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [wx, affinex, wy, affiney, L, Ln_inv, bend_energy ] = ...
                      tps_getwarp( lambda, xs_source, ys_source, xs_dest, ys_dest )
    dim = size( xs_source );
    if( all(size(xs_source)~=dim) || all(size(ys_source)~=dim) || all(size(xs_dest)~=dim))
        error( 'argument sizes do not match' ); end;
    
    % get L
    n = size(xs_source,2);
    delta_xs = [ xs_source' * ones(1,n) ] - [ ones(n,1) * xs_source ];
    delta_ys = [ ys_source' * ones(1,n) ] - [ ones(n,1) * ys_source ];
    R_sq = (delta_xs .* delta_xs + delta_ys .* delta_ys);  
    R_sq = R_sq+eye(n); K = R_sq .* log( R_sq ); K( find(isnan(K)) )=0; 
    K = K + lambda * eye( n );
    P = [ ones(n,1), xs_source', ys_source' ];
    L = [ K, P; P', zeros(3,3) ];
    LInv = L^(-1);
    Ln_inv = LInv(1:n,1:n);
    
    % recover W's
    wx = LInv * [xs_dest 0 0 0]';
    affinex = wx(n+1:n+3);
    wx = wx(1:n);
    
    wy = LInv * [ys_dest 0 0 0]';
    affiney = wy(n+1:n+3);
    wy = wy(1:n);
    
    % get bending energy (without regulariztion)
    w = [wx'; wy'];
    K = K - lambda * eye( n );
    bend_energy = trace(w*K*w')/2;
    
    
    
    
    
    
    
