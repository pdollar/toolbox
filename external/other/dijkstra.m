% Runs Dijkstra's shortest path algorithm on a distance matrix.
%
% Runs Dijkstra's on the given nxn distance matrix G. G may be full or
% sparse. If G is sparse missing values mean no edge (infinite distance).
% Finds the shortest path distance to from every point i in the 1xp source
% vector S to every other point j, resulting in a [ p x n ] distance matrix
% D. 
%
% USAGE
%   [D P] = dijkstra( G, [S] )
%
% INPUT
%   G   - nxn distance matrix
%   S   - [] 1xp array of sources indices i (defaults to 1:n)
%
% OUPUT
%   D   - pxn array of shortest path lengths from i to j
%   P   - pxn array indicating the index of the previous
%         nodes on the shortest path from i to j
%
% EXAMPLE
%  n=11; G=zeros(n); for i=1:n-1; G(i,i+1)=1; end; G=G+G';
%  [D P] = dijkstra( G, 6 ); % D=[5:-1 0 1:5]; P=[2:6 -1 6:10];
%
% See also
%
% Piotr's Image&Video Toolbox      Version 2.10
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

function [D P] = dijkstra( G, S )

% parameters
n=size(G,1); assert(size(G,2)==n);
if(nargin<2 || isempty(S)), S=1:n; end
if(~issparse(G)), G=sparse(G); end;
G=0.5*(G+G');

% run c code
if(nargout<2)
  D = fibheap1( G, S );
else
  [ D P ] = fibheap1( G, S );
end
