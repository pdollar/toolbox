% Converts subs/vals image representation to array representation.
%
% imsubs is a 'bag of pixels' image representation which is useful for sparse arrays.
%
% INPUTS
%   subs    - subscripts of point locations (n x d) 
%   vals    - values at point locations (n x 1)
%   siz     - image size vector (1xd) - must fully contain subs
%   fillval - [optional] value to fill array with at nonspecified locs
%
% OUTPUTS
%   I       - array of size siz
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also IMSUBS_RESIZE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = imsubs2array( subs, vals, siz, fillval )
    if( nargin<4 || isempty(fillval) ) fillval=0; end;
    inds = sub2ind2( siz, subs );
    I = repmat( fillval, siz );
    I(inds) = vals;
