function I = localSum( I, dims, shape )
% Fast routine for box filtering.
%
% Same effect as calling 'C=convn( I, ones(dims), shape)', except more
% efficient. Computes local sums by using running sums. To get sum in
% non-overlapping windows, use shape='block'. Equivalent to doing localSum,
% and then subsampling (except more efficient).
%
% USAGE
%  I = localSum( I, dims, shape )
%
% INPUTS
%  I       - matrix to compute sum over
%  dims    - size of volume to compute sum over, can be scalar
%  shape   - ['full'] 'valid', 'full', 'same', or 'block'
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
% EXAMPLE - 2
%  load trees; I=ind2gray(X,map);
%  I2 = localSum( I, 5, 'block' );
%  figure(1); im(I); figure(2); im(I2);
%
% See also IMSHRINK
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<3 || isempty(shape));  shape='full'; end;

if( nargin==3 && strcmp(shape,'block') )
  funH = @nlfiltersep_blocksum;
else
  funH = @nlfiltersep_sum;
end;

I = nlfiltersep( I, dims, shape, funH );
