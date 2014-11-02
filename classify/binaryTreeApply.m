function hs = binaryTreeApply( X, tree, maxDepth, minWeight, nThreads )
% Apply learned binary decision tree classifier.
%
% USAGE
%  hs = binaryTreeApply( X, tree, [maxDepth], [minWeight], [nThreads] )
%
% INPUTS
%  X          - [NxF] N length F feature vectors
%  tree       - learned tree classification model
%  maxDepth   - [] maximum depth of tree
%  minWeight  - [] minimum sample weigth to allow split
%  nThreads   - [16] max number of computational threads to use
%
% OUTPUTS
%  hs         - [Nx1] predicted output log ratios
%
% EXAMPLE
%
% See also binaryTreeTrain
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<3 || isempty(maxDepth)), maxDepth=0; end
if(nargin<4 || isempty(minWeight)), minWeight=0; end
if(nargin<5 || isempty(nThreads)), nThreads=16; end
if(maxDepth>0), tree.child(tree.depth>=maxDepth) = 0; end
if(minWeight>0), tree.child(tree.weights<=minWeight) = 0; end
hs = tree.hs(forestInds(X,tree.thrs,tree.fids,tree.child,nThreads));

end
