function clf = clfKnn( p, k, metric )
% Create a k nearest neighbor classifier.
%
% USAGE
%  clf = clfKnn( p, k, metric )
%
% INPUTS
%  p       - data dimension
%  k       - number of nearest neighbors to look at
%  metric  - [] distance function, squared euclidean by default
%
% OUTPUTS
%  clf     - model ready to be trained
%
% EXAMPLE
%
% See also NFOLDXVAL, CLFKNNTRAIN, CLFKNNFWD, CLFKNNDIST
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<3 ); metric = []; end

clf.p = p;
clf.type = 'knn';
clf.k = k;
clf.metric = metric;
clf.funTrain = @clfKnnTrain;
clf.funFwd = @clfKnnFwd;
