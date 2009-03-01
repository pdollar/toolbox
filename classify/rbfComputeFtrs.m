function Xrbf = rbfComputeFtrs( X, rbfBasis )
% Evaluate features of X given a set of radial basis functions.
%
% See rbfComputeBasis for discussion of rbfs and general usage.
%
% USAGE
%  Xrbf = rbfComputeFtrs( X, rbfBasis )
%
% INPUTS
%  X         - [N x d] N points of d dimensions each
%  rbfBasis  - rbfBasis struct (see rbfComputeBasis)
%
% OUTPUTS
%  Xrbf      - [N x k] computed feature vectors
%
% EXAMPLE
%
% See also RBFDEMO, RBFCOMPUTEBASIS
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

N = size(X,1);
k = rbfBasis.k;
mu = rbfBasis.mu';

% for each point, compute values of all basis functions
% mu=[k x d]; onesVec=[k x 1]; Xi=[1 x d];
Xrbf = zeros( N, k );
onesVec = ones(k,1);
for i=1:N
  Xrbf(i,:) = sum( ((X(onesVec*i,:) - mu)).^2, 2 );
end
Xrbf = exp( -Xrbf/2 ./ rbfBasis.vars(ones(N,1),:) );


% normalize rbfs to sum to 1
if( 0 ); Xrbf = Xrbf ./ repmat( sum(Xrbf,2), [1 k] ); end

% add constant vector of ones as last feature
if( 0 ); Xrbf = [Xrbf ones(N,1)]; end

% add original features as features
if( 0 );  Xrbf = [X Xrbf];  end
