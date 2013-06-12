function [hs,probs] = fernsClfApply( data, ferns, inds )
% Apply learned fern classifier.
%
% USAGE
%  [hs,probs] = fernsClfApply( data, ferns, [inds] )
%
% INPUTS
%  data     - [NxF] N length F binary feature vectors
%  ferns    - learned fern classification model
%  inds     - [NxM] cached inds (from previous call to fernsInds)
%
% OUTPUTS
%  hs       - [Nx1] predicted output labels
%  probs    - [NxH] predicted output label probabilities
%
% EXAMPLE
%
% See also fernsClfTrain, fernsInds
%
% Piotr's Image&Video Toolbox      Version 2.50
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]
if( nargin<3 || isempty(inds) )
  inds = fernsInds(data,ferns.fids,ferns.thrs); end
[N,M]=size(inds); H=ferns.H; probs=zeros(N,H);
for m=1:M, probs = probs + ferns.pFern(inds(:,m),:,m); end
if(ferns.bayes==0), probs=probs/M; end; [~,hs]=max(probs,[],2);
end
