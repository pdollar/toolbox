function [B, m, n, k, rs, cs] = spBlkDiag( A, m0, n0, k0, rs, cs )
% Creates a sparse block diagonal matrix from a 3D array.
%
% Given an [mxnxk] matrix A, construct a sparse block diagonal matrix B of
% dims [m*k x n*k], containing k blocks of size mxn each, where each block
% i is taken from A(:,:,i).
%
% When computing B, a time consuming step is to compute a series of indices
% (rs,cs). These indices are fixed for given dims of A and can be re-used.
% spBlkDiag's additional inputs/outputs can be used to cache these indices.
%
% USAGE
%  [B, m, n, k, rs, cs] = spBlkDiag( A, [m0], [n0], [k0], [rs], [cs] )
%
% INPUTS
%  A       - [m x n x k] input matrix of k mxn blocks
%  m0      - cached 1st dim of A
%  n0      - cached 2nd dim of A
%  k0      - cached 3rd dim of A
%  rs      - cached list of row indices
%  cs      - cached list of col indices
%
% OUTPUT
%  B       - [m*k x n*k] sparse block diagonal matrix with k mxn blocks
%  m       - new 1st dim of A
%  n       - new 2nd dim of A
%  k       - new 3rd dim of A
%  rs      - new list of row indices
%  cs      - new list of col indices
%
% EXAMPLE
%  A=rand(3,4,2); B=spBlkDiag(A); full(B)
%
% See also SPARSE, BLKDIAG
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

[m,n,k]=size(A);

% compute the indices of the elements in the sparse matrix
if( nargin<6 || isempty(m0) || m~=m0 || n~=n0 || k~=k0 )
  ds=(1:m)'; rs=reshape(1:m*k,m,k); rs=rs(ds(:,ones(1,n)),:); rs=rs(:);
  cs=1:n*k; cs=cs(ones(m,1),:); cs=cs(:);
end

% finally generate the sparse matrix
B=sparse(rs,cs,A(:),m*k,n*k);
