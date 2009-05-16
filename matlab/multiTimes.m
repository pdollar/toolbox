function C = multiTimes( A, B, type )
% Matrix multiply each submatrix of two 3D arrays without looping.
%
% type controls the matrix multiplication to perform (for each i):
%  1    - C(:,:,i) = A(:,:,i)*B(:,:)
%  1.1  - C(i,:,:) = A(:,:,i)*B(:,:)
%  2.1  - C(:,:,i) = A(:,:,i)'*B(:,:,i)
%  3    - C(:,i) = A(:,:,i)*B(:,i)
%  3.1  - C(:,i) = A(:,:,i)'*B(:,i)
% Corresponding dimensions of A and B must match appropriately.
%
% USAGE
%  C = multiTimes( A, B, type )
%
% INPUTS
%  A         - [ma x na x oa] matrix
%  B         - [mb x nb x ob] matrix
%  type      - multiplication type (see above)
%
% OUTPUTS
%  C         - result of the multiplication
%
% EXAMPLE
%  n=10000; A=randn(2,2,n); B=randn(2);
%  tic, C1=multiTimes(A,B,1); toc
%  tic, C2=zeros(size(A)); for i=1:n, C2(:,:,i)=A(:,:,i)*B; end; toc
%
% See also BSXFUN, MTIMES
%
% Piotr's Image&Video Toolbox      Version 2.30
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

ma = size(A,1); na = size(A,2); oa = size(A,3);
mb = size(B,1); nb = size(B,2); ob = size(B,3);

switch type
  case 1    % C(:,:,i) = A(:,:,i)*B(:,:)
    C = permute(reshape(reshape(permute(A,[1 3 2]),ma*oa,na)*B,...
      ma,oa,nb),[1 3 2]);
  case 1.1  % C(i,:,:) = A(:,:,i)*B(:,:)
    C = reshape(reshape(permute(A,[3 1 2]),ma*oa,na)*B,oa,ma,nb);
  case 2.1  % C(:,:,i) = A(:,:,i)'*B(:,:,i)
    C=reshape(sum(bsxfun(@times,reshape(permute(A,[2,1,3]),...
      [na ma 1 oa]),reshape(B,[1 mb nb ob])),2),[na nb oa]);
  case 3    % C(:,i) = A(:,:,i)*B(:,i)
    C = reshape(sum(bsxfun(@times, A, reshape(B,[1 mb nb ])),2),ma,nb);
  case 3.1  % C(:,i) = A(:,:,i)'*B(:,i)
    C = reshape(sum(bsxfun(@times, permute(A,[2,1,3]), ...
      reshape(B,[1 mb nb ])),2),na,nb);
end
