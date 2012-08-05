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
% Piotr's Image&Video Toolbox      Version 2.50
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% compute distance to each basis function
% mu=[k x d]; onesK=[k x 1]; Xi=[1 x d];
Xrbf = pdist2(X,rbfBasis.mu','sqeuclidean');

% compute gaussian response
if( rbfBasis.globalVar )
  Xrbf = exp( Xrbf / (-2*rbfBasis.var) );
else
  Xrbf = exp( bsxfun(@rdivide, Xrbf, -2*rbfBasis.vars ) );
end

% add constant vector of ones as last feature
if( rbfBasis.constant )
  Xrbf(:,end+1) = 1;
end

% normalize rbfs to sum to 1
if( rbfBasis.normalize )
  Xrbf = bsxfun(@rdivide, Xrbf, sum(Xrbf,2));
end
