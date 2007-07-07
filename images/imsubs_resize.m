% Resizes subs in subs/vals image representation by resizVals.
%
% imsubs is a 'bag of pixels' image representation which is useful for
% sparse arrays.
%
% This essentially repleces each sub by sub.*resizVals.  The only subtlety
% is that in images the leftmost sub value is .5, so for example when
% resizing by a factor of 2, the first pixel is replaced by 2 pixels and so
% location 1 in the original image goes to location 1.5 in the second
% image, NOT 2.  It may be necessary to round the values afterward.
%
% USAGE
%  subs = imsubs_resize( subs, resizVals )
%
% INPUTS
%  subs        - subscripts of point locations (n x d)
%  resizVals   - k element vector of shrinking factors
%
% OUTPUTS
%  subs        - transformed subscripts of point locations (n x d)
%
% EXAMPLE
%
% See also IMSUBS2ARRAY

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function subs = imsubs_resize( subs, resizVals )

[n d] = size(subs);
[resizVals,er] = checkNumArgs( resizVals, [1 d], -1, 2 ); error(er);

% transform subs
resizVals = repmat( resizVals, [n, 1] );
subs = (subs - .5) .* resizVals +.5;

