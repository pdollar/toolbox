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
% Piotr's Computer Vision Matlab Toolbox      Version 2.50
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]
if( nargin<3 || isempty(inds) )
  inds = fernsInds(data,ferns.fids,ferns.thrs); end
[N,M]=size(inds); H=ferns.H; probs=zeros(N,H);
for m=1:M, probs = probs + ferns.pFern(inds(:,m),:,m); end
if(ferns.bayes==0), probs=probs/M; end; [~,hs]=max(probs,[],2);
end
