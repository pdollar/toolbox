function Y = clfKnnFwd( clf, X )
% Apply a k-nearest neighbor classifier to X.
%
% USAGE
%  Y = clfKnnFwd( clf, X )
%
% INPUTS
%  clf     - trained model
%  X       - nxp data array
%
% OUTPUTS
%  Y       - nx1 vector of labels predicted according to the clf
%
% EXAMPLE
%
% See also CLFKNN, CLFKNNTRAIN
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( ~strcmp(clf.type,'knn')); error( ['incorrect type: ' clf.type] ); end
if( size(X,2)~= clf.p ); error( 'Incorrect data dimension' ); end

metric = clf.metric;
Xtrain = clf.Xtrain;
Ytrain = clf.Ytrain;
k = clf.k;

% get nearest neighbors for each X point
D = pdist2( X, Xtrain, metric );
Y = clfKnnDist( D, Ytrain, k );
