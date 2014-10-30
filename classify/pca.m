function [U,mu,vars] = pca( X )
% Principal components analysis (alternative to princomp).
%
% A simple linear dimensionality reduction technique. Use to create an
% orthonormal basis for the points in R^d such that the coordinates of a
% vector x in this basis are of decreasing importance. Instead of using all
% d basis vectors to specify the location of x, using only the first k<d
% still gives a vector xhat that is close to x.
%
% This function operates on arrays of arbitrary dimension, by first
% converting the arrays to vectors. If X is m+1 dimensional, say of size
% [d1 x d2 x...x dm x n], then the first m dimensions of X are combined. X
% is flattened to be 2 dimensional: [dxn], with d=prod(di). Once X is
% converted to 2 dimensions of size dxn, each column represents a single
% observation, and each row is a different variable. Note that this is the
% opposite of many matlab functions such as princomp. If X is MxNxn, then
% X(:,:,i) represents the ith observation (useful for stack of n images),
% likewise for n videos X is MxNxKxn. If X is very large, it is sampled
% before running PCA. Use this function to retrieve the basis U. Use
% pcaApply to retrieve that basis coefficients for a novel vector x. Use
% pcaVisualize(X,...) for visualization of approximated X.
%
% To calculate residuals:
%  residuals = cumsum(vars/sum(vars)); plot(residuals,'-.')
%
% USAGE
%  [U,mu,vars] = pca( X )
%
% INPUTS
%  X         - [d1 x ... x dm x n], treated as n [d1 x ... x dm] elements
%
% OUTPUTS
%  U         - [d x r], d=prod(di), each column is a principal component
%  mu        - [d1 x ... x dm] mean of X
%  vars      - sorted eigenvalues corresponding to eigenvectors in U
%
% EXAMPLE
%  load pcaData;
%  [U,mu,vars] = pca( I3D1(:,:,1:12) );
%  [Y,Xhat,avsq] = pcaApply( I3D1(:,:,1), U, mu, 5 );
%  pcaVisualize( U, mu, vars, I3D1, 13, [0:12], [], 1 );
%  Xr = pcaRandVec( U, mu, vars, 1, 25, 0, 3 );
%
% See also princomp, pcaApply, pcaVisualize, pcaRandVec, visualizeData
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.24
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% set X to be zero mean, then flatten
d=size(X); n=d(end); d=prod(d(1:end-1));
if(~isa(X,'double')), X=double(X); end
if(n==1); mu=X; U=zeros(d,1); vars=0; return; end
mu = mean( X, ndims(X) );
X = bsxfun(@minus,X,mu)/sqrt(n-1);
X = reshape( X, d, n );

% make sure X not too large or SVD slow O(min(d,n)^2.5)
m=2500; if( min(d,n)>m ), X=X(:,randperm(n,m)); n=m; end

% get principal components using the SVD of X: X=U*S*V'
if( 0 )
  [U,S]=svd(X,'econ'); vars=diag(S).^2;
elseif( d>n )
  [~,SS,V]=robustSvd(X'*X); vars=diag(SS);
  U = X * V * diag(1./sqrt(vars));
else
  [~,SS,U]=robustSvd(X*X'); vars=diag(SS);
end

% discard low variance prinicipal components
K=vars>1e-30; vars=vars(K); U=U(:,K);

end

function [U,S,V] = robustSvd( X, trials )
% Robust version of SVD more likely to always converge.
% [Converge issues only seem to appear on Matlab 2013a in Windows.]
if(nargin<2), trials=100; end
try [U,S,V] = svd(X); catch
  if(trials<=0), error('svd did not converge'); end
  n=numel(X); j=randi(n); X(j)=X(j)+eps;
  [U,S,V]=robustSvd(X,trials-1);
end
end
