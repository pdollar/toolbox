function C = multiTimes( A, B, type )
% Matrix multiply each submatrix of two 3D arrays without looping.
%
% type controls the matrix multiplication to perform (for each i):
%  1    - C(:,:,i) = A(:,:,i)*B(:,:)
%  1.1  - C(i,:,:) = A(:,:,i)*B(:,:)
%  1.2  - C(:,:,i) = A(:,:)*B(:,:,i)
%  2    - C(:,:,i) = A(:,:,i)*B(:,:,i)
%  2.1  - C(:,:,i) = A(:,:,i)'*B(:,:,i)
%  2.2  - C(:,:,i) = A(:,:,i)*B(:,:,i)'
%  3    - C(:,i) = A(:,:,i)*B(:,i)
%  3.1  - C(:,i) = A(:,:,i)'*B(:,i)
%  3.2  - C(:,i) = A(:,i)'*B(:,:,i)
%  4.1  - C(i) = trace(A(:,:,i)'*B(:,:,i))
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
% Piotr's Image&Video Toolbox      Version 2.52
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

ma = size(A,1); na = size(A,2); oa = size(A,3);
mb = size(B,1); nb = size(B,2); ob = size(B,3);

% just to simplify the reading
%if( ma==mb ); m = ma; end
%if( na==nb ); n = na; end
if( oa==ob ); o = oa; end

switch type
  case 1    % C(:,:,i) = A(:,:,i)*B(:,:)
    C = permute(reshape(reshape(permute(A,[1 3 2]),ma*oa,na)*B,...
      ma,oa,nb),[1 3 2]);
  case 1.1  % C(i,:,:) = A(:,:,i)*B(:,:)
    C = reshape(reshape(permute(A,[3 1 2]),ma*oa,na)*B,oa,ma,nb);
  case 1.2  % C(:,:,i) = A(:,:)*B(:,:,i)
    C = reshape(A*reshape(B,mb,nb*ob),ma,nb,ob);
  case 2    % C(:,:,i) = A(:,:,i)*B(:,:,i)
    C = reshape(sum(bsxfun(@times,reshape(A,...
      [ma na 1 o]),reshape(B,[1 mb nb o])),2),[ma nb o]);
  case 2.1  % C(:,:,i) = A(:,:,i)'*B(:,:,i)
    C = reshape(sum(bsxfun(@times,reshape(permute(A,[2,1,3]),...
      [na ma 1 o]),reshape(B,[1 mb nb o])),2),[na nb o]);
  case 2.2  % C(:,:,i) = A(:,:,i)*B(:,:,i)'
    C = reshape(sum(bsxfun(@times,reshape(A,...
      [ma na 1 o]),reshape(permute(B,[2,1,3]),[1 nb mb o])),2),[ma mb o]);
  case 3    % C(:,i) = A(:,:,i)*B(:,i)
    C = reshape(sum(bsxfun(@times, A, reshape(B,[1 mb nb ])),2),ma,nb);
  case 3.1  % C(:,i) = A(:,:,i)'*B(:,i)
    C = reshape(sum(bsxfun(@times, permute(A,[2,1,3]), ...
      reshape(B,[1 mb nb ])),2),na,nb);
  case 3.2  % C(:,i) = A(:,i)'*B(:,:,i)
    C = reshape(sum(bsxfun(@times, reshape(A,ma,1,na), B),1), nb,na);
  case 4.1  % C(i) = tr(A(:,:,i)'*B(:,:,i))
    C = reshape(sum(sum(A.*B,1),2),1,o);
  otherwise
    error('unknown type: %f',type);
end
