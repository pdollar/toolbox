% Converts a cell array into a regular array. 
%
% Each element of X must be a regular array, and must have the same number of dimensions
% k.  Converts X to an array Y of dimension k+1 where Y(:,:...,:,i) is X{i} padded to be
% as big as the biggest element in X (along each dimension).   
%
% Specifically, let di1..dik be the k dimensions of element X{i}.  Let dj=max(dij) for
% each j.  Then each element of X{i} is padded to have size [d1 ... dk], and then the
% elements of X are stacked into a vector.
%
% Treats the cell array X as a vector (so ignores the layout of X).
%
% INPUTS
%   X               - cell array where each element is a regular array with dimension k
%   padelement      - [optional] element with which to pad (0 by default)
%
% OUTPUTS
%   Y   - resulting array of dimension k+1
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MAT2CELL2

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function Y = cell2array( X, padelement )
    if(~iscell(X)); error('X must be a cell array'); end;
    if(iscell(X{1})); error('X must contain regular arrays'); end;
    n = numel(X);  nd = ndims(X{1}); 
    for i=2:n if(ndims(X{i})~=nd) error('all elements of X must have same dims'); end; end;
    if(nargin<2) padelement=0; end;
    
    %%% get maximum and minimum size of any element of X
    maxsiz = size(X{1}); minsiz = size(X{1});
    for i=1:n 
        siz = size(X{i});
        maxsiz = max( maxsiz, siz );
        minsiz = min( minsiz, siz );
    end

    %%% construct Y
    for d=1:nd inds{d} = 1:maxsiz(d); end;
    Y = X{i}(1);  Y = repmat( Y, ( [ maxsiz, n ] ) );
    if( all(maxsiz==minsiz) )
        for i=1:n Y( inds{:}, i ) = X{i}; end;
    else
        for i=1:n Y( inds{:}, i ) = arraycrop2dims( X{i}, maxsiz, padelement); end;
    end
