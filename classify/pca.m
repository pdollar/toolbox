% principal components analysis (alternative to princomp).
%
% A simple dimensionality reduction technique.  Use this function to create an orthonormal
% basis for the space R^N.  This basis has the property that the coordinates of a vector x
% in R^N are of decreasing importance.  Hence instead of using all N coordinates to
% specify the location of x, using only the first k<N still gives a vector xhat that is
% very close to x with high probability.  
%
% Use this function to retrieve the basis U.  Use pca_apply.m to retrieve that basis
% coefficients for a novel vector x.  Also, use pca_visualize(X,...) for visualization of
% the approximated X. 
%
% This function operates on arrays of arbitrary dimension, by first converting the array
% to a vector.  That is if X is n dimensional, say of dims d1 x d2 x...x dn-1 x dn.  Then
% the first n-1 dimensions of X are comined. That is X is flattened to be 2 dimensional:
% (d1 * d2 * ...* dn-1) x dn.  
%
% Once X is converted to 2 dimensions of size Nxn, each column represents a single 
% observation, and each row is a different variable.  Note that this is the opposite of
% many matlab functions such as princomp.  So if X is MxNxK, then X(:,:,i) representes the
% ith observation.  This is useful if X is a stack of images (each image will
% automatically get vectorized).  Likewise if X is MxNxKxR, then X(:,:,:,i) becomes the
% ith observation, which is useful if X is a collection of videos each of size MxNxK.
%
% If X is very large, it is samlped before running PCA, using randomsample.
%
% To calculate residuals: 
%   residuals = variances / sum(variances); 
%   residuals = cumsum(residuals); plot( residuals, '- .' )
%
% INPUTS
%   X           - n-dim array of size (d1 x d2 x...x dn-1) x dn (treated as dn elements)
%
% OUTPUTS
%   U           - 2D array of size (d1 * d2 * ...* dn-1) x r, where each column represents 
%               - a principal component of X (after X is flattened).
%   mu          - Array of size d1 x d2 x...x dn-1 which represents the mean of X.
%   variances   - sorted eigenvalues corresponding to eigenvectors in U 
%
% EXAMPLE
%   load pca_data;  
%   [ U, mu, variances ] = pca( I3D1(:,:,1:12) );
%   [ Y, Xhat, pe ] = pca_apply( I3D1(:,:,1), U, mu, variances, 5 );
%   figure(1); im(I3D1(:,:,1));  figure(2); im(Xhat);
%   pca_visualize( U, mu, variances, I3D1, 13, [0:12], [], 3 );
%
% DATESTAMP
%   29-Nov-2005  2:00pm
%
% See also PRINCOMP, PCA_APPLY, PCA_VISUALIZE, VISUALIZE_DATA, RANDOMSAMPLE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [ U, mu, variances ] = pca( X )

    %%% THE FOLLOWING IS USED TO TIME SVD
    % t=[]; rs = 100:20:500; 
    % for r=rs tic; [u,s,v] = svd(rand(r)); t(end+1)=toc; end; plot(rs,t);
    % plot(rs,t,'r'); hold('on'); fplot( '10^-6 * .25*(x)^2.75', [1,1000] ); hold('off');
    % x=1500; 10^-7 * 2.5*(x)^2.75 / 60 %minutes
    %%%

    % Will run out of memory if X has too many elements.  
    % Hence, choose a random sample to run PCA on.
    maxmegs = 80; %$P
    if( ~isa(X,'double') )  
        x1=X(1); s=whos('x1'); nbytes=s.bytes;  
        X = randomsample( X, maxmegs * nbytes/8 );
        X = double(X);
    else
        X = randomsample( X, maxmegs );
    end

    siz=size( X );  nd=ndims(X);  d=prod(siz(1:end-1));
    inds={':'};  inds=inds(:,ones(1,nd-1));   
   
    % set X to be zero mean
    mu = mean( X, nd );
    murep = mu( inds{:}, ones(1,siz(end)));
    X = X - murep;

    % flatten X
    X = reshape(X, d, [] );
    [N,n] = size(X);
    if (n==1) U = zeros( d, 1 ); variances = 0; return; end
    X = X ./ sqrt(n-1);

    % get principal components using the SVD 
    %  X = U * S * V'; all else follows
    %  note: maxrank = min( n-1, N )
    if (N>n)
        [V,Ssq,V] = svd( X' * X ); 
        keeplocs = diag(Ssq) > .00000001^2;
        Ssq = Ssq(keeplocs,keeplocs);
        V = V(:,keeplocs);
        U = X * (V * Ssq^-.5);
    else
        [U,Ssq,U] = svd( X * X' );
        keeplocs = diag(Ssq) > .00000001^2;
        Ssq = Ssq(keeplocs,keeplocs);
        U = U(:,keeplocs);
    end    
    
    % eigenvalues squared
    variances = diag(Ssq);
    
