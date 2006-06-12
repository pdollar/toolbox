% Pads or crops I appropriately so that size(IC)==dims.  
%
% For each dimension d, if size(I,d) is larger then dims(d) then symmetrically crops along
% d (if cropping amount is odd crops one more unit from the start of the dimension).  If
% size(I,d) is smaller then dims(d) then symmetrically pads along d with padelement (if
% padding amount is even then pads one more unit along the start of the dimension).
%
% INPUTS
%   I             - n dimensional array to crop window from
%                   does not support cell arrays (except for cropping)
%   dims          - dimensions to make I
%   padelement    - [optional] element with which to pad (0 by default)
%
% OUTPUTS
%   IC            - cropped array
%
% EXAMPLE
%   I = randn(10);
%   delta=1; IC = arraycrop2dims( I, size(I)-2*delta  );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also ARRAYCROP_FULL, PADARRAY

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function IC = arraycrop2dims( I, dims, padelement )
    if( nargin<3 || isempty(padelement)) padelement=0; end;      
    nd = ndims(I);  siz = size(I);
    [dims,er] = checknumericargs( dims, size(siz), 0, 1 ); error(er);
    if(any(dims==0)) IC=[]; return; end;

    % get start and end locations for cropping
    start_locs = ones( 1, nd );  end_locs = siz;
    for d=1:nd
        delta = siz(d) - dims(d);
        if ( delta~=0 )
            deltahalf = floor( delta / 2 );  deltarem = delta - 2*deltahalf;
            start_locs(d) = 1 + (deltahalf + deltarem);
            end_locs(d) = siz(d) - deltahalf;
        end
    end

    % call arraycrop_full 
    IC = arraycrop_full( I, start_locs, end_locs, padelement );
    
    
    
    
    
    
    
    
    
    
