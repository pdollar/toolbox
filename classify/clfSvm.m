% Wrapper for svm that makes svm compatible with nfoldxval.
%
% Requires the SVM toolbox by Anton Schwaighofer.
%
% USAGE
%  net = clfSvm(varargin)
%
% INPUTS
%  see svm in SVM toolbox by Anton Schwaighofer.
%
% OUTPUTS
%  see svm in SVM toolbox by Anton Schwaighofer.
%
% EXAMPLE
%
% See also SVM, NFOLDXVAL

% Piotr's Image&Video Toolbox      Version 2.0
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function net = clfSvm(varargin)

net = svm( varargin{:} );
net.funTrain = @svmtrain;
net.funFwd = @svmfwd;
