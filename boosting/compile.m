c

if( 0 ) % cleanup
  delete('compile/*');
  rmdir('compile');
  delete('*.ilk');
  delete('*.pdb');
end

if( 1 ) % compile
  if(~exist('compile','dir')), mkdir('compile'); end
  mex -g -c Savable.cpp -outdir compile
  mex -g -c Haar.cpp -outdir compile
  mex -g matEntry.cpp compile/Haar.obj compile/Savable.obj
end

A=matEntry()

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
