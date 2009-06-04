function r = randSample( n, k )
% Generate values sampled uniformly without replacement from 1:n.
%
% If n is an integer, samples k values from 1:n without replacement. If n
% is an array, samples k values without replacement from n. This function
% implements much of the same functionality as randsample.m in the
% Statistics Toolbox.
%
% USAGE
%  r = randSample( n, k )
%
% INPUTS
%  n           - specifies sampling source (if array) or range (if scalar)
%  k           - the number of samples to draw
%
% OUTPUTS
%  r           - k uniformly generated random samples
%
% EXAMPLE
%  r = randSample( 10, 5 );
%  r = randSample( [ 5 6 8 9 32 45 ], 2 );
%
% See also RANDPERM
%
% Piotr's Image&Video Toolbox      Version 2.31
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( length(n)==1 )
  if(k>n), error('Too many samples requested.'); end
  rp = randperm(n); r = rp(1:k);
else
  if(k>length(n)), error('Too many samples requested.'); end
  rp = randperm(length(n)); r = n(rp(1:k));
end
