function I = nlfiltersep( I, dims, shape, fun, varargin )
% Efficient multidimensional nonlinear but seperable filtering operation.
%
% The concept of a nonlinear seperable filter is less common, but can prove
% useful since computation time can be reduced. Consider a funciton like
% max that is applied to a 2 dim window. max could be applied to each row
% of the window, then to the resulting column, giving the same result. This
% is what is meant here by a seperable nonlinear filter. It is also useful
% to model convolution with an all ones mask as a nonlinear filter as it
% allows for a very efficient implementation.
%
% If shape is not 'block', the function fun must be able to take an input
% of the form C=fun(I,radius,prm1,...,prmk). The return C must have the
% same size as I, and each element of C must be the result of applying the
% nlfilt operation to the local column (of size 2r+1) of A.
%
% If shape is 'block', nlfiltersep applies operations to nonoveralpping
% blocks (versus a sliding window in which all overlapping blocks are
% considered). In this case the function fun must be able to take an input
% of the form C=fun(I,dim,prm1,...,prmk) and apply the operation along
% given dimension, collapsing dim to size 1 (see example below).
%
% USAGE
%  I = nlfiltersep( I, dims, shape, fun, varargin )
%
% INPUTS
%  I       - matrix to compute fun over
%  dims    - size of volume to compute fun over, can be scalar
%  shape   - 'valid', 'full', 'same' or 'block'
%  fun     - nonlinear filter
%  params  - optional parameters for nonlinear filter
%
% OUTPUTS
%  I      - resulting image
%
% EXAMPLE
%  I=double(rgb2gray(imread('peppers.png')))/255;
%  Cs = nlfiltersep(I,[11 11],'same',@nlfiltersep_sum); % local sums
%  Cm = nlfiltersep(I,[11 11],'same',@nlfiltersep_max); % local maxes
%  figure(1); im(I); figure(2); im(Cs); figure(3); im(Cm);
%
% EXAMPLE 2
%  I=double(rgb2gray(imread('peppers.png')))/255;
%  Cs = nlfiltersep(I,[3 3],'block',@sum ); % block sums
%  Cm = nlfiltersep(I,[3 3],'block',@(x,d) max(x,[],d) ); % block maxes
%  figure(1); im(I); figure(2); im(Cs); figure(3); im(Cm);
%
% See also NLFILTER, LOCALSUM
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.53
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

params=varargin; nd=ndims(I); siz=size(I);
[dims,er]=checkNumArgs(dims,size(siz),0,1); error(er);
assert(any(strcmp(shape,{'same','valid','full','block'})));

if(strcmp(shape,'block'))
  % trim I to have integer number of blocks
  dims=min(dims,siz); siz=siz-mod(siz,dims);
  if(~all(siz==size(I))); I=arrayCrop(I,ones(1,nd),siz); end
  
  % Apply filter along each dimension of I
  siz=[dims; siz./dims]; siz=siz(:)'; I=reshape(I,siz);
  for d=0:nd-1, I=feval(fun,I,1+d*2,params{:}); end
  I=permute(I,[2:2:nd*2 1:2:nd*2]);
  
else
  % pad I to 'full' dimensions, note must pad pre with rs2!
  rs1=max(0,floor((dims-1)/2)); rs2=ceil((dims-1)/2);
  if(strcmp(shape,'valid') && any(dims>size(I))); I=[]; return; end
  if(strcmp(shape,'full'))
    I = padarray(I,rs2,0,'pre');
    I = padarray(I,rs1,0,'post');
  end
  
  % Apply filter along first dimension of I then shift dimensions
  for d=1:nd
    if( dims(d)>0 ), siz=size(I);
      I = reshape(feval(fun,I,rs1(d),rs2(d),params{:}),siz);
    end
    I = shiftdim( I, 1 );
  end
  
  % crop to appropriate size
  if(strcmp(shape,'valid')), I=arrayCrop(I,rs1+1,size(I)-rs2); end
end
