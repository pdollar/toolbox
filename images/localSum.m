function I = localSum( I, dims, shape, op )
% Fast routine for box filtering.
%
% Same effect as calling 'C=convn( I, ones(dims), shape)', except more
% efficient. Computes local sums by using running sums. To get sum in
% non-overlapping windows, use shape='block'. Equivalent to doing localSum,
% and then subsampling (except more efficient). If operation op is set to
% 'max' or 'min', computes local maxes or mins instead of sums.
%
% USAGE
%  I = localSum( I, dims, [shape], [op] )
%
% INPUTS
%  I       - matrix to compute sum over
%  dims    - size of volume to compute sum over, can be scalar
%  shape   - ['full'] 'valid', 'full', 'same', or 'block'
%  op      - ['sum'] 'max', or 'min'
%
% OUTPUTS
%  C       - matrix of sums
%
% EXAMPLE - 1
%  A = rand(500); dim=11; shape='same'; r=20;
%  tic, for i=1:r, B = localSum(A,dim,shape); end; toc
%  tic, for i=1:r, C = conv2(A,ones(dim),shape); end; toc
%  diff=B-C; im(diff), sum(abs(diff(:)))
%
% EXAMPLE - 2
%  load trees; I=ind2gray(X,map); figure(1); im(I);
%  I1=localSum(I,3,'block','sum'); figure(2); im(I1); title('sum')
%  I2=localSum(I,3,'block','max'); figure(3); im(I2); title('max')
%  I3=localSum(I,3,'block','min'); figure(4); im(I3); title('min')
%
% See also IMSHRINK
%
% Piotr's Image&Video Toolbox      Version 2.41
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<3 || isempty(shape));  shape='full'; end
if( nargin<4 || isempty(op)); op='sum'; end

if( nargin>=3 && strcmp(shape,'block') )
  switch op
    case 'sum', fun = @sum;
    case 'max', fun = @(x,d) max(x,[],d);
    case 'min', fun = @(x,d) min(x,[],d);
  end
else
  switch op
    case 'sum', fun = @nlfiltersep_sum;
    case 'max', fun = @nlfiltersep_max;
    case 'min', error('min not implemented');
  end
end

I = nlfiltersep( I, dims, shape, fun );
