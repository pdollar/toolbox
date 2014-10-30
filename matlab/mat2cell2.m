function C = mat2cell2( X, parts )
% Break matrix up into a cell array of same sized matrices.
%
% Useful wrapper for matlab function mat2cell.  Instead of specifying
% locations along each dimension at which to split the matrix, this
% function takes the number of parts along each dimension to break X into.
% That is if X is d1xd2x...xdk and parts=[p1 p2 ... pk]; then X is split
% into p1*p2*...*pk matricies of dimension d1/p1 x d2/p2 x ... x dk/pk. If
% di/pi is not an integer, floor(di/pi) is used.  Leftover chunks of X are
% discarded. Using a scalar p for parts is equivalent to using [p p ... p].
%
% So for example if X is 10*16, mat2cell2( X, [2 3] ) breaks X into 2*3
% parts, each of size 5x5, and the last column of X is discarded.
%
% USAGE
%  C = mat2cell2( X, parts )
%
% INPUTS
%  X       - matrix to split
%  parts   - see above
%
% OUTPUTS
%  C       - cell array adjacent submatrices of X
%
% EXAMPLE
%  A=rand(6,10); B = mat2cell2(A,[3 3]),
%
% See also MAT2CELL, CELL2ARRAY, CELL2MAT
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.02
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

siz = size(X); nd = ndims(X);
if(length(parts)>nd && all(parts(nd+1:end)==1)), parts=parts(1:nd); end
[parts,er] = checkNumArgs( parts, size(siz), 0, 2 ); error(er);

% crop border areas so as to make dims of X divisible by parts
parts = min(siz,parts); siz = siz - mod( siz, parts );
if (~all( siz==size(X))); X = arrayCrop( X, ones(1,nd), siz ); end

% Convert to cell array by calling mat2cell
bounds = cell(1,nd);
for d=1:nd; bounds{d} = repmat( siz(d)/parts(d), [1 parts(d)] ); end
C=mat2cell( X, bounds{:});
