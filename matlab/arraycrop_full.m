% Used to crop a rectangular region from an n dimensional array.  
% 
% Guarantees that the resulting array will have dimensions as specified by rect by filling
% in locations with padelement if the locations are outside of the image.
%
% INPUTS
%   I             - n dimensional array to crop window from
%   start_locs    - locations at which to start cropping along each dim
%   end_locs      - locations at which to end cropping along each dim
%   padelement    - [optional] element with which to pad (0 by default)
%
% OUTPUTS
%   I             - cropped array
%
% DATESTAMP
%   29-Sep-2005  2:00pm
% 
% See also PADARRAY

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = arraycrop_full( I, start_locs, end_locs, padelement )
    if( nargin<4 || isempty(padelement)) padelement=0; end;  
    nd = ndims(I);  siz = size(I);   
    [start_locs,er] = checknumericargs( start_locs, size(siz), 0, 0 ); error(er);    
    [end_locs,er]   = checknumericargs( end_locs,   size(siz), 0, 0 ); error(er);    
    if( any(start_locs>end_locs)) error('start_locs must be <= end_locs'); end;
    padelement = feval( class(I), padelement );
    
    % crop a real rect [accelerate implementation if nd==2 or nd==3]
    start_locsr = max(start_locs,1);  end_locsr = min(end_locs, siz);
    if( nd==2 )
        I = I( start_locsr(1):end_locsr(1), start_locsr(2):end_locsr(2) );   
    elseif( nd==3 )
        I = I( start_locsr(1):end_locsr(1), start_locsr(2):end_locsr(2), start_locsr(3):end_locsr(3) );   
    else
        extract = cell( nd, 1 );
        for d=1:nd extract{d} = start_locsr(d):end_locsr(d); end
        I = I( extract{:} );        
    end
    
    % then pad as appropriate (essentially inlined padarray)
    padpre = 1 - min( start_locs, 1 );  
    padpost = max( end_locs, siz ) - siz;
    if (any(padpre~=0) || any(padpost~=0))
        idx = cell(1,nd); size_padded = zeros(1,nd); siz = size(I);
        for d=1:nd
            idx{d} = (1:siz(d)) + padpre(d);
            size_padded(d) = siz(d) + padpre(d) + padpost(d);
        end
        Ib = repmat( padelement, size_padded );
        Ib(idx{:}) = I;  I = Ib;
    end
    
    
%     %%% Alternate method not based on padarray (slower)
%     for d=1:nd
%         if (start_locs(d) <= 0 )
%             dims = size(I);  dims(d) = 1-start_locs(d);
%             A = repmat( padelement, dims ); %;  A = A( ones(dims) );
%             I = cat(d,A,I); 
%         end
%         if (end_locs(d) - siz(d) > 0)
%             dims = size(I);  dims(d) = end_locs(d) - siz(d);
%             A = repmat( padelement, dims ); %
%             I = cat(d,I,A);
%         end
%     end
