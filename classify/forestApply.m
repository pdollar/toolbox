function [hs,ps] = forestApply( data, forest, maxDepth, minCount, best )
% Apply learned forest classifier.
%
% USAGE
%  [hs,ps] = forestApply( data, forest, [maxDepth], [minCount], [best] )
%
% INPUTS
%  data     - [NxF] N length F feature vectors
%  forest   - learned forest classification model
%  maxDepth - [] maximum depth of tree
%  minCount - [] minimum number of data points to allow split
%  best     - [0] if true use single best prediction per tree
%
% OUTPUTS
%  hs       - [Nx1] predicted output labels
%  ps       - [NxH] predicted output label probabilities
%
% EXAMPLE
%
% See also forestTrain
%
% Piotr's Image&Video Toolbox      Version 3.24
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]
if(nargin<3 || isempty(maxDepth)), maxDepth=0; end
if(nargin<4 || isempty(minCount)), minCount=0; end
if(nargin<5 || isempty(best)), best=0; end
assert(isa(data,'single')); M=length(forest);
H=size(forest(1).distr,2); N=size(data,1);
if(best), hs=zeros(N,M); else ps=zeros(N,H); end
discr=iscell(forest(1).hs); if(discr), best=1; hs=cell(N,M); end
for i=1:M, tree=forest(i);
  if(maxDepth>0), tree.child(tree.depth>=maxDepth) = 0; end
  if(minCount>0), tree.child(tree.count<=minCount) = 0; end
  ids = forestInds(data,tree.thrs,tree.fids,tree.child);
  if(best), hs(:,i)=tree.hs(ids); else ps=ps+tree.distr(ids,:); end
end
if(discr), ps=[]; return; end % output is actually {NxM} in this case
if(best), ps=histc(hs',1:H)'; end; [~,hs]=max(ps,[],2); ps=ps/M;
end
