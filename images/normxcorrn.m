% Normalized n-dimensional cross-correlation.
%
% For 2 dimensional inputs this function is exactly the same as normxcorr2, but also works
% in higher dimensions.   For more information see help on normxcorr2.m.  Also see Forsyth
% & Ponce 11.3.1 (p241).
%
% INPUTS:
%   T           - template to correlate to each window in A, must be smaller than A
%   A           - matrix to correlate T to
%   shape       - [optional] 'valid', 'full', or 'same', see convn_fast help
%
% OUTPUTS
%   C           - correlation matrix
%
% EXAMPLE
%   T = filter_gauss_nD( [21 21], [], [], 0 )*100;  A = rand(100); 
%   C1=normxcorrn(T,A);  C2=normxcorr2(T,A);  C3=xcorr2(A,T);
%   C4=xcorrn(A,T); C4r = rot90( xcorrn(T,A),2 );
%   C5=xeucn(A,T);  C5r = rot90( xeucn(T,A), 2 );
%   show=1;
%   figure(show); show=show+1; im(C1);   title('normxcorrn');
%   figure(show); show=show+1; im(C2);   title('normxcorr2');
%   figure(show); show=show+1; im(C3);   title('xcorr2');
%   figure(show); show=show+1; im(C4);   title('xcorrn');
%   figure(show); show=show+1; im(C4r);  title('xcorrn rev&rot');
%   figure(show); show=show+1; im(-C5);  title('xeucn');
%   figure(show); show=show+1; im(-C5r); title('xeucn rev&rot');
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also NORMXCORRN_FG, XEUCN, XCORRN

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function C =  normxcorrn( T, A, shape )
    if( nargin < 3 || isempty(shape)) shape='full'; end;    
    nd = ndims(T);  n = prod(size(T));
    if( nd~=ndims(A) ) error('T and A must have same number of dimensions'); end;
    %if( any(size(T)>size(A)) ) error('T must be smaller than A.'); end;  
    
    % flip for conv purposes [accelerated for 2D]
    if( nd==2 ) T = rot90( T,2 ); else for d=1:nd T = flipdim(T,d); end; end;
    
    % center T on 0 and normalize magnitued to 1
    TN = T - sum(T(:)) / n;  TN = TN / norm( TN(:) );
    
    % The expression for normxcorr is between a window Aw of A and a template T is:
    %   NormXCorr(Aw,T) = sum(AwN .* TN) / mag( AwN ) / mag( TN );
    % Where AwN=Aw-AwAve  and  TN=T-TAve.  The template T is constant, so we normalize TN
    % so that mag( TN )=1.  Also sum(AwN .* TN) = sum(Aw .* TN), since sum(const*TN )=0.
    % Together This gives us: 
    %   NormXCorr(Aw,T) = sum(Aw .* TN) / mag( AwN )
    % To get mag(AwN) we exploit the fact that: E[(X-EX)^2]= E[X^2]-E[X]^2:
    %   sqrt(sum((Aw-AwAve).^2)) = sqrt(sum( Aw.^2 ) - n*AwAve^2);
    AwAve = localsum( A, size(T), shape ) / n; % average of A in each window
    AwMag = real(sqrt(localsum(A.*A,size(T),shape)-n*(AwAve.*AwAve))); % mag of Aw per win
    C = convn_fast(A,TN,shape) ./ (AwMag+eps);  % NormXCorr in each window
    C( AwMag<.00001 ) = 0; % prevent numerical errors

    
    
    
    
    
