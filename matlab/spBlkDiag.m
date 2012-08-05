function [B,inds] = spBlkDiag( A, inds )
% Creates a sparse block diagonal matrix from a 3D array.
%
% Given an [mxnxk] matrix A, construct a sparse block diagonal matrix B of
% dims [m*k x n*k], containing k blocks of size mxn each, where each block
% i is taken from A(:,:,i).
%
% When computing B, a time consuming step is to compute a series of
% indices. These indices are fixed for given dims of A and can be re-used.
% spBlkDiag's additional input/output can be used to cache these indices.
%
% USAGE
%  [B, inds] = spBlkDiag( A, [inds] )
%
% INPUTS
%  A       - [m x n x k] input matrix of k mxn blocks
%  inds    - cached indices for faster computation
%
% OUTPUT
%  B       - [m*k x n*k] sparse block diagonal matrix with k mxn blocks
%  inds    - cached indices for faster computation
%
% EXAMPLE
%  A=rand(3,4,2); B=spBlkDiag(A); full(B)
%
% See also SPARSE, BLKDIAG
%
% Piotr's Image&Video Toolbox      Version 2.35
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

[m,n,k]=size(A);

% compute the indices of the elements in the sparse matrix
if( nargin<2 || isempty(inds) || m~=inds.m || n~=inds.n || k~=inds.k )
  ds=(1:m)'; rs=reshape(1:m*k,m,k); rs=rs(ds(:,ones(1,n)),:); rs=rs(:);
  cs=1:n*k; cs=cs(ones(m,1),:); cs=cs(:);
  inds=struct('m',m,'n',n,'k',k,'rs',rs,'cs',cs);
else
  rs=inds.rs; cs=inds.cs;
end

% finally generate the sparse matrix
B=sparse(rs,cs,A(:),m*k,n*k);
