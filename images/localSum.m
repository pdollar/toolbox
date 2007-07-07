% Fast routine for box filtering.
%
% Same effect as calling 'C=convn( I, ones(dims), shape)', except more
% efficient. Computes local sums by using running sums.
%
% To get sum in non-overlapping windows, use shape='block'. Equivalent to
% doing localSum, and then subsampling (except more efficient).
%
% USAGE
%  I = localSum( I, dims, shape )
%
% INPUTS
%  I       - matrix to compute sum over
%  dims    - size of volume to compute sum over
%  shape   - [optional] 'valid', 'full', 'same',(see conv2 help) or 'block'
%
% OUTPUTS
%  C       - matrix of sums
%
% EXAMPLE - 1
%  A = rand(20); dim=11; shape='valid';
%  B = localSum(A,dim,shape);
%  C = conv2(A,ones(dim),shape);
%  diff=B-C; sum(abs(diff(:)))
%
% EXAMPLE -2
%  load trees; I=ind2gray(X,map);
%  I2 = localSum( I, 11, 'block' );
%  figure(1); im(I); figure(2); im(I2);
%
% See also LOCALSUM_BLOCK

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function I = localSum( I, dims, shape )

if( nargin<3 ); 
  shape='full'; 
else
  if strcmp(shape,'block')
    I = nlfiltblock_sep( I, dims, @rnlfiltblock_sum );
    return
  end
end

I = nlfilt_sep( I, dims, shape, @rnlfilt_sum );
