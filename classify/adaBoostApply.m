function hs = adaBoostApply( X, model, maxDepth, minWeight )
% Apply learned boosted decision tree classifier.
%
% USAGE
%  hs = adaBoostApply( X, model, [maxDepth], [minWeight] )
%
% INPUTS
%  X          - [NxF] N length F feature vectors (must be type single)
%  model      - learned boosted tree classifier
%  maxDepth   - [] maximum depth of tree
%  minWeight  - [] minimum sample weigth to allow split
%
% OUTPUTS
%  hs         - [Nx1] predicted output log ratios
%
% EXAMPLE
%
% See also adaBoostTrain
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

assert(isa(X,'single'));
if(nargin<3 || isempty(maxDepth)), maxDepth=0; end
if(nargin<4 || isempty(minWeight)), minWeight=0; end
if(maxDepth>0), model.child(model.depth>=maxDepth) = 0; end
if(minWeight>0), model.child(model.weights<=minWeight) = 0; end
nWeak=size(model.fids,2); N=size(X,1); hs=zeros(N,1);
for i=1:nWeak
  ids = forestInds(X,model.thrs(:,i),model.fids(:,i),model.child(:,i));
  hs = hs + model.hs(ids,i);
end

end
