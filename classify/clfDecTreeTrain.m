function clf = clfDecTreeTrain( clf, X, Y )
% Train a decision tree classifier.
%
% USAGE
%  clf = clfDecTreeTrain( clf, X, Y )
%
% INPUTS
%  clf     - model to be trained
%  X       - nxp data array
%  Y       - nx1 array of labels
%
% OUTPUTS
%  clf     - a trained binary decision tree clf
%
% EXAMPLE
%
% See also CLFDECTREE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if(~strcmp(clf.type,'dectree')); error( ['incor. type: ' clf.type] ); end
if( size(X,2)~= clf.p ); error( 'Incorrect data dimension' ); end

% apply treefit
Y = int2str2( Y ); % convert Y to string format for treefit.
params = clf.params;
T = treefit(X,Y,'method','classification',params{:});

% apply cross validation (on training data), and prune
[c,s,n,best] = treetest(T,'cross',X,Y);
T = treeprune(T,'level',best);

clf.T = T;
