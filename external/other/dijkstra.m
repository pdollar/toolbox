% Uses Dijkstra's algorithm on a distance matrix.
%
% USAGE
%   [ D P ] = dijkstra( G, S )
%
% INPUT
%   G   - full or sparse distance array [n x n]. If sparse, no value
%         means no edge. If full, every value corresponds to reality (0 or not)
%   S   - array of sources from which the distance to every other
%         node will be computed [1 x p]
%
% OUPUT
%   D   - [ p x n ] array of shortest path lengths from i to j
%   P   - [ p x n ] array indicating the index of the previous
%         nodes on the shortest path from i to j
%
% EXAMPLE
%
% See also
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

function [ D P ] = dijkstra( G, S )

G=0.5*(G+G');
[ D P ] = fibheap( G, S );
