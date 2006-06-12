% Wrapper for pca_apply that allows for application to large X.
%
% Wrapper for pca_apply that splits and processes X in parts, this may be
% useful if processing cannot be done fully in parallel because of memory
% constraints. See pca_apply for usage.
%
% INPUTS
%   same as pca_apply
%
% OUTPUTS
%   same as pca_apply
%
% DATESTAMP
%   29-Nov-2005  2:00pm
%
% See also PCA, PCA_APPLY, PCA_VISUALIZE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [ Yk, Xhat, pixelerror ] = pca_apply_large( X, U, mu, variances, k )
    siz = size(X); nd = ndims(X);  [N,r]  = size(U);
    if (N==prod(siz) && ~(nd==2 && siz(2)==1)) siz=[siz, 1]; nd=nd+1; end;
    inds = {':'}; inds = inds(:,ones(1,nd-1));   
    d= prod(siz(1:end-1));

    % some error checking
    if(isa(X,'uint8')) X = double(X); end;
    if( k>r ) warning('Only r<k principal components available.'); k=r; end;
    if (d~=N) error('incorrect size for X or U'); end;

    % Will run out of memory if X has too many elements.  Hence, run pca_apply on parts of
    % X and recombine.  The stuff below is uninteresting and ugly, all the work is done by
    % pca_apply. 
    maxwidth = ceil( (10^7) / d );  
    if (maxwidth > siz(end))
        if (nargout==1) 
            Yk = pca_apply( X, U, mu, variances, k ); 
        elseif (nargout==2) 
            [Yk, Xhat] = pca_apply( X, U, mu, variances, k );
        else 
            [ Yk, Xhat, avsq, avsq_orig ] = pca_apply( X, U, mu, variances, k ); 
            pixelerror = avsq / avsq_orig; 
        end
    else
        Yk = zeros( k, siz(end) );  Xhat = zeros( siz );  
        avsq = 0; avsq_orig = 0;  lastelt = 0;
        if( nargout==1 ) outargs = cell(1,1); elseif( nargout==2 ) outargs = cell(1,2); 
        else outargs = cell(1,4); end;
        while (lastelt < siz(end))
            firstelt = lastelt + 1;  lastelt = min( firstelt+maxwidth-1, siz(end) );  
            truewidth = (lastelt - firstelt + 1);
            [outargs{:}] = pca_apply( X(inds{:}, firstelt:lastelt), U, mu, variances, k );
            Yk( :, firstelt:lastelt ) = outargs{1}; 
            if(nargout>1) Xhat(inds{:}, firstelt:lastelt ) = outargs{2}; end;
            if(nargout>2) avsq = avsq + outargs{3}; 
                avsq_orig = avsq_orig + outargs{4}; end        
        end
        if( nargout==3) pixelerror = avsq / avsq_orig; end;
    end
    
