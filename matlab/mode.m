% Returns the mode of a vector.
% 
% INPUTS
%   x   - vector of integers
%
% OUTPUTS   
%   y   - mode
%
% EXAMPLE
%   x = randint2( 1, 10, [1 3] )
%   mode( x )
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function y=mode(x)
    [b,i,j] = unique(x);
    [ mval, ind ] = max(hist(j,length(b)));
    y = b(ind);
