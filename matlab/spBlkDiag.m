function [ B, m, n, k, rs, cs ] = spBlkDiag( A, m0, n0, k0, rs, cs )
% Creates a sparse block diagonal matrix from a 3D array
% 
% If A is too big to create a big sparse matrix, it is nice to call
% this function with submatrices of (e.g. A(:,:,1:10)).
% In this case, the temporary indices should be stored and resent
% to spBlkDiag for efficiency purposes.
% Most users probably just need to call B = spBlkDiag( A )
%
% USAGE
%  B = spBlkDiag( A )
%  [ B, m, n, k, rs, cs ] = spBlkDiag( A, m0, n0, k0, rs, cs )
%
% INPUTS
%  A       - [ m x n x k ] matrix containing the k blocks to diagonalize
%  m0      - previous first dimension of A
%  n0      - previous second dimension of A
%  k0      - previous third dimension of A
%  rs      - previous list of row indices
%  cs      - previous list of column indices
%
% OUTPUT
%  B       - [ m*k x n*k ] sparse matrix containing the k blocks
%  m       - new first dimension of A
%  n       - new second dimension of A
%  k       - new third dimension of A
%  rs      - new list of row indices
%  cs      - new list of column indices
%
% EXAMPLE
%  spBlkDiag(rang(3,4,2));
%
% See also 
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

[m,n,k]=size(A);

% compute the indices of the elements in the sparse matrix
if (nargin==1 || isempty(m0) || m~=m0 || n~=n0 || k~=k0 )
  ds=(1:m)'; rs=reshape(1:m*k,m,k); rs=rs(ds(:,ones(1,n)),:); rs=rs(:);
  cs=1:n*k; cs=cs(ones(m,1),:); cs=cs(:);
end

% finally generate the sparse matrix
B=sparse(rs,cs,A(:),m*k,n*k);
