% Calculates the sum in non-overlapping blocks of I of size dims.  
%
% Similar to localsum except gets sum in non-overlapping windows. Equivalent to doing
% localsum, and then subsampling (except more efficient).
%
% INPUTS
%   I       - matrix to compute sum over
%   dims    - size of volume to compute sum over 
%
% OUTPUTS
%   I       - resulting array 
%
% DATESTAMP
%   29-Sep-2005  2:00pm
% 
% See also LOCALSUM

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = localsum_block( I, dims )
    I = nlfiltblock_sep( I, dims, @rnlfiltblock_sum );
