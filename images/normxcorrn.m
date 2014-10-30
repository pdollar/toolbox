function C = normxcorrn( T, A, shape, Tm )
% Normalized n-dimensional cross-correlation.
%
% For 2 dimensional inputs this function is exactly the same as normxcorr2,
% but also works in higher dimensions.   For more information see help on
% normxcorr2.m.  Also see Forsyth & Ponce 11.3.1 (p241).
%
% Also, it can take an additional argument that specifies a figure ground
% mask for the T.  That is Tm must be of the same dimensions as T, with
% each entry being 0 or 1, where zero specifies regions to ignore (the
% ground) and 1 specifies interesting regions (the figure).  Essentially Tm
% specifies regions in T that are interesting and should be taken into
% account when doing normalized cross correlation. This allows for
% templates of arbitrary shape, and not just squares. Note: with a mask,
% this function is approximately 3 times slower because it cannot use the
% trick of precomputing running sums.
%
% USAGE
%  C = normxcorrn( T, A, [shape], [Tm] )
%
% INPUTS
%  T           - template to correlate to each window in A
%  A           - matrix to correlate T to
%  shape       - ['full'] 'valid', 'full', or 'same', see convnFast help
%  Tm          - [] figure/ground mask for the template
%
% OUTPUTS
%  C           - correlation matrix
%
% EXAMPLE
%  T=gaussSmooth(rand(20),2); A=repmat(T,[3 3]);  Tm=ones(size(T));
%  C1=normxcorrn(T,A);  C2=normxcorr2(T,A);  C3=normxcorrn(T,A,[],Tm);
%  figure(1); im(C1);  figure(2); im(C2);  figure(3); im(C3);
%  figure(4); im(abs(C1-C2));  figure(5); im(abs(C2-C3));
%
% See also XEUCN, XCORRN, CONVNFAST
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(shape)); shape='full'; end
if( nargin<4 || isempty(Tm)); Tm=[]; end
nd = ndims(T);  
if(nd~=ndims(A)); error('normxcorrn: T and A must have same ndims'); end;


if(isempty(Tm)) %%% no mask specified
  %if( any(size(T)>size(A)) ) error('T must be smaller than A.'); end;

  % flip for conv purposes
  if(nd==2);  T=rot90(T,2);  else  for d=1:nd; T=flipdim(T,d); end;  end

  % center T on 0 and normalize magnitued to 1
  n = numel(T);
  TN = T - sum(T(:)) / n;  
  TN = TN / norm( TN(:) );

  % Eexpression for normxcorr is between a window Aw of A and T is:
  %  NormXCorr(Aw,T) = sum(AwN .* TN) / mag( AwN ) / mag( TN );
  % Where AwN=Aw-AwAve  and  TN=T-TAve.  The template T is constant, so we
  % normalize TN so that mag( TN )=1.  Also sum(AwN .* TN) = sum(Aw .* TN),
  % since sum(const*TN )=0. Together This gives us:
  %   NormXCorr(Aw,T) = sum(Aw .* TN) / mag( AwN )
  % To get mag(AwN) we exploit the fact that: E[(X-EX)^2]= E[X^2]-E[X]^2:
  %   sqrt(sum((Aw-AwAve).^2)) = sqrt(sum( Aw.^2 ) - n*AwAve^2);
  AwAve = localSum( A, size(T), shape ) / n; % average of A in each window
  AwMag = real(sqrt(localSum(A.*A,size(T),shape)-n*(AwAve.*AwAve)));
  
  % mag of Aw per win
  C = convnFast(A,TN,shape) ./ (AwMag+eps);  % normxcorr in each window
  C( AwMag<.00001 ) = 0;                     % prevent numerical errors

else %%% mask specified

  n = sum(Tm(:));
  if(nd~=ndims(Tm)); error('normxcorrn: T / Tm must have same ndims'); end;
  if(any(size(T)~=size(Tm))); error('T and Tm must have same dims'); end;
  if(~all(Tm==0 | Tm==1)); error('elem of Tm must be either 0 or 1'); end;
  if(n==0); error('Tm must have some nonzero values'); end;

  % center T on 0 and normalize magnitued to 1, excluding ground
  % T= (T-Tav) / ||(T-Tav)||
  T(Tm==0)=0;  T = T - sum(T(:)) / n;
  T(Tm==0)=0;  T = T / norm( T(:) );

  % flip for conv purposes
  if(nd==2); T=rot90(T,2); else for d=1:nd; T=flipdim(T,d); end; end
  if(nd==2); Tm=rot90(Tm,2); else for d=1:nd; Tm=flipdim(Tm,d); end; end

  % get average over each window over A
  Aav = convnFast( A, Tm/n, shape );

  % get magnitude over each window over A "mag(WA-WAav)"
  % We can rewrite the above as "sqrt(SUM(WAi^2)-n*WAav^2)". so:
  Amag = convnFast( A.*A, Tm, shape ) - n * Aav .* Aav;
  Amag = sqrt(Amag);  Amag(Amag<.000001)=1;

  % finally get C.  in each image window, we will now do:
  % "dot(T,(WA-WAav)) / mag(WA-WAav)"
  C = convnFast(A,T,shape) - Aav*sum(T(:));
  C = C ./ Amag;
end
