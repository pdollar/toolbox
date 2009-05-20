function [ U, mu, vars ] = pca( X )
% Principal components analysis (alternative to princomp).
%
% A simple linear dimensionality reduction technique.  Use to create an
% orthonormal basis for the points in R^D such that the coordinates of a
% vector x in this basis are of decreasing importance.  Instead of using
% all D basis vectors to specify the location of x, using only the first
% k<D still gives a vector xhat that is close to x.
%
% This function operates on arrays of arbitrary dimension, by first
% converting the arrays to vector.  If X is m+1 dimensional, say of size
% [d1 x d2 x...x dm x n], then the first m dimensions of X are combined. X
% is flattened to be 2 dimensional: [Dxn], with D=prod(di). Once X is
% converted to 2 dimensions of size Dxn, each column represents a single
% observation, and each row is a different variable.  Note that this is the
% opposite of many matlab functions such as princomp.  If X is MxNxn, then
% X(:,:,i) represents the ith observation (useful for stack of n images),
% likewise for n videos X is MxNxKxn. If X is very large, it is sampled
% before running PCA, using subsampleMatrix. Use this function to retrieve
% the basis U.  Use pcaApply to retrieve that basis coefficients for a
% novel vector x. Use pcaVisualize(X,...) for visualization of approximated
% X.
%
% To calculate residuals:
%  residuals = cumsum(vars / sum(vars)); plot( residuals, '-.' )
%
% USAGE
%  [ U, mu, vars ] = pca( X )
%
% INPUTS
%  X         - [d1 x ... x dm x n], treated as n [d1 x ... x dm] elements
%
% OUTPUTS
%  U         - [D x r], D=prod(di), each column is a principal component
%  mu        - [d1 x ... x dm] mean of X.
%  vars      - sorted eigenvalues corresponding to eigenvectors in U
%
% EXAMPLE
%  load pcaData;
%  [ U, mu, vars ] = pca( I3D1(:,:,1:12) );
%  [ Y, Xhat, avsq ] = pcaApply( I3D1(:,:,1), U, mu, 5 );
%  pcaVisualize( U, mu, vars, I3D1, 13, [0:12], [], 1 );
%  Xr = pcaRandVec( U, mu, vars, 1, 25, 0, 3 );
%
% See also PRINCOMP, PCAAPPLY, PCAVISUALIZE, PCARANDVEC
% VISUALIZEDATA, SUBSAMPLEMATRIX
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% Will run out of memory if X has too many elements.
maxmegs = 200;
if( ~isa(X,'double') )
  s=whos('X'); nbytes=s.bytes/numel(X);
  X = subsampleMatrix( X, maxmegs * nbytes/8 );
  X = double(X);
else
  X = subsampleMatrix( X, maxmegs );
end

% dimensions
siz=size(X);  nd=ndims(X);  D=prod(siz(1:end-1));  n=siz(end);
if(n==1); mu=X; U=zeros(D,1); vars=0; return; end

% set X to be zero mean, then flatten
mu = mean( X, nd );
muRep = repmat(mu, [ones(1,nd-1), n ] );
X = X - muRep;
X = reshape( X, D, n );
X = X / sqrt(n-1); %normalize vars

% make sure X does not exceed certain size or SVD too slow
maxN=1500; if( min(D,n)>maxN ); X=X(:,randSample(n,maxN)); n=maxN; end;

% get principal components using the SVD- X=U*S*V';  maxrank=min(n-1,D)
% basically same as svd(X,'econ'), slightly faster?
if( D>n )
  [V,SS,V] = svd( X' * X );
  keepLocs = diag(SS) > 1e-30;
  SS = SS(keepLocs,keepLocs);
  V = V(:,keepLocs);
  U = X * V * diag(1./sqrt(diag(SS)));
else
  [U,SS,U] = svd( X * X' );
  keepLocs = diag(SS) > 1e-30;
  SS = SS(keepLocs,keepLocs);
  U = U(:,keepLocs);
end

% eigenvalues squared
vars = diag(SS);

%%% THE FOLLOWING IS USED TO TIME SVD
% t=[]; rs = [100:50:500 750 1000];
% for r=rs; tic; [u,s,v] = svd(rand(r)); t(end+1)=toc; r, end;
% plot(rs,t,'+r'); hold('on');
% fplot( '1e-7*(x)^2.78', [1,1000] ); hold('off');
% x=1500; 1e-7*(x)^2.78 / 60 %minutes
%%%
