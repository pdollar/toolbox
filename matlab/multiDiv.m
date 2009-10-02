function C = multiDiv( A, B, type )
% Matrix divide each submatrix of two 3D arrays without looping.
%
% type controls the matrix multiplication to perform (for each i):
%  2    - C(:,:,i) = A(:,:,i)\B(:,:,i)
%  3    - C(:,i) = A(:,:,i)\B(:,i)
% Corresponding dimensions of A and B must match appropriately.
% Other cases (see multiTimes.m) are not yet implemented.
%
% USAGE
%  C = multiDiv( A, B, type )
%
% INPUTS
%  A         - [ma x na x oa] matrix
%  B         - [mb x nb x ob] matrix
%  type      - division type (see above)
%
% OUTPUTS
%  C         - result of the division
%
%
% EXAMPLE [case 2]
%  n=10000; A=randn(3,3,n); B=randn(3,10,n);
%  tic, C1=multiDiv(A,B,2); toc
%  tic, C2=C1; for i=1:n, C2(:,:,i)=A(:,:,i)\B(:,:,i); end; toc
%  sum(abs(C1(:)-C2(:)))
%
% EXAMPLE [case 3]
%  n=30000; A=randn(2,2,n); B=randn(2,n);
%  tic, C1=multiDiv(A,B,3); toc
%  tic, C2=C1; for i=1:n, C2(:,i)=A(:,:,i)\B(:,i); end; toc
%  sum(abs(C1(:)-C2(:)))
%
% See also MULTITIMES, SPBLKDIAG
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

ma = size(A,1); na = size(A,2); oa = size(A,3);
mb = size(B,1); nb = size(B,2); ob = size(B,3); %#ok<NASGU>
step=max(ceil(100000/ma/na),1);

switch type
  case 2    % C(:,:,i) = A(:,:,i)\B(:,:,i)
    C=zeros(na,nb,oa); inds=[]; s=0;
    while( s<oa ), e=min(s+step,oa);
      [A1,inds] = spBlkDiag(A(:,:,s+1:e),inds);
      B1 = reshape(permute(B(:,:,s+1:e),[1 3 2]),[],nb);
      C(:,:,s+1:e) = permute(reshape(A1\B1,[na e-s nb]),[1 3 2]); s=e;
    end
  case 3    % C(:,i) = A(:,:,i)\B(:,i)
    C=zeros(na,oa); inds=[]; s=0;
    while( s<oa ), e=min(s+step,oa);
      [A1,inds] = spBlkDiag(A(:,:,s+1:e),inds);
      C(s*na+1:e*na) = A1 \ B(s*ma+1:e*ma)'; s=e;
    end
  otherwise
    error('unknown type: %f',type);
end
