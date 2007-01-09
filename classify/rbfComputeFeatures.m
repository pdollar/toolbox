% Evaluate features of X given a set of radial basis functions.
%
% See rbfComputeBasis for discussion of rbfs and general usage.
%
% USAGE
%  Xrbf = rbfComputeFeatures( X, rbfBasis )
%
% INPUT
%  X         - [N x d] N points of d dimensions each
%  rbfBasis  - rbfBasis struct (see rbfComputeBasis)
%
% OUTPUT
%  Xrbf      - [N x nBasis] computed feature vectors
%
% DATESTAMP
%  09-Jan-2007  1:00pm
%
% See also RBFDEMO, RBFCOMPUTEBASIS

function Xrbf = rbfComputeFeatures( X, rbfBasis )
  N         = size(X,1);
  nBasis    = rbfBasis.nBasis; 
  mu        = rbfBasis.mu';
  variance  = rbfBasis.variance;

  %% for each point, compute values of all basis functions
  %% mu=[nBasis x d]; onesVec=[nBasis x 1]; Xi=[1 x d]; 
  Xrbf = zeros( N, nBasis );
  onesVec = ones(nBasis,1);
  for i=1:N 
    eucdist = sum( ((onesVec*X(i,:) - mu)).^2, 2 );
    Xrbf(i,:) = eucdist' / 2 ./ variance;
  end;
  Xrbf = exp( -Xrbf );

  %% normalize rbfs to sum to 1
  if( 0 ); Xrbf = Xrbf ./ repmat( sum(Xrbf,2), [1 nBasis] ); end;

  %% add constant vector of ones as last feature
  if( 0 ); Xrbf = [Xrbf ones(N,1)]; end;
  
  %% add original features as features
  if( 0 );  Xrbf = [X Xrbf];  end;
  