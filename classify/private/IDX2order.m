function order = IDX2order( IDX )
% Converts class labels into an ordering.
%
% Creates an ordering order such that IDX(order)=[1 1...1 2...2 ... k...k].
% All points within a class retain the ordering in which they originally
% appeared.  Also, Xb = X(order,:) has cluster labels IDX(order), ie
% adjacent elements in X typically belong to the same cluster.
%
% USAGE
%  order = IDX2order( IDX )
%
% INPUTS
%  IDX     - cluster membership [see kmeans2.m]
%
% OUTPUTS
%  order   - n-by-1 vector containing a new ordering for the points.
%
% EXAMPLE
%  order = IDX2order( [1 1 3 1 2 2] )  % should be: [1 2 4 5 6 3]
%
% See also DISTMATRIXSHOW
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

k = max(IDX);  n = length(IDX);
order = zeros(1,n);  count = 0;
for i=1:k
  locs = (IDX==i); orderi = cumsum(locs);
  order(locs) = orderi(locs) + count;
  count = count+sum(locs);
end
[dis,order] = sort(order);
