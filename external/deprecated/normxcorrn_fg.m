% Normalized n-dimensional cross-correlation with a mask.
%
% Similar to normxcorrn, except takes an additional argument that specifies
% a figure ground mask for the T.  That is T_fg must be of the same
% dimensions as T, with each entry being 0 or 1, where zero specifies
% regions to ignore (the ground) and 1 specifies interesting regions (the
% figure).  Essentially T_fg specifies regions in T that are interesting
% and should be taken into account when doing normalized cross correlation.
% This allows for templates of arbitrary shape, and not just squares.
%
% Note: this function is approximately 3 times slower then normxcorr2
% because it cannot use the trick of precomputing sums.
%
% USAGE
%  C = normxcorrn_fg( T, T_fg, A, [shape] )
%
% INPUTS
%  T           - template to correlate to each window in A
%  T_fg        - figure/ground mask for the template
%  A           - matrix to correlate T to
%  shape       - ['full'] 'valid', 'full', or 'same', see convn_fast help
%
% OUTPUTS
%  C           - correlation matrix
%
% EXAMPLE
%  A=rand(50);  B=rand(11);  Bfg=ones(11);
%  C1=normxcorrn_fg(B,Bfg,A);  C2=normxcorr2(B,A);
%  figure(1); im(C1); figure(2); im(C2);
%  figure(3); im(abs(C1-C2));
%
% See also NORMXCORRN

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function C = normxcorrn_fg( T, T_fg, A, shape )
if( nargin <4 || isempty(shape)); shape='full'; end;

if( ndims(T)~=ndims(A) || ndims(T)~=ndims(T_fg) )
  error('TEMPALTE, T_fg, and A must have same number of dimensions'); end;
if( any(size(T)~=size(T_fg)))
  error('TEMPALTE and T_fg must have same dimensions'); end;
if( ~all(T_fg==0 | T_fg==1))
  error('T_fg may have only entries either 0 or 1'); end;
nkeep = sum(T_fg(:));
if( nkeep==0); error('T_fg must have some nonzero values'); end;

% center T on 0 and normalize magnitued to 1, excluding ground
% T= (T-T_av) / ||(T-T_av)||
T(T_fg==0)=0;
T = T - sum(T(:)) / nkeep;
T(T_fg==0)=0;
T = T / norm( T(:) );

% flip for convn_fast purposes
for d=1:ndims(T); T = flipdim(T,d); end;
for d=1:ndims(T_fg); T_fg = flipdim(T_fg,d); end;

% get average over each window over A
A_av = convn_fast( A, T_fg/nkeep, shape );

% get magnitude over each window over A "mag(WA-WAav)"
% We can rewrite the above as "sqrt(SUM(WAi^2)-n*WAav^2)". so:
A_mag = convn_fast( A.*A, T_fg, shape ) - nkeep * A_av .* A_av;
A_mag = sqrt(A_mag);  A_mag(A_mag<.000001)=1; %removes divide by 0 error

% finally get C.  in each image window, we will now do:
% "dot(T,(WA-WAav)) / mag(WA-WAav)"
C = convn_fast(A,T,shape) - A_av*sum(T(:));
C = C ./ A_mag;
