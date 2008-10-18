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

c
% mex -O 'private/integralImagePrepare.cpp'
% mex -O cpp/matEntry.cpp cpp/rect.cpp cpp/haar.cpp

% nrep=1000;
% I=rand(100);
% I =double(imread('cameraman.tif'));

% II=IntegralImage; II.prepare(I);
% tic, for i=1:nrep
% % II.setRoi(1,1,10,10);
% prepare(II,I); A=II.II;
% end, toc

% tic, for i=1:nrep
% [II,IIsq]=integralImagePrepare(I); B=II;
% end, toc

% tic, for i=1:nrep
% [m,n]=size(I); II=zeros(m+1,n+1); IIsq=II;
% II(2:end,2:end)=cumsum(cumsum(I),2); C=II;
% IIsq(2:end,2:end)=cumsum(cumsum(I.*I),2);
% end, toc

% tic, for i=1:nrep
% D=matEntry(I);
% end, toc

% sum(sum(abs(A-B)))
% [sum(sum(abs(A-B))) sum(sum(abs(A-C))) sum(sum(abs(A-D)))]

