% Wrapper for svm that makes svm compatible with nfoldxval.
%
% Requires the SVM toolbox by Anton Schwaighofer.
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also SVM, NFOLDXVAL

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function net = clf_svm(varargin)
    net = svm( varargin{:} );
    net.fun_train = @svmtrain;
    net.fun_fwd = @svmfwd;
