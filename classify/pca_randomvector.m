% Generate random vectors in PCA subspace.
%
% Used to generate random vectors from the subspace spanned by the first k
% principal components.  The points generated come from the gaussian
% distribution from within the subspace.
%
% Can optionally generate points on the subspace that are also on a
% hypershpere centered on the origin.  This may be useful if the original
% data points were all from a hypershpere -- for example they were
% normalized via imnormalize.  Set the optional hypershpere flag to
% 1 to generate points only on the hypersphere.
%
% INPUTS
%   U           - [returned by pca] -- see pca
%   mu          - [returned by pca] -- see pca
%   variances   - [returned by pca] -- see pca
%   k           - number of principal coordinates to use
%   n           - number of x to generate
%   hypershpere - [optional] generate points on hypersphere (see above)
%   show        - [optional] figure to use for display (no display if == 0)
%
% OUTPUTS
%   Xr          - resulting randomly generated vectors
%
% DATESTAMP
%   29-Nov-2005  2:00pm
%
% See also PCA

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function Xr = pca_randomvector( U, mu, variances, k, n, hypershpere, show )
    %%% Little test - see if eigenvectors induced by randomly generated vectors 
    %%% are the same as the original eigenvectors.  Assumes [U,mu,variances] exist.  
    %   Xr = pca_randomvector( U, mu, variances, 3, 100 );
    %   [ Ur, mur, variancesr ] = pca( Xr );
    %   ind = 3;
    %   Uim = reshape( U(:,ind), [ size(mu,1), size(mu,2) ]  );
    %   Uimr = reshape( Ur(:,ind), [ size(mu,1), size(mu,2) ]  );
    %   if( sum(abs(Uim-Uimr))>sum(abs(Uim+Uimr))) Uimr=Uimr*-1; end; % might be off by a sign
    %   clf; subplot(3,1,1); im( Uim ); subplot(3,1,2); im( Uimr ); 
    %   subplot(3,1,3); im( Uim - Uimr);
    %%%
    if( nargin<6 || isempty(hypershpere) ) hypershpere=0; end;
    if( nargin<7 || isempty(show) ) show=0; end;
    
    siz = size(mu);  
    nd = ndims(mu);  
    sizX = [siz, n];
    d = prod(siz);
    
    % generate random vectors inside of subspace.  
    C = diag( variances(1:k).^-1 );    
    Yr = C * randn(k,n);
    Uk = U(:,1:k);
    Xr = Uk * Yr;

    % use above method to try to generate points in the hyperspace that
    % also lie on a hypersphere.
    if(hypershpere)
        % The final point must lie on the hypershpere.  That is we need to
        % scale each element xr of Xr so that after adding it to mu the
        % resulting vector has length d.  So we need to find k>0 such that
        % (k*xr + mu) has length d.  To find this k we simply solve the
        % quadratic equation induced by ||(k*xr + mu)||=d, choosing the root
        % such that k>0.  Note that the mean of the resulting vector will not
        % necessarily be 0, but the variance will pretty much be 1!
        % Regardless, we restandardize at the end.
        muv = mu(:);  magmu = dot(muv,muv);
        for i=1:n
            xr = Xr(:,i);
            rs = roots( [dot(xr,xr), 2 * dot(xr,muv), magmu-d] );
            Xr(:,i) = muv + max(rs)*xr;
        end

        Xr = reshape( Xr, sizX );
        Xr = feval_arrays( Xr, @imnormalize );
    else
        % simply add the mean to reshaped Xr
        Xr = reshape( Xr, sizX );
        murep = repmat(mu, [ones(1,nd), n ] );
        Xr = Xr + murep;
    end

    % optionaly show resulting vectors
    if (show)
        figure(show); montage2(Xr,1);
    end

