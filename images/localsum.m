% Fast routine for box filtering.
%
% Same effect as calling 'C=convn( I, ones(dims), shape)', except more
% efficient. Computes local sums by using running sums.
%
% USAGE
%  I = localsum( I, dims, shape )
%
% INPUTS
%  I       - matrix to compute sum over
%  dims    - size of volume to compute sum over
%  shape   - [optional] 'valid', 'full', or 'same', see conv2 help
%
% OUTPUTS
%  C       - matrix of sums
%
% EXAMPLE
%  A = rand(20); dim=11; shape='valid';
%  B = localsum(A,dim,shape);
%  C = conv2(A,ones(dim),shape);
%  diff=B-C; sum(abs(diff(:)))
%
% See also LOCALSUM_BLOCK

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function I = localsum( I, dims, shape )

if( nargin<3 ); shape='full'; end
I = nlfilt_sep( I, dims, shape, @rnlfilt_sum );
