% Normalized n-dimensional cross-correlation.
%
% For 2 dimensional inputs this function is exactly the same as normxcorr2,
% but also works in higher dimensions.   For more information see help on
% normxcorr2.m.  Also see Forsyth & Ponce 11.3.1 (p241).
%
% Also, it can take an additional argument that specifies
% a figure ground mask for the T.  That is T_fg must be of the same
% dimensions as T, with each entry being 0 or 1, where zero specifies
% regions to ignore (the ground) and 1 specifies interesting regions (the
% figure).  Essentially T_fg specifies regions in T that are interesting
% and should be taken into account when doing normalized cross correlation.
% This allows for templates of arbitrary shape, and not just squares.
% Note: with a mask, this function is Note: this function is approximately
% 3 times slower then normxcorr2 because it cannot use the trick of
% precomputing sums.recomputing sums.
%
% USAGE
%  C = normxcorrn( T, A, [shape] )
%  C = normxcorrn( T, T_fg, A, [shape] )
%
% INPUTS - 1 - without a mask
%  T           - template to correlate to each window in A
%  A           - matrix to correlate T to
%  shape       - ['full'] 'valid', 'full', or 'same', see convn_fast help
%
% INPUTS - 2 - with a mask
%  T           - template to correlate to each window in A
%  T_fg        - figure/ground mask for the template
%  A           - matrix to correlate T to
%  shape       - ['full'] 'valid', 'full', or 'same', see convn_fast help
%
% OUTPUTS
%  C           - correlation matrix
%
% EXAMPLE - 1 - without a mask
%  T = filterGauss( [21 21], [], [], 0 )*100;  A = rand(100);
%  C1=normxcorrn(T,A);  C2=normxcorr2(T,A);  C3=xcorr2(A,T);
%  C4=xcorrn(A,T); C4r = rot90( xcorrn(T,A),2 );
%  C5=xeucn(A,T);  C5r = rot90( xeucn(T,A), 2 );
%  show=1;
%  figure(show); show=show+1; im(C1);   title('normxcorrn');
%  figure(show); show=show+1; im(C2);   title('normxcorr2');
%  figure(show); show=show+1; im(C3);   title('xcorr2');
%  figure(show); show=show+1; im(C4);   title('xcorrn');
%  figure(show); show=show+1; im(C4r);  title('xcorrn rev&rot');
%  figure(show); show=show+1; im(-C5);  title('xeucn');
%  figure(show); show=show+1; im(-C5r); title('xeucn rev&rot');
%
% EXAMPLE - 2 - with a mask
%  A=rand(50);  B=rand(11);  Bfg=ones(11);
%  C1=normxcorrn_fg(B,Bfg,A);  C2=normxcorr2(B,A);
%  figure(1); im(C1); figure(2); im(C2);
%  figure(3); im(abs(C1-C2));
%
% See also NORMXCORRN_FG, XEUCN, XCORRN

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function C = normxcorrn( varargin)

T=varargin{1};

if (nargin==2) || (nargin==3 && ischar(varargin{3}))
  A=varargin{2}; 
  if( nargin < 3 || isempty(varargin{3}))
    shape='full'; 
  else
    shape=varargin{3};
  end
  nd = ndims(T);  n = numel(T);
  if( nd~=ndims(A) );
    error('T and A must have same number of dimensions');
  end
  %if( any(size(T)>size(A)) ) error('T must be smaller than A.'); end;

  % flip for conv purposes [accelerated for 2D]
  if( nd==2 ); T = rot90( T,2 ); else for d=1:nd; T = flipdim(T,d); end; end

  % center T on 0 and normalize magnitued to 1
  TN = T - sum(T(:)) / n;  TN = TN / norm( TN(:) );

  % The expression for normxcorr is between a window Aw of A and a template T
  % is:
  %   NormXCorr(Aw,T) = sum(AwN .* TN) / mag( AwN ) / mag( TN );
  % Where AwN=Aw-AwAve  and  TN=T-TAve.  The template T is constant, so we
  % normalize TN so that mag( TN )=1.  Also sum(AwN .* TN) = sum(Aw .* TN),
  % since sum(const*TN )=0. Together This gives us:
  %   NormXCorr(Aw,T) = sum(Aw .* TN) / mag( AwN )
  % To get mag(AwN) we exploit the fact that: E[(X-EX)^2]= E[X^2]-E[X]^2:
  %   sqrt(sum((Aw-AwAve).^2)) = sqrt(sum( Aw.^2 ) - n*AwAve^2);
  AwAve = localSum( A, size(T), shape ) / n; % average of A in each window
  AwMag = real(sqrt(localSum(A.*A,size(T),shape)-n*(AwAve.*AwAve)));
  % mag of Aw per win
  C = convn_fast(A,TN,shape) ./ (AwMag+eps);  % NormXCorr in each window
  C( AwMag<.00001 ) = 0; % prevent numerical errors
else % mask case %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  T_fg=varargin{2}; A=varargin{3}; shape=varargin{4};

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
end
