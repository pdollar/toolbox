function hs = adaBoostApply( X, model )
% Apply learned boosted decision tree classifier.
%
% USAGE
%  hs = adaBoostApply( X, model )
%
% INPUTS
%  X          - [NxF] N length F feature vectors (must be type single)
%  model      - learned boosted tree classifier
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
nWeak=size(model.fids,2); N=size(X,1); hs=zeros(N,1);
for i=1:nWeak
  ids = forestInds(X,model.thrs(:,i),model.fids(:,i),model.child(:,i));
  hs = hs + model.hs(ids,i);
end

end
