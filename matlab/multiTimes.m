function C = multiTimes( A, B, type )
% Compute 3-dimensional multiplications
%
% It can perform the following multiplications depending on type:
%  case 1,
%    C(:,:,i) = A(:,:,i)*B(:,:)
%  case 1.1,
%    C(i,:,:) = A(:,:,i)*B(:,:)
%  case 2.1,
%    C(:,:,i) = A(:,:,i)'*B(:,:,i)
%  case 3,
%    C(:,i) = A(:,:,i)*B(:,i)
%  case 3.1,
%    C(:,i) = A(:,:,i)'*B(:,i)
%
% USAGE
%  C = multiTimes( A, B, type )
%
% INPUTS
%  A         - [ma x na x oa] matrix
%  B         - [mb x nb x ob] matrix
%  type      - the type of 3-dimensional multiplication to perform
%
% OUTPUTS
%  C         - result of the multiplication
%
% EXAMPLE
%
% See also
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

ma = size(A,1); na = size(A,2); oa = size(A,3);
mb = size(B,1); nb = size(B,2); ob = size(B,3);

switch type
  case 1,
    % C(:,:,i) = A(:,:,i)*B(:,:)
    C = permute(reshape(reshape(permute(A,[1 3 2]),ma*oa,na)*B,...
      ma,oa,nb),[1 3 2]);
  case 1.1,
    % C(i,:,:) = A(:,:,i)*B(:,:)
    C = reshape(reshape(permute(A,[3 1 2]),ma*oa,na)*B,oa,ma,nb);
  case 2.1,
    % C(:,:,i) = A(:,:,i)'*B(:,:,i)
    C=reshape(sum(bsxfun(@times,reshape(permute(A,[2,1,3]),...
      [na ma 1 oa]),reshape(B,[1 mb nb oa])),2),[na nb oa]);
  case 3,
    % C(:,i) = A(:,:,i)*B(:,i)
    C = reshape(sum(bsxfun(@times, A, reshape(B,[1 mb nb ])),2),ma,nb);
  case 3.1,
    % C(:,i) = A(:,:,i)'*B(:,i)
    C = reshape(sum(bsxfun(@times, permute(A,[2,1,3]), ...
      reshape(B,[1 mb nb ])),2),na,nb);
end

