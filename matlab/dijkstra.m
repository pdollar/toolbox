function [D,P] = dijkstra( G, varargin )
% Runs Dijkstra's shortest path algorithm on a distance matrix.
%
% Runs Dijkstra's on the given SPARSE nxn distance matrix G, where missing
% values mean no edge (infinite distance). Uses a Finonacci heap resulting
% in fast computation. Finds the shortest path distance from every point
% S(i) in the 1xp source vector S to every other point j, resulting in a
% pxn distance matrix D. P(i,j) contains the second to last node on the
% path from S(i) to j. If point j is not reachable from point S(i) then
% D(i,j)=inf and P(i,j)=-1.
%
% USAGE
%   [D P] = dijkstra( G, [S] )
%
% INPUT
%   G   - sparse nxn distance matrix
%   S   - 1xp array of source indices i
%
% OUPUT
%   D   - pxn - shortest path lengths from S(i) to j
%   P   - pxn - indicies of second to last node on path from S(i) to j
%
% EXAMPLE
%  n=11; G=sparse(n,n); for i=1:n-1, G(i,i+1)=1; end; G=G+G';
%  [D,P] = dijkstra(G,5), % D=[4:-1:0 1:6]; P=[2:5 -1 5:10];
%
% See also
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.20
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

[D,P] = dijkstra1( G, varargin{:} );
