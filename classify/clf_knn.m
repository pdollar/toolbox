% Create a k nearest neighbor classifier.
% 
% INPUTS
%   p       - data dimension
%   k       - number of nearest neighbors to look at 
%   dist_fn - [optional] distance function, squared euclidean by default
%
% OUTPUTS
%   clf     - model ready to be trained
%
% DATESTAMP
%   11-Oct-2005  2:45pm
%
% See also NFOLDXVAL, CLF_KNN_TRAIN, CLF_KNN_FWD

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function clf = clf_knn( p, k, dist_fn )
    if( nargin<3 ) dist_fn = @dist_euclidean; end;
        
    clf.p = p;
    clf.type = 'knn';
    clf.k = k;
    clf.dist_fn = dist_fn;    
    clf.fun_train = @clf_knn_train;
    clf.fun_fwd = @clf_knn_fwd;
