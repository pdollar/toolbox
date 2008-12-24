c
addpath(genpath('/common/pdollar/toolbox'));
cd(fileparts(mfilename('fullpath')));

if( 0 ) % cleanup
  delete('compile/*');
  rmdir('compile');
  delete('*.ilk');
  delete('*.pdb');
end

if( 1 ) % compile
  if(~exist('compile','dir')), mkdir('compile'); end
  mex -g -c common/Savable.cpp -outdir compile
  mex -g -c common/Haar.cpp -outdir compile
  mex -g -Icommon matEntry.cpp compile/Haar.obj compile/Savable.obj
  %mex -g -Icommon matEntry.cpp compile/Haar.o compile/Savable.o
end

% A = matEntry('getObject',1)
% A=rand(3); B=matEntry('transpose',A); A-B'

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

% addpath(genpath('/common/pdollar/toolbox'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%I=imread('cameraman.tif');
% dlmwrite('cameraman.txt',I);
%I=dlmread('res.txt'); im(I);