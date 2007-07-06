% Calculates the sum in non-overlapping blocks of I of size dims.
%
% Similar to localsum except gets sum in non-overlapping windows.
% Equivalent to doing localsum, and then subsampling (except more
% efficient).
%
% USAGE
%  I = localsum_block( I, dims )
%
% INPUTS
%  I       - matrix to compute sum over
%  dims    - size of volume to compute sum over
%
% OUTPUTS
%  I       - resulting array
%
% EXAMPLE
%  load trees; I=ind2gray(X,map);
%  I2 = localsum_block( I, 11 );
%  figure(1); im(I); figure(2); im(I2);
%
% See also LOCALSUM

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function I = localsum_block( I, dims )

I = nlfiltblock_sep( I, dims, @rnlfiltblock_sum );
