function Xr = pcaRandVec( U, mu, vars, k, n, hypershpere, show )
% Generate random vectors in PCA subspace.
%
% Used to generate random vectors from the subspace spanned by the first k
% principal components.  The points generated come from the gaussian
% distribution from within the subspace. Can optionally generate points on
% the subspace that are also on a hypershpere centered on the origin.  This
% may be useful if the original data points were all from a hypershpere --
% for example they were normalized via imNormalize.  Set the optional
% hypershpere flag to 1 to generate points only on the hypersphere.
%
% USAGE
%  Xr = pcaRandVec( U, mu, vars, k, n, [hypershpere], [show] )
%
% INPUTS
%  U           - returned by pca.m
%  mu          - returned by pca.m
%  vars        - returned by pca.m
%  k           - number of principal coordinates to use
%  n           - number of points to generate
%  hypershpere - [0] generate points on hypersphere (see above)
%  show        - [1] figure to use for display (no display if == 0)
%
% OUTPUTS
%  Xr          - resulting randomly generated vectors
%
% EXAMPLE
%
% See also PCA IMNORMALIZE
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<6 || isempty(hypershpere) ); hypershpere=0; end
if( nargin<7 || isempty(show) ); show=0; end

siz1 = size(mu);   nd = ndims(mu);
sizX = [siz1, n];  D = prod(siz1);

% generate random vectors inside of subspace.
C = diag( vars(1:k).^-1 );
Yr = C * randn(k,n);
Uk = U(:,1:k);
Xr = Uk * Yr;

if(hypershpere)
  % The final point must lie on hypershpere.  Need to scale each element xr
  % of Xr so that after adding it to mu the resulting vector has length D.
  % So need to find k>0 such that (k*xr + mu) has length D.  To find k
  % simply solve the quadratic equation induced by ||(k*xr + mu)||=D,
  % choosing the root such that k>0.  Note that the mean of resulting
  % vector will not necessarily be 0, but the variance will pretty much be
  % 1! Regardless, renomralize at the end.
  muv = mu(:);  muMag = dot(muv,muv);
  for i=1:n
    xr = Xr(:,i);
    rs = roots( [dot(xr,xr), 2 * dot(xr,muv), muMag-D] );
    Xr(:,i) = muv + max(rs)*xr;
  end
  Xr = reshape( Xr, sizX );
  Xr = fevalArrays( Xr, @imNormalize );
else
  % simply add the mean to reshaped Xr
  Xr = reshape( Xr, sizX );
  muRep = repmat(mu, [ones(1,nd), n ] );
  Xr = Xr + muRep;
end

% optionaly show resulting vectors
if(show && (nd==2 || nd==3)); figure(show); montage2(Xr); end



%%% Little test - see if eigenvectors induced by randomly generated vectors
%%% are the same as the original eigenvectors.  Assumes [U,mu,vars] exist.
%   Xr = pcaRandVec( U, mu, vars, 3, 100 );
%   [ Ur, mur, varsr ] = pca( Xr );
%   ind = 3;
%   Uim = reshape( U(:,ind), [ size(mu,1), size(mu,2) ]  );
%   Uimr = reshape( Ur(:,ind), [ size(mu,1), size(mu,2) ]  );
%   if( sum(abs(Uim-Uimr))>sum(abs(Uim+Uimr))) Uimr=Uimr*-1; end; %sign?
%   clf; subplot(3,1,1); im( Uim ); subplot(3,1,2); im( Uimr );
%   subplot(3,1,3); im( Uim - Uimr);
%%%
