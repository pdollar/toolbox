function clf = clfDecTree( p, varargin )
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
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

clf.p = p;
clf.type = 'dectree';
clf.params = varargin;

clf.funTrain = @clfDecTreeTrain;
clf.funFwd = @clfDecTreeFwd;
