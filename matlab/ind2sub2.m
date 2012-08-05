function sub = ind2sub2( siz, ind )
% Improved version of ind2sub.
%
% Almost the same as ind2sub, except always returns only a single output
% that contains all the index locations.  Also handles multiple linear
% indicies at the same time. See help for ind2sub for more info.
%
% USAGE
%  sub = ind2sub2( siz, ind )
%
% INPUTS
%  siz     - size of array into which ind is an index
%  ind     - linear index (or vector of indicies) into given array
%
% OUTPUTS
%  sub     - sub(i,:) is the ith set of subscripts into the array.
%
% EXAMPLE
%  sub = ind2sub2( [10,10], 20 )         % 10 2
%  sub = ind2sub2( [10,10], [20 19] )    % 10 2; 9 2
%
% See also IND2SUB, SUB2IND2
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( any(ind>prod(siz)) ); error('index out of range'); end

% taken almost directly from ind2sub.m
ind = ind(:);
nd = length(siz);
k = [1 cumprod(siz(1:end-1))];
ind = ind - 1;
sub = zeros(length(ind),nd);
for i = nd:-1:1
  sub(:,i) = floor(ind/k(i))+1;
  ind = rem(ind,k(i));
end
