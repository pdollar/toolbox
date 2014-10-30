function C = xeucn( A, T, shape )
% n-dimensional euclidean distance between each window in A and template T.
%
% Similar to normxcorrn, except at each point (i,j) calculates the
% euclidean distance between the T and the window in A surrounding the
% point, storing the result in C(i,j).
%
% USAGE
%  C = xeucn( A, T, [shape] )
%
% INPUTS
%  A           - first d-dimensional matrix
%  T           - second d-dimensional matrix
%  shape       - ['full'] 'valid', or 'same' (see convn)
%
% OUTPUTS
%  C           - correlation matrix
%
% EXAMPLE
%  T=gaussSmooth(rand(20),2); A=repmat(T,[3 3]);
%  C1=normxcorrn(T,A);  C2=xcorrn(A,T);  C3=xeucn(A,T);
%  figure(1); im(C1);  figure(2); im(C2);  figure(3); im(-C3);
%
% See also XCORRN, CONVNFAST
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(shape)); shape='full'; end
nd = ndims(T);
if(nd~=ndims(A)); error('xeucn: T and A must have same ndims'); end;

% flip for conv purposes
if(nd==2); T=rot90(T,2); else for d=1:nd; T=flipdim(T,d); end; end

% The expression for euclidean distance can be rewritten as:
%   D(k,l) = sumj( (Akj - Tlj).^2 )
%          = sumj( Akj.^2 ) + sumj( Tlj.^2 ) - 2*sumj(Akj.*Tlj);
% T is constant.  Hence simply need square of A in each window, as
% well as each dot product between A and T.
Amag = localSum( A.*A, size(T), shape );     % sum of squares per window
Tmag = T.^2;  Tmag = sum( Tmag(:) );         % sum of squares of T
C = Amag + Tmag - 2 * convnFast(A,T,shape);  % distance squared
% C( Amag<.01 ) = Tmag;  % prevent numerical errors
C = real(sqrt(real(C)));
