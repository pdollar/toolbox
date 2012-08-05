function varargout = pcaApply( X, U, mu, k )
% Companion function to pca.
%
% Use pca.m to retrieve the principal components U and the mean mu from a
% set of vectors x, then use pcaApply to get the first k coefficients of
% x in the space spanned by the columns of U. See pca for general usage.
%
% If x is large, pcaApply first splits and processes x in parts. This
% allows pcaApply to work even for very large arrays.
%
% This may prove useful:
%  siz=size(X);  k=100;  Uim=reshape(U(:,1:k),[siz(1:end-1) k ]);
%
% USAGE
%  [ Yk, Xhat, avsq ] = pcaApply( X, U, mu, k )
%
% INPUTS
%  X           - data for which to get PCA coefficients
%  U           - returned by pca.m
%  mu          - returned by pca.m
%  k           - number of principal coordinates to approximate X with
%
% OUTPUTS
%  Yk          - first k coordinates of X in column space of U
%  Xhat        - approximation of X corresponding to Yk
%  avsq        - measure of squared error normalized to fall between [0,1]
%
% EXAMPLE
%
% See also PCA, PCAVISUALIZE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% sizes / dimensions
siz = size(X);  nd = ndims(X);  [D,r] = size(U);
if(D==prod(siz) && ~(nd==2 && siz(2)==1)); siz=[siz, 1]; nd=nd+1; end
n = siz(end);

% some error checking
if(prod(siz(1:end-1))~=D); error('incorrect size for X or U'); end
if(isa(X,'uint8')); X = double(X); end
if(k>r); warning(['k set to ' int2str(r)]); k=r; end; %#ok<WNTAG>

% If X is small simply call pcaApply1 once.
% OW break up X and call pcaApply1 multiple times and recombine.
maxWidth = ceil( (10^7) / D );
if( maxWidth > n )
  varargout = cell(1,nargout);
  [varargout{:}] = pcaApply1( X, U, mu, k );

else
  inds = {':'}; inds = inds(:,ones(1,nd-1));
  Yk = zeros( k, n );  Xhat = zeros( siz );
  avsq = 0;  avsqOrig = 0;  last = 0;
  if( nargout==3 ); out=cell(1,4); else out=cell(1,nargout); end;
  while(last < n)
    first=last+1;  last=min(first+maxWidth-1,n);
    Xi = X(inds{:}, first:last);
    [out{:}] = pcaApply1( Xi, U, mu, k );
    Yk(:,first:last) = out{1};
    if( nargout>=2 );  Xhat(inds{:},first:last)=out{2};  end;
    if( nargout>=3 );  avsq=avsq+out{3}; avsqOrig=avsqOrig+out{4};  end;
  end;
  varargout = {Yk, Xhat, avsq/avsqOrig};
end

function [ Yk, Xhat, avsq, avsqOrig ] = pcaApply1( X, U, mu, k )

% sizes / dimensions
siz = size(X);  nd = ndims(X);  [D,r] = size(U);
if(D==prod(siz) && ~(nd==2 && siz(2)==1)); siz=[siz, 1]; nd=nd+1; end
n = siz(end);

% subtract mean, then flatten X
Xorig = X;
muRep = repmat(mu, [ones(1,nd-1), n ] );
X = X - muRep;
X = reshape( X, D, n );

% Find Yk, the first k coefficients of X in the new basis
if( r<=k ); Uk=U; else Uk=U(:,1:k); end;
Yk = Uk' * X;

% calculate Xhat - the approx of X using the first k princ components
if( nargout>1 )
  Xhat = Uk * Yk;
  Xhat = reshape( Xhat, siz );
  Xhat = Xhat + muRep;
end

% caclulate average value of (Xhat-Xorig).^2 compared to average value
% of X.^2, where X is Xorig without the mean.  This is equivalent to
% what fraction of the variance is captured by Xhat.
if( nargout>2 )
  avsq = Xhat - Xorig;
  avsq = dot(avsq(:),avsq(:));
  avsqOrig = dot(X(:),X(:));
  if( nargout==3 ); avsq=avsq/avsqOrig; end
end
