n=100; G=sparse(n,n); for i=1:n-1; G(i,i+1)=1; end; G=G+G';
% G=full(G); % causes problem for CURRENT
nTrial=10000;

%%% CURRENT version: does not work
tic, for i=1:nTrial; [D1] = dijkstra( G, 6 ); end; toc
%tic, for i=1:nTrial; [D1] = fibheap1( G, 6 ); end; toc

%%% OLD version (w missing source): works well, fast
% tic, [D2 P2] = dijkstraOld( G, 6 ); toc
% D2=D2'; P2=P2';

%%% ORIG version: from isomap
tic, for i=1:nTrial; D3 = dijkstraOrig( G, 6 ); end; toc

sum(D1-D3)
%%%
% [D1;D3]
% [P1]


%[D5,P5]=dijkstra(G,5); [D6,P6]=dijkstra(G,6); 
%[D56,P56]=dijkstra( G, 5:6 ); [D5;D6]-D56, [P5;P6]-P56,