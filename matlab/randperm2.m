% Returns a random permutation of integers.
%
% randperm2(n) is a random permutation of the integers from 1 to n.  For
% example, randperm2(6) might be [2 4 5 6 1 3].  randperm2(n,k) is only
% returns the first k elements of the permuation, so for example
% randperm2(6) might be [2 4]. This is a faster version of randperm.m if
% only need first k<<n elements of the random permutation.  Also uses less
% random bits (only k).  Note that this is an implementation O(k), versus
% the matlab implementation which is O(nlogn), however, in practice it is
% often slower for k=n because it uses a loop.
%
% USAGE
%  p = randperm2( n, k )
%
% INPUTS
%  n   - permute 1:n
%  k   - keep only first k outputs
%
% OUTPUTS
%  p 	- k length vector of permutations
%
% EXAMPLE
%  randperm2(10,5)
%
% See also RANDPERM

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function p = randperm2( n, k )

wid = sprintf('Images:%s:obsoleteFunction',mfilename);
warning(wid,[ '%s is obsolete in Piotr''s toolbox.\n RANDSAMPLE is its '...
  'recommended replacement.'],upper(mfilename));

p = randsample( n, k );

%if (nargin<2); k=n; else k = min(k,n); end

%  p = 1:n;
%  for i=1:k
%    r = i + floor( (n-i+1)*rand );
%    t = p(r);  p(r) = p(i);  p(i) = t;
%  end
%  p = p(1:k);
