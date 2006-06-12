% Apply a k-nearest neighbor classifier to X.
%
% INPUTS
%   clf     - trained model
%   X       - nxp data array
% 
% OUTPUTS
%   Y       - nx1 vector of labels predicted according to the clf
%
% DATESTAMP
%   11-Oct-2005  2:45pm
%
% See also CLF_KNN, CLF_KNN_TRAIN

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function Y = clf_knn_fwd( clf, X )
    if( ~strcmp( clf.type, 'knn' ) ) error( ['incorrect type: ' clf.type] ); end;
    if( size(X,2)~= clf.p ) error( 'Incorrect data dimension' ); end;
    
    dist_fn = clf.dist_fn;
    Xtrain = clf.Xtrain; 
    Ytrain = clf.Ytrain;  
    k = clf.k;    
    n = size(X,1);

    % get nearest neighbors for each X point
    D = feval( dist_fn, X, Xtrain );
    Y = clf_knn_dist( D, Ytrain, k );
