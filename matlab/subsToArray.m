% Converts subs/vals image representation to array representation.
%
% imsubs is a 'bag of pixels' image representation which is useful for
% sparse arrays.
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
% See also SUB2IND2

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function I = subsToArray( subs, vals, siz, fillVal )

if( nargin<4 || isempty(fillVal) ); fillVal=0; end

inds = sub2ind2( siz, subs );
I = repmat( fillVal, siz );
I(inds) = vals;
