% Wrapper for treefit that makes decision trees compatible with nfoldxval.
%
% USAGE
%  clf = clfDecTree( p, varargin )
%
% INPUTS
%  p       - data dimension
%  varargin- params for treefit, ex: 'splitmin'',2,'priorprob',ones(1,n)/n
%
% OUTPUTS
%  clf     - model ready to be trained
%
% EXAMPLE
%
% See also NFOLDXVAL, TREEFIT, CLFDECTREEFWD, CLFDECTREETRAIN

% Piotr's Image&Video Toolbox      Version 2.0
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

function clf = clfDecTree( p, varargin )

clf.p = p;
clf.type = 'dectree';
clf.params = varargin;

clf.funTrain = @clfDecTreeTrain;
clf.funFwd = @clfDecTreeFwd;
