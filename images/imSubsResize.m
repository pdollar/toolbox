% Resizes subs by resizVals.
%
% Resizes subs in subs/vals image representation by resizVals.
%
% This essentially replaces each sub by sub.*resizVals.  The only subtlety
% is that in images the leftmost sub value is .5, so for example when
% resizing by a factor of 2, the first pixel is replaced by 2 pixels and so
% location 1 in the original image goes to location 1.5 in the second
% image, NOT 2.  It may be necessary to round the values afterward.
%
% USAGE
%  subs = imSubsResize( subs, resizVals, [zeroPnt] )
%
% INPUTS
%  subs        - subscripts of point locations (n x d)
%  resizVals   - k element vector of shrinking factors
%  zeroPnt     - [.5] See comment above.
%
% OUTPUTS
%  subs        - transformed subscripts of point locations (n x d)
%
% EXAMPLE
%  subs = imSubsResize( [1 1; 2 2], [2 2] )
%
%
% See also IMSUBSTOARRAY

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function subs = imSubsResize( subs, resizVals, zeroPnt )

if( nargin<3 || isempty(zeroPnt) ); zeroPnt=.5;  end

[n d] = size(subs);
[resizVals,er] = checkNumArgs( resizVals, [1 d], -1, 2 ); error(er);

% transform subs
resizVals = repmat( resizVals, [n, 1] );
subs = (subs - zeroPnt) .* resizVals + zeroPnt;
