function C = multiDiv( A, B, type )
% Matrix divide each submatrix of two 3D arrays without looping.
%
% type controls the matrix multiplication to perform (for each i):
%  1    - C(:,:,i) = A(:,:,i)\B(:,:)
%  1.1  - C(i,:,:) = A(:,:,i)\B(:,:)
%  1.2  - C(i,:,:) = B(:,:)\A(:,:,i)
%  2    - C(:,:,i) = A(:,:,i)\B(:,:,i)
%  2.1  - C(:,:,i) = A(:,:,i)'\B(:,:,i)
%  2.2  - C(:,:,i) = A(:,:,i)\B(:,:,i)'
%  3    - C(:,i) = A(:,:,i)\B(:,i)
%  3.1  - C(:,i) = A(:,:,i)'\B(:,i)
% Corresponding dimensions of A and B must match appropriately.
% If type is negative, it is the same as above but with / not \
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
% EXAMPLE
%  n=10000; A=randn(2,2,n); B=randn(2);
%  tic, C1=multiDiv(A,B,1); toc
%  tic, C2=zeros(size(A)); for i=1:n, C2(:,:,i)=A(:,:,i)\B; end; toc
%
% See also BSXFUN, MULTITIMES
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

ma = size(A,1); na = size(A,2); oa = size(A,3);
mb = size(B,1); nb = size(B,2); ob = size(B,3);

% just to simplify the reading
if ma==mb; m = ma; end
if na==nb; n = na; end
if oa==ob; o = oa; end

step=max(ceil(10000/ma/na),1); s=0;

switch type
  case 1    % C(:,:,i) = A(:,:,i)\B(:,:)
  case 1.1  % C(i,:,:) = A(:,:,i)\B(:,:)
  case 1.2  % C(i,:,:) = B(:,:)\A(:,:,i)
  case 2    % C(:,:,i) = A(:,:,i)\B(:,:,i)
  case 2.1  % C(:,:,i) = A(:,:,i)'\B(:,:,i)
  case 2.2  % C(:,:,i) = A(:,:,i)\B(:,:,i)'
  case 3    % C(:,i) = A(:,:,i)\B(:,i)
	C = zeros(na,oa);
	% get the initial indices
	e=min(s+step,oa);
	[ B, m0, n0, k0, rs, cs ] = spBlkDiag( AA(:,:,s+1:e) );
	C(s*na+1:e*na)=B\BB(s*ma+1:e*ma)'; s=e;
	% continue with the other blocks if necessary
    while (s<oa); e=min(s+step,oa);
	  if e==s+step
		C(s*na+1:e*na)=spBlkDiag(AA(:,:,s+1:e), m0, n0, k0, rs, cs)\BB(s*ma+1:e*ma)'; s=e;
	  else
	    C(s*na+1:e*na)=spBlkDiag(AA(:,:,s+1:e))\BB(s*ma+1:e*ma)'; s=e;
	  end
    end
  case 3.1  % C(:,i) = A(:,:,i)'\B(:,i)
end
