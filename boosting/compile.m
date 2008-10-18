%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

c
%mex rect.cpp -c
% mex -O matEntry.cpp rect.cpp haar.cpp


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A=rand(100);
% tic
% B=matEntry(A);
% toc
% tic
% t=ones(1,10); C=conv2(conv2(A,t,'valid'),t','valid');
% toc
% % figure(1); im(B)
% % figure(2); im(C)
% sum(sum(abs(B-C)))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% n=10000;
% A=rand(5)*2;
% 
% tic, for i=1:n
% B=matEntry(A);
% end, toc
% 
% tic, for i=1:n
% [m,n]=size(A); C=zeros(m+1,n+1); C2=C;
% C(2:end,2:end)=cumsum(cumsum(A),2);
% C2(2:end,2:end)=cumsum(cumsum(A.*A),2);
% end, toc
% 
% sum(sum(abs(B-C2)))