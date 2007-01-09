% Get locations and sizes of radial basis functions for use in rbf network.  
%
% Radial basis function are a simple, fast method for universal function
% approximation / regression. The idea is to find a mapping X->y where X
% and y are continuous real variables. The mapping is linear over features
% of X: y=rbfWeight*features(X). The features are of the form:
%  f_j(x) = exp(-||x-mu_j||_2^2 / 2 sig_j^2 ).
% The number of basis functions controls the complexity of the network. Too
% many basis functions can lead to overfitting, too few to bad
% interpolation. Rbf networks are trained in two phases.  First, the radial
% basis functions are found in an unsupervised manner (using only Xtrain),
% for example by clustering Xtrain.  Next, given the basis functions,
% Xtrain and ytrain, the basis weights are found by solving the system:
%   rbfWeight * features(Xtrain) = ytrain
% At this point, to interpolate any new points, Xtest, use:
%   ytest = rbfWeight * features(Xtest)
%
% The code below achieves all three steps:
%  rbfBasis  = rbfComputeBasis( Xtrain, nBasis, cluster, scale, show );
%  rbfWeight = rbfComputeFeatures(Xtrain,rbfBasis) \ ytrain;
%  ytest     = rbfComputeFeatures(Xtest,rbfBasis) * rbfWeight;
%
% For an in depth discussion of rbf networks see:
%  Christopher M. Bishop. "Neural Networks for Pattern Recognition"
%
% USAGE
%  rbfBasis = rbfComputeBasis( X, nBasis, [cluster], [scale], [show] )
%
% INPUTS
%  X           - [N x d] N points of d dimensions each
%  nBasis      - number of basis functions to use
%  [cluster]   - [1]: Computes cluster centers for use as rbf functions.
%              - 0: Evenly centered basis functions (for small d)
%  [scale]     - [5] Alter computed value of sigma by given factor
%                set larger for smoother results, too small -> bad interp
%  [show]      - [0] will display results in figure(show)
%                 if negative, assumes X is array Nxs^2 of N sxs patches
%
% OUTPUTS
%  rfbBasis
%   .d        - feature vector size
%   .nBasis   - number of basis functions actually used
%   .mu       - [d x nBasis] rbf centers
%   .variances- [1 x nBasis] rbf widths
%   .variance - rbf average width
%
% DATESTAMP
%  09-Jan-2007  1:00pm
%
% See also RBFDEMO, RBFCOMPUTEFEATURES

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 

function rbfBasis = rbfComputeBasis( X, nBasis, cluster, scale, show )
  if( nargin<2 || isempty(nBasis)); error('nBasis not specified'); end;
  if( nargin<3 || isempty(cluster)); cluster=1;  end;
  if( nargin<4 || isempty(scale)); scale=5;  end;
  if( nargin<5 || isempty(show)); show=0;  end;
  [N d] = size(X);
  
  if( cluster ) 
    %%% CLUSTERS subsample, run kmeans
    maxN=5000; if( N>maxN );  X=X(randperm2(N,maxN),:);  N=maxN;  end;
    params = {'replicates', 5, 'display', 1};
    [IDX,mu] = kmeans2( X, nBasis, params{:} );  
    mu = mu'; nBasis = size(mu,2);
  else
    %%% GRID generate locations evenly spaced on grid  
    if( d>4 ); error('d too high. curse of dimensionality..'); end;
    nBasisPer = round( nBasis ^ (1/d) );
    nBasis = nBasisPer ^ d;
    minX = min(X,[],1 );  maxX = max(X,[],1 );
    stepX = (maxX-minX)/(nBasisPer+1);
    loc=cell(1,d); for i=1:d; loc{i}=(1:nBasisPer)*stepX(i)+minX(i); end;
    grid=cell(1,d); if(d>1); [grid{:}]=ndgrid(loc{:}); else grid=loc; end;
    mu=zeros(d,nBasis);   for i=1:d; mu(i,:) = grid{i}(:); end;
  end;

  %%% Set variance to be equal to average distance of neareast neighbor.
  dist = dist_euclidean( mu', mu' );
  dist = dist + realmax * eye( nBasis );
  variances = min(dist)* scale;
  variance  = mean(variances);
  variances = max( variances, variance/100 );
  
  %%% store results
  rbfBasis.d          = d;
  rbfBasis.nBasis     = nBasis; 
  rbfBasis.mu         = mu;
  rbfBasis.variances  = variances;
  rbfBasis.variance   = variance;
    
  %%% optionally display
  if( abs(show) )
    if( show<0 ) % if images can display
      siz = sqrt(d);
      I = clustermontage( reshape(X,siz,siz,N), IDX, 25, 1 );
      figure(-show); clf; montages( I, {1} );
      figure(-show+1); clf; montage2(reshape(mu,siz,siz,[]),1);
    elseif( d==1 ) % 1D data
      figure(show); clf; hold on;
      minX = min(X,[],1 );  maxX = max(X,[],1 );
      xs = linspace( minX, maxX, 500 )';
      for i=1:nBasis
        ys = exp( -(xs-mu(i)).^2 / 2 / variance  );
        plot( xs, ys );
      end
    elseif( d==2 ) % 2D data      
      figure(show); clf; hold on;
      minX = min(X,[],1 );  maxX = max(X,[],1 );
      xs1 = linspace(minX(1),maxX(1),25); 
      xs2 = linspace(minX(2),maxX(2),25);
      [xs1,xs2] = ndgrid( xs1, xs2 );
      xs = [xs1(:) xs2(:)]; n = size(xs,1);
      for i=1:nBasis
        mui = repmat(mu(:,i),[1 n])';
        ys = exp( - sum( ((xs - mui)).^2, 2 ) / 2 / variance );
        surf( xs1, xs2, reshape(ys,size(xs1)) ); 
      end;
    elseif( d==3 ) % 3D data (show data+centers)
      figure(show); clf; hold on;
      scatter3( X(:,1),X(:,2),X(:,3),12,'filled'); 
      scatter3( mu(1,:),mu(2,:),mu(3,:),30,'filled'); 
    end;    
  end;
  