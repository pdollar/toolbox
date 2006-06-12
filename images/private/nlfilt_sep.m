% Efficient multidimensional nonlinear but seperable filtering operation.
%
% The concept of a nonlinear seperable filter is not very common, but nevertheless can
% prove very useful since computation time can be reduced greatly.  Consider a funciton
% like max that is applied to a 2 dimensional window.  max could also be applied to each
% row of the window, then to the resulting column, insead of being applied to the entire
% window simultaneously.  This is what is meant here by a seperable nonlinear filter.   
%
% The function fun must be able to take an input of the form
% C=fun(I,radius,param1,...paramk).  The return C must have the same size as I, and each
% element of C must be the result of applying the nlfilt operation to the local column (of
% size 2r+1) of A.  
%
% For example:
%   % COMPUTES LOCAL SUMS:
%   C = nlfilt_sep( I, dims, shape, @rnlfilt_sum );
%
%   % COMPUTES LOCAL MAXES:
%   C = nlfilt_sep( I, dims, shape, @rnlfilt_max ); 
%
% INPUTS
%   I       - matrix to compute fun over
%   dims    - size of volume to compute fun over 
%   shape   - 'valid', 'full', or 'same', see conv2 help
%   fun     - nonlinear filter 
%   params  - optional parameters for nonlinear filter
%
% OUTPUTS
%   I      - resulting image
%
% DATESTAMP
%   26-Jan-2006  2:00pm
%
% See also NLFILTBLOCK_SEP, RNLFILT_SUM, RNLFILT_MAX

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 

function I = nlfilt_sep( I, dims, shape, fun, varargin )
    params = varargin;   nd = ndims(I);  siz = size(I); 
    [dims,er] = checknumericargs( dims, size(siz), 0, 1 ); error(er);
    rs1 = max(0,floor( (dims-1)/2 ));  rs2 = ceil( (dims-1)/2 );

    % pad I to 'full' dimensions, note must pad pre with rs2!
    if(strcmp(shape,'valid') && any(dims>size(I)) ) I=[]; return; end;
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
        I = arraycrop_full( I, rs1+1, size(I)-rs2 );
    elseif(~strcmp(shape,'full') && ~strcmp(shape,'same'))
        error('unknown shape');
    end;
    
    
    
    
    
    
    
