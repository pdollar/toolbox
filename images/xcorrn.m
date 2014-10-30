function C = xcorrn( A, T, shape )
% n-dimensional cross-correlation.  Generalized version of xcorr2.
%
% For 2 dimensional inputs this function is exactly the same as xcorr2, but
% also works in higher dimensions. Can also be more efficient because it
% performs convolution using convnFast.  Note that xcorr2 is part of the
% 'Signal Processing Toolbox' and may not be available on all systems.
%
% The order of parameters is reversed from normxcorrn. This is to be
% compatible with the matlab functions normxcorr2 and xcorr2 (which take
% parameters in different orders).
%
% USAGE
%  C = xcorrn( A, T, [shape] )
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
%  C1=xcorr2(A,T); C2=xcorrn(A,T); C3=rot90(xcorrn(T,A),2);
%  figure(1); im(C1);  figure(2); im(C2);  figure(3); im(C3);
%
% See also XCORR2, NORMXCORRN, XEUCN, CONVNFAST
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.12
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(shape)); shape='full'; end
nd = ndims(A);
if(nd~=ndims(A)); error('xcorrn: T and A must have same ndims'); end;

% flip for conv purposes
if(nd==2); T=rot90(T,2); else for d=1:nd; T=flipdim(T,d); end; end

% convolve [in frequency or spatial domain]
C = convnFast( A, T, shape );
