% Break matrix up into a cell array of same sized matrices.
%
% Useful wrapper for matlab function mat2cell.  Instead of specifying locations along each
% dimension at which to split the matrix, this function takes the number of parts along
% each dimension to break X into.  That is if X is d1xd2x...xdk and parts=[p1 p2 ... pk];
% then X is split into p1*p2*...*pk matricies of dimension d1/p1 x d2/p2 x ... x dk/pk.
% If di/pi is not an integer, floor(di/pi) is used.  Leftover chunks of X are discarded.
% Using a scalar p for parts is equivalent to using [p p ... p].
%
% So for example if X is 10*16, mat2cell2( X, [2 3] ) break X into 2*3 parts, each of size
% 5x5, and the last column of X is discarded.
%
% INPUTS
%   X       - matrix to split
%   parts   - see above
%
% OUTPUTS
%   C       - cell array adjacent submatrices of X
%
% EXAMPLE
%   A=rand(4), B = mat2cell2(A,2), B{:}
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MAT2CELL, CELL2ARRAY, CELL2MAT

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function C = mat2cell2( X, parts )
    siz = size(X); nd = ndims(X);
    [parts,er] = checknumericargs( parts, size(siz), 0, 2 ); error(er);
    
    % crop border areas so as to make dims of X divisible by parts
    parts = min(siz,parts);   siz = siz - mod( siz, parts );
    if (~all( siz==size(X))) X = arraycrop_full( X, ones(1,nd), siz ); end;
    
    % Convert to cell array by calling mat2cell
    for d=1:nd bounds{d} = repmat( siz(d)/parts(d), [1 parts(d)] ); end
    C=mat2cell( X, bounds{:});
