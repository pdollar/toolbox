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
  % compile common objects for which no object file
  common = {'Savable', 'Haar', 'Rand', 'ChImage' };
  n=length(common); objs=cell(1,n);
  for i=1:n
    sName=['common/' common{i} '.cpp'];
    tName=['compile/' common{i} '.obj'];
    if(~exist(tName,'file'))
      mex('-O','-c',sName,'-outdir','compile');
    end
    objs{i} = tName;
  end
  % finally compile matEntry
  mex('-O','-Icommon','-Lcommon','matEntry.cpp','-lFreeImage',objs{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
%dlmwrite('cameraman.txt',I);
%I=dlmread('res.txt'); im(I);