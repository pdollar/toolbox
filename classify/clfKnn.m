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

% Piotr's Image&Video Toolbox      Version 2.0
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function clf = clfKnn( p, k, metric )

if( nargin<3 ); metric = []; end

clf.p = p;
clf.type = 'knn';
clf.k = k;
clf.metric = metric;
clf.funTrain = @clfKnnTrain;
clf.funFwd = @clfKnnFwd;
