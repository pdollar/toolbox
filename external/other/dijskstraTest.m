n=10; G=sparse(n,n); for i=1:n-1; G(i,i+1)=1; end; G=G+G';
% G=full(G); % causes problem for CURRENT

%%% CURRENT version: does not work
tic, [D1 P1] = dijkstra( G, 6 ); toc

%%% OLD version (w missing source): works well, fast
tic, [D2 P2] = dijkstraOld( G, 6 ); toc
D2=D2'; P2=P2';

%%% ORIG version: from isomap
tic, D3 = dijkstraOrig( G, 6 ); toc

%%%
[D1;D2;D3]
[P1;P2]