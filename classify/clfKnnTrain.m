function clf = clfKnnTrain( clf, X, Y )
% Train a k nearest neighbor classifier (memorization).
%
% USAGE
%  clf = clfKnnTrain( clf, X, Y )
%
% INPUTS
%  clf     - model to be trained
%  X       - nxp data array
%  Y       - nx1 array of labels
%
% OUTPUTS
%  clf     - a trained k-nearest neighbor classifier.
%
% EXAMPLE
%
% See also CLFKNN, CLFKNNFWD
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( ~strcmp(clf.type,'knn')); error( ['incorrect type: ' clf.type] ); end;
if( size(X,2)~= clf.p ); error( 'Incorrect data dimension' ); end;

%%% error check
n=size(X,1);  Y=double(Y);
[Y,er] = checkNumArgs( Y, [n 1], 0, 0 ); error(er);

%%% training is memorization
clf.Xtrain = X;
clf.Ytrain = Y;
