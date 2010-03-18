function net = clfSvm(varargin)
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
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

net = svm( varargin{:} );
net.funTrain = @svmtrain;
net.funFwd = @svmfwd;
