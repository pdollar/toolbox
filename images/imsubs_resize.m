% Resizes subs in subs/vals image representation by resizevals.
%
% imsubs is a 'bag of pixels' image representation which is useful for sparse arrays.
%
% This essentially repleces each sub by sub.*resizevals.  The only subtlety is that in
% images the leftmost sub value is .5, so for example when resizing by a factor of 2, the
% first pixel is replaced by 2 pixels and so location 1 in the original image goes to
% location 1.5 in the second image, NOT 2.  It may be necessary to round the values
% afterward.
%
% INPUTS
%   subs        - subscripts of point locations (n x d) 
%   resizevals  - k element vector of shrinking factors
%
% OUTPUTS
%   subs    - transformed subscripts of point locations (n x d) 
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also IMSUBS2ARRAY 

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function subs = imsubs_resize( subs, resizevals )
    [n d] = size(subs);
    [resizevals,er] = checknumericargs( resizevals, [1 d], -1, 2 ); error(er);

    % transform subs
    resizevals = repmat( resizevals, [n, 1] );
    subs = (subs - .5) .* resizevals +.5;

