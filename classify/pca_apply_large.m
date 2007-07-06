% Wrapper for pca_apply that allows for application to large X.
%
% Wrapper for pca_apply that splits and processes X in parts, this may be
% useful if processing cannot be done fully in parallel because of memory
% constraints. See pca_apply for usage.
%
% USAGE
%  same as pca_apply
%
% INPUTS
%  same as pca_apply
%
% OUTPUTS
%  same as pca_apply
%
% EXAMPLE
%
% See also PCA, PCA_APPLY, PCA_VISUALIZE

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [ Yk, Xhat, avsq ] = pca_apply_large( X, U, mu, vars, k )

siz = size(X); nd = ndims(X);  [N,r]  = size(U);
if(N==prod(siz) && ~(nd==2 && siz(2)==1)); siz=[siz, 1]; nd=nd+1; end
inds = {':'}; inds = inds(:,ones(1,nd-1));
d= prod(siz(1:end-1));

% some error checking
if(d~=N); error('incorrect size for X or U'); end
if(isa(X,'uint8')); X = double(X); end
if( k>r )
  warning(['Only ' int2str(r) '<k comp. available.']); %#ok<WNTAG>
  k=r;
end

% Will run out of memory if X has too many elements.  Hence, run
% pca_apply on parts of X and recombine.
maxwidth = ceil( (10^7) / d );
if(maxwidth > siz(end))
  if (nargout==1)
    Yk = pca_apply( X, U, mu, vars, k );
  elseif (nargout==2)
    [Yk, Xhat] = pca_apply( X, U, mu, vars, k );
  else
    [ Yk, Xhat, avsq ] = pca_apply( X, U, mu, vars, k );
  end
else
  Yk = zeros( k, siz(end) );  Xhat = zeros( siz );
  avsq = 0;  avsqOrig = 0;  last = 0;
  while(last < siz(end))
    first=last+1;  last=min(first+maxwidth-1,siz(end));
    Xi = X(inds{:}, first:last);
    if( nargout==1 )
      Yki = pca_apply( Xi, U, mu, vars, k );
    else
      if( nargout==2 )
        [Yki,Xhati] = pca_apply( Xi, U, mu, vars, k );
      else
        [Yki,Xhati,avsqi,avsqOrigi] = pca_apply( Xi, U, mu, vars, k );
        avsq = avsq + avsqi;  avsqOrig = avsqOrig + avsqOrigi;
      end;
      Xhat(inds{:}, first:last ) = Xhati;
    end
    Yk( :, first:last ) = Yki;
  end;
  if( nargout==3); avsq = avsq / avsqOrig; end
end
