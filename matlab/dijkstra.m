% Runs Dijkstra's shortest path algorithm on a distance matrix.
%
% Runs Dijkstra's on the given SPARSE nxn distance matrix G, where missing
% values mean no edge (infinite distance). Uses a Finonacci heap resulting
% in fast computation. Finds the shortest path distance from every point
% S(i) in the 1xp source vector S to every other point j, resulting in a
% pxn distance matrix D. If point j is not reachable from point S(i) then
% D(i,j)=inf and P(i,j)=0. 
%
% Note: requires c++ compiler (to compile dijkstra.cpp). mex command is:
%  mex fibheap.cpp dijkstra.cpp -output dijkstra
% which must be run from /private. To set c++ compiler run 'mex -setup'.
%
% USAGE
%   [D P] = dijkstra( G, [S] )
%
% INPUT
%   G   - nxn distance matrix
%   S   - [] 1xp array of source indices i (defaults to 1:n)
%
% OUPUT
%   D   - pxn - shortest path lengths from S(i) to j
%   P   - pxn - indicies of second to last node on path from S(i) to j
%
% EXAMPLE
%  n=11; G=sparse(n,n); for i=1:n-1; G(i,i+1)=1; end; G=G+G';
%  [D P] = dijkstra( G, 5 ); % D=[5:-1 0 1:5]; P=[2:6 -1 6:10];
%
% See also
%
% Piotr's Image&Video Toolbox      Version 2.10
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% function [D P] = dijkstra( G, S )
% 
% % parameters
% n=size(G,1); assert(size(G,2)==n);
% if(nargin<2 || isempty(S)), S=1:n; end
% 
% % convert G to suitable format
% assert(issparse(G));
% G=0.5*(G+G');
% 
% % run c code
% if(nargout<2), D=fibheap( G, S ); else [D,P] = fibheap( G, S ); end
% 
% end
