function I = subsToArray( subs, vals, siz, fillVal )
% Converts subs/vals image representation to array representation.
%
% Constructs array from subs/vals representation.  Similar to Matlab's
% sparse command, except doesn't actually produce a sparse matrix.  Uses
% different conventions as well.
%
% USAGE
%  I = subsToArray( subs, vals, siz, [fillVal] )
%
% INPUTS
%  subs    - subscripts of point locations (n x d)
%  vals    - values at point locations (n x 1)
%  siz     - image size vector (1xd) - must fully contain subs
%  fillVal - [0] value to fill array with at nonspecified locs
%
% OUTPUTS
%  I       - array of size siz
%
% EXAMPLE
%
% See also SUB2IND2, SPARSE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(fillVal) ); fillVal=0; end

inds = sub2ind2( siz, subs );
I = repmat( fillVal, siz );
I(inds) = vals;
