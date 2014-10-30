function inds = fernsInds( data, fids, thrs )
% Compute indices for each input by each fern.
%
% USAGE
%  inds = fernsInds( data, fids, thrs )
%
% INPUTS
%  data     - [NxF] N length F binary feature vectors
%  fids     - [MxS] feature ids for each fern for each depth
%  thrs     - [MxS] threshold corresponding to each fid
%
% OUTPUTS
%  inds     - [NxM] computed indices for each input by each fern
%
% EXAMPLE
%
% See also fernsClfTrain, fernsClfApply
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.50
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

inds = fernsInds1( data, fids, thrs );

%%% OLD MATLAB CODE -- NOW IN MEX
% [M,S]=size(fids); N=size(data,1);
% inds = zeros(N,M,'uint32');
% for n=1:N
%   for m=1:M
%     for s=1:S
%       inds(n,m)=inds(n,m)*2;
%       if( data(n,fids(m,s))<thrs(m,s) )
%         inds(n,m)=inds(n,m)+1;
%       end
%     end
%   end
% end
% inds=inds+1;
% end
