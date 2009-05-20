function r = randSample( n, k )
% Generate uniformly random samples in a certain range or array
%
% This function simply exists to remove dependencies on the 
% statistical toolbox that contains the similar function
% randsample. It does not implement all of its features though
%
% USAGE
%  r = randomSample( n, k )
%  r = randomSample( array, k )
%
% INPUTS
%  n           - an integer of the random sample must be in the range
%                [ 1 : n ] or an array if the samples have to be picked
%                from an array
%  k           - the number of samples to draw
%
% OUTPUTS - and whatever after the dash
%  r           - uniformly generated random samples
%
% EXAMPLE - and whatever after the dash
%  r = randomSample( 10, 5 );
%  r = randomSample( [ 5 6 8 9 32 45 ], 2 );
%
% See also 
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if length(n)==1
  if k > n;	error('Asking for too many samples'); end
  rp = randperm(n);
  r = rp(1:k);
else
  if k > length(n);	error('Asking for too many samples'); end
  rp = randperm(length(n));
  r = n(rp(1:k));
end
