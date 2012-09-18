function [hs,probs] = forestApply( data, forest, maxDepth, minCount )
% Apply learned forest classifier.
%
% USAGE
%  [hs,probs] = forestApply( data, forest, [maxDepth], [minCount] )
%
% INPUTS
%  data     - [NxF] N length F feature vectors
%  forest   - learned forest classification model
%  maxDepth - [] maximum depth of tree
%  minCount - [] minimum number of data points to allow split
%
% OUTPUTS
%  hs       - [Nx1] predicted output labels
%  probs    - [NxH] predicted output label probabilities
%
% EXAMPLE
%
% See also forestTrain
%
% Piotr's Image&Video Toolbox      Version 3.01
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]
if(nargin<3 || isempty(maxDepth)), maxDepth=0; end
if(nargin<4 || isempty(minCount)), minCount=0; end
assert(isa(data,'single')); M=length(forest);
for i=1:M, tree=forest(i);
  if(maxDepth>0), tree.child(tree.depth>=maxDepth) = 0; end
  if(minCount>0), tree.child(tree.count<=minCount) = 0; end
  ids = forestInds(data,tree.thrs,tree.fids,tree.child);
  p=tree.distr(ids,:); if(i==1), probs=p; else probs=probs+p; end
end
[~,hs] = max(probs,[],2);
end
