function hs = binaryTreeApply( X, tree, maxDepth, minWeight )
% Apply learned binary decision tree classifier.
%
% USAGE
%  hs = binaryTreeApply( X, tree, [maxDepth], [minWeight] )
%
% INPUTS
%  X          - [NxF] N length F feature vectors (must be type single)
%  tree       - learned tree classification model
%  maxDepth   - [] maximum depth of tree
%  minWeight  - [] minimum sample weigth to allow split
%
% OUTPUTS
%  hs         - [Nx1] predicted output log ratios
%
% EXAMPLE
%
% See also binaryTreeTrain
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

assert(isa(X,'single'));
if(nargin<3 || isempty(maxDepth)), maxDepth=0; end
if(nargin<4 || isempty(minWeight)), minWeight=0; end
if(maxDepth>0), tree.child(tree.depth>=maxDepth) = 0; end
if(minWeight>0), tree.child(tree.weights<=minWeight) = 0; end
hs = tree.hs(forestInds(X,tree.thrs,tree.fids,tree.child));

end
