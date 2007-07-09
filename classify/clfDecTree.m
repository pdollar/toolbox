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

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function clf = clfDecTree( p, varargin )

clf.p = p;
clf.type = 'dectree';
clf.params = varargin;

clf.funTrain = @clfDecTreeTrain;
clf.funFwd = @clfDecTreeFwd;
