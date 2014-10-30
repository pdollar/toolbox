% Returns the mode of a vector.
%
% Was mode not part of Matlab before?
%
% USAGE
%  y = mode2( x )
%
% INPUTS
%  x   - vector of integers
%
% OUTPUTS
%  y   - mode
%
% EXAMPLE
%  x = randint2( 1, 10, [1 3] )
%  mode(x), mode2( x )
%
% See also MODE

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function y = mode2( x )

wid = sprintf('Images:%s:obsoleteFunction',mfilename);
warning(wid,[ '%s is obsolete in Piotr''s toolbox.\n MODE is its '...
  'recommended replacement.'],upper(mfilename));

y = mode( x );

% [b,i,j] = unique(x);
% [ mval, ind ] = max(hist(j,length(b)));
% y = b(ind);
