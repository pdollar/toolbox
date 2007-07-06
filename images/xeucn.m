% n-dimensional euclidean distance between each window in A and template T
%
% Similar to normxcorrn, except at each point (i,j) calculates the 
% euclidean distance between the T and the window in A surrounding the 
% point, storing the result in C(i,j).
%
% The order of parameters is reversed from normxcorrn.  This is to be 
% compatible with the matlab functions normxcorr2 anc xcorr2 which take 
% parameters in different orders. Also, note that normxcorrn gives a 
% similarity matrix, whereas xeucn gives a dissimilarity (distance) matrix.
%
% USAGE
%  C = xeucn( A, T, [shape] )
%
% INPUTS
%  A           - first d-dimensional matrix
%  T           - second d-dimensional matrix
%  shape       - ['full'] 'valid', 'full', or 'same', see convn_fast help
%
% OUTPUTS
%  C           - correlation matrix
%
% EXAMPLE
%
% See also NORMXCORRN, XCORRN

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function C = xeucn( A, T, shape )

if( nargin < 3 || isempty(shape)); shape='full'; end
nd = ndims(T);
if( nd~=ndims(A) )
  error('T and A must have same number of dimensions')
end

% flip for conv purposes [accelerated for 2D]
if( nd==2 ); T = rot90( T,2 ); else for d=1:nd; T = flipdim(T,d); end; end

% The expression for euclidean distance can be rewritten as:
%   D(k,l) = sumj( (Akj - Tlj).^2 )
%          = sumj( Akj.^2 ) + sumj( Tlj.^2 ) - 2*sumj(Akj.*Tlj);
% T is constant.  Hence simply need square of A in each window, as
% well as each dot product between A and T.
A_mag = localsum( A.*A, size(T), shape ); % sum of squares of A per window
T_mag = T.^2;  T_mag = sum( T_mag(:) );    % constant (sum of squares of T)
C = A_mag + T_mag - 2 * convn_fast(A,T,shape); % Distance squared
% C( A_mag<.01 ) = T_mag;  % prevent numerical errors
C = sqrt(real(C));
