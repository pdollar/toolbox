function I = nlfiltersep( I, dims, shape, fun, varargin )
% Efficient multidimensional nonlinear but seperable filtering operation.
%
% The concept of a nonlinear seperable filter is not very common, but
% nevertheless can prove useful since computation time can be reduced.
% Consider a funciton like max that is applied to a 2 dim window.  max
% could also be applied to each row of the window, then to the resulting
% column, giving the same result.  This is what is meant here by a
% seperable nonlinear filter.
%
% If shape is 'block', instead applies operations to nonoveralpping blocks
% (versus a sliding window in which all overlapping blocks are considered).
%
% The function fun must be able to take an input of the form
% C=fun(I,radius,param1,...paramk).  The return C must have the same size
% as I, and each element of C must be the result of applying the nlfilt
% operation to the local column (of size 2r+1) of A.
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
%  load trees; I=ind2gray(X,map);
%  Cs = nlfiltersep( I, [11 11], 'same', @nlfiltersep_sum ); % local sums
%  Cm = nlfiltersep( I, [11 11], 'same', @nlfiltersep_max ); % local maxes
%  figure(1); im(I); figure(2); im(Cs); figure(3); im(Cm);
%
% See also NLFILTER
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

params = varargin;   nd = ndims(I);  siz = size(I);
[dims,er] = checkNumArgs( dims, size(siz), 0, 1 ); error(er);

if(strcmp(shape,'block'))

  % trim I to have integer number of blocks
  dims = min(dims,siz);  siz = siz - mod( siz, dims );
  if (~all( siz==size(I))); I = arrayCrop( I, ones(1,nd), siz ); end;

  % Apply rnlfiltblock filter along each dimension of I.  Actually filter
  % is always aplied along first dimension of I and then I is shifted.
  for d=1:nd
    if( dims(d)>1 )
      siz = size(I);  siz(1) = siz(1)/dims(d);
      I = feval( fun, I, dims(d), params{:} );
      I = reshape( I, siz );
    end
    I = shiftdim( I, 1 );
  end

else

  % pad I to 'full' dimensions, note must pad pre with rs2!
  rs1 = max(0,floor( (dims-1)/2 ));  rs2 = ceil( (dims-1)/2 );
  if(strcmp(shape,'valid') && any(dims>size(I)) ); I=[]; return; end;
  if(strcmp(shape,'full'))
    I = padarray(I,rs2,0,'pre');
    I = padarray(I,rs1,0,'post');
  end

  % Apply filter along each dimension of I.  Actually filter
  % is always applied along first dimension of I and then I is shifted.
  for d=1:nd
    if( dims(d)>0 )
      siz = size(I);
      I = feval( fun, I, rs1(d), rs2(d), params{:} );
      I = reshape( I, siz );
    end
    I = shiftdim( I, 1 );
  end

  % crop to appropriate size
  if(strcmp(shape,'valid'))
    I = arrayCrop( I, rs1+1, size(I)-rs2 );
  elseif(~strcmp(shape,'full') && ~strcmp(shape,'same'))
    error('unknown shape');
  end;

end
