function r = randSample( n, k, isArray )
% Generate values sampled uniformly without replacement from 1:n.
%
% If n is an integer, samples k values from 1:n without replacement. If n
% is an array, samples k values without replacement from n. This function
% implements much of the same functionality as randsample.m in the
% Statistics Toolbox.
%
% USAGE
%  r = randSample( n, k, [isArray] )
%
% INPUTS
%  n           - specifies sampling source (if array) or range (if scalar)
%  k           - the number of samples to draw
%  isArray     - [0] if true treat n as an array (even if has single elt)
%
% OUTPUTS
%  r           - k uniformly generated random samples
%
% EXAMPLE
%  r = randSample( 10, 5 )
%  r = randSample( [ 5 6 8 9 32 45 ], 2 )
%
% See also randperm
%
% Piotr's Image&Video Toolbox      Version 2.50
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 ), isArray=0; end
m=length(n); if(m>1), isArray=1; elseif(isArray==0), m=n; end
if(k>m), error('Too many samples requested.'); end
if(k==1), r=1+floor(m*rand); else r=randperm(m); r=r(1:k); end
if(isArray), r=n(r); end

end
