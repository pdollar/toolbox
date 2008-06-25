n=11; G=zeros(n); for i=1:n-1; G(i,i+1)=1; end; G=G+G';

%%% CURRENT VERSION - doesn not work
[D1 P1] = dijkstra( G, 6 );

%%% OLD VERSION W MISSING SOURCE - works well
[D2 P2] = dijkstraOld( sparse(G), 6 );
D2=D2'; P2=P2';



%%%
[D1;D2], [P1;P2]