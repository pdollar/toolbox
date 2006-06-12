% Wrapper for treefit that makes decision trees compatible with nfoldxval.
% 
% INPUTS
%   p       - data dimension
%   params  - parameters for treefit, ex: 'splitmin'',2,'priorprob',ones(1,n)/n
%
% OUTPUTS
%   clf     - model ready to be trained
%
% DATESTAMP
%   11-Oct-2005  2:45pm
%
% See also NFOLDXVAL, TREEFIT

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function clf = clf_dectree( p, varargin )
    clf.p = p;
    clf.type = 'dectree';
    clf.params = varargin;
    
    clf.fun_train = @clf_dectree_train;
    clf.fun_fwd = @clf_dectree_fwd;
