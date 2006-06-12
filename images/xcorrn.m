% n-dimensional cross-correlation.  Generalized version of xcorr2.
%
% For 2 dimensional inputs this function is exactly the same as xcorr2, but also works in
% higher dimensions.   It can also be more efficient because it performs convolution in
% either the spatial or frequency domain.   
%
% The order of parameters is reversed from normxcorrn.  This is to be compatible with the
% matlab functions normxcorr2 anc xcorr2 which take parameters in different orders.
%
% For more information see help on xcorr2.m.
% For example usage see normxcorrn.  
%
% INPUTS
%   A           - first d-dimensional matrix 
%   T           - second d-dimensional matrix 
%   shape       - [optional] 'valid', 'full', or 'same', see convn_fast help
%
% OUTPUTS
%   C           - correlation matrix
%
% DATESTAMP
%   29-Sep-2005  2:00pm
% 
% See also XCORR2, NORMXCORRN, XEUCN

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function C = xcorrn( A, T, shape )
    if( nargin < 3 || isempty(shape)) shape='full'; end;    
    nd = ndims(A);
    if( nd~=ndims(T) ) error('A and T must have same number of dimensions'); end;

    % flip for conv purposes [accelerated for 2D]
    if( nd==2 ) T = rot90( T,2 ); else for d=1:nd T = flipdim(T,d); end; end;
    
    % convolve [in frequency or spatial domain]
    C = convn_fast( A, T, shape );
