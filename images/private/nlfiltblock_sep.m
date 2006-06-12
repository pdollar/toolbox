% Efficient multidimensional nonlinear but seperable filtering operation.
%
% See nlfilt_sep for a basic discussion of the he concept of a nonlinear
% seperable filters.  This is similar, instead applies operations to
% nonoveralpping blocks (versus a sliding window approach in which all
% overlapping blocks are considered).  Also, as opposed to nlfilt_sep, the
% output returned by this function is smaller then the input I.
%
% The function fun must be able to take an input of the form
% C=fun(I,radius,param1,...paramk).  The return C must be the result of
% applying the nlfilt operation to the local column (of size 2r+1) of A.  
%
% For example:
%   % COMPUTES LOCAL BLOCK SUMS (see localsum_block):
%   I = nlfiltblock_sep( I, dims, @rnlfiltblock_sum );
%
% INPUTS
%   I       - matrix to compute fun over
%   dims    - size of volume to compute fun over 
%   fun     - nonlinear filter 
%   params  - optional parameters for nonlinear filter
%
% OUTPUTS
%   I      - resulting image
%
% DATESTAMP
%   29-Sep-2005  2:00pm
% 
% See also NLFILT_SEP, RNLFILTBLOCK_SUM

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = nlfiltblock_sep( I, dims, fun, varargin  )
    nd = ndims(I);  siz = size(I);   
    [dims,er] = checknumericargs( dims, size(siz), 0, 1 ); error(er);
    params = varargin;
    
    % trim I to have integer number of blocks
    dims = min(dims,siz);  siz = siz - mod( siz, dims ); 
    if (~all( siz==size(I))) I = arraycrop_full( I, ones(1,nd), siz ); end;
    
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
    
