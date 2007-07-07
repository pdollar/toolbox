% Apply a k-nearest neighbor classifier to X.
%
% USAGE
%  Y = clf_knn_fwd( clf, X )
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
% See also CLF_KNN, CLF_KNN_TRAIN

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function Y = clf_knn_fwd( clf, X )

if( ~strcmp(clf.type,'knn')); error( ['incorrect type: ' clf.type] ); end
if( size(X,2)~= clf.p ); error( 'Incorrect data dimension' ); end

metric = clf.metric;
Xtrain = clf.Xtrain;
Ytrain = clf.Ytrain;
k = clf.k;

% get nearest neighbors for each X point
D = pdist2( X, Xtrain, metric );
Y = clf_knn_dist( D, Ytrain, k );
