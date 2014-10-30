function IDXpred = clfKnnDist( D, IDX, k )
% k-nearest neighbor classifier based on a distance matrix D.
%
% k==1 is much faster than k>1.  For k>1, ties are broken randomly.
%
% USAGE
%  IDXpred = clfKnnDist( D, IDX, k )
%
% INPUTS
%  D       - MxN array of distances from M-TEST points to N-TRAIN points.
%  IDX     - nTrain length vector of class memberships
%  k       - [1] number of nearest neighbors to use
%
% OUTPUTS
%  IDXpred - length M vector of classes for training data
%
% EXAMPLE
%  % (given D and IDX)
%  for k=1:size(D,2) err(k)=sum(IDX==clfKnnDist(D,IDX,k)); end;
%  figure(1); plot(err)
%
% See also CLFKNN
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<3 || isempty(k) );  k=1;  end

[n nTrain] = size(D);
if( nTrain ~= length(IDX) );
  error('Distance matrix and IDX vector dimensions do not match.'); end

%%% 1NN [fast and easy]
if( k==1 )
  [dis,Dind]=min(D,[],2);
  IDXpred=IDX(Dind);

  %%% kNN
else
  [IDXnames,dis,IDX]=unique(IDX);

  %%% get closests k prototypes [n x k  matrix]
  [D,knnsInds] = sort(D,2);
  knnsInds = knnsInds(:,1:k);
  knns = IDX(knnsInds);
  if( n==1 ); knns = knns'; end

  %%% get cnts of each of the prototypes
  nclasses = max(IDX);
  cnts = zeros(n,nclasses);
  for i=1:nclasses;  cnts(:,i)=sum(knns==i,2);  end
  cnts = cnts + randn(size(cnts))/1000; %break ties randomly
  [ cnts, classes ] = sort(cnts,2,'descend');

  %%% get IDXpred
  IDXpred = IDXnames( classes(:,1) );
end
