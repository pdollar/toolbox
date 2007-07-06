% Fast version of kmeans clustering.
%
% Cluster the N x p matrix X into k clusters using the kmeans algorithm. It
% returns the cluster memberships for each data point in the N x 1 vector
% IDX and the K x p matrix of cluster means in C.
%
% This function is in some ways it is less general then Matlab's kmeans.m
% (for example only uses euclidian distance), but it has some options that
% the Matlab version does not (for example, it has a notion of outliers and
% min-cluster size).  It is also many times faster than matlab's kmeans.
% General kmeans help can be found in help for the matlab implementation of
% kmeans. Note that the although the names and conventions for this
% algorithm are taken from Matlab's implementation, there are slight
% alterations (for example, IDX==-1 is used to indicate outliers).
%
% IDX is a n-by-1 vector used to indicated cluster membership.  Let X be a
% set of n points.  Then the ID of X - or IDX is a column vector of length
% n, where each element is an integer indicating the cluster membership of
% the corresponding element in X.  IDX(i)=c indicates that the ith point in
% X belongs to cluster c. Cluster labels range from 1 to k, and thus
% k=max(IDX) is typically the number of clusters IDX divides X into. The
% cluster label "-1" is reserved for outliers. IDX(i)==-1 indicates that
% the given point does not belong to any of the discovered clusters. Note
% that matlab's version of kmeans does not have outliers.
%
% USAGE
%  [ IDX, C, sumd ] = kmeans2( X, k, 'key1', val1, 'key2', val2, ... )
%
% INPUTS
%  X       - [n x p] matrix of n p-dim vectors.
%  k       - maximum nuber of clusters (actual number may be smaller)
%  varargin- for ('key', val) pairs
%   'replicates'  - Number of random restarts.
%   'maxiter'     - Maximum number of iterations. Default is 100.
%   'display'     - Whether or not to display algorithm status (default==0)
%   'randstate'   - random seed for kmeans.  Useful for replicability.
%   'outlierfrac' - maximum frac of points that can be treated as outliers
%   'minCsize'    - minimum cluster size (smaller clusters get eliminated)
%
% OUTPUTS
%  IDX    - [n x 1] cluster membership (see above)
%  C      - [k x p] matrix of centroid locations C(j,:) = mean(X(IDX==j,:))
%  sumd   - [1 x k] sumd(j) is sum of distances from X(IDX==j,:) to C(j,:)
%           sum(sumd) is a typical measure of the quality of a clustering
%
% EXAMPLE
%
% See also DEMOCLUSTER

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [ IDX, C, sumd ] = kmeans2( X, k, varargin )

%%% get input args   (NOT SUPPORTED:  distance, emptyaction, start )
pnames = {'replicates' 'maxiter' 'display' 'randstate' };
dflts =  {      1        100         0           []    };
pnames = { pnames{:} 'outlierfrac' 'minCsize'};
dflts =  { dflts{:}       0             1    };
[errmsg,nTrial,maxIter,display,rndSeed,outFrac,minCsize] = ...
  getargs(pnames, dflts, varargin{:});
error(errmsg);
if(k<1); error('k must be greater than 1'); end
if(ndims(X)~=2 || any(size(X)==0)); error('Illegal X'); end
if(outFrac<0 || outFrac>=1)
  error('fraction of outliers must be between 0 and 1'); end
nOutl = floor( size(X,1)*outFrac );

% initialize random seed if specified
if( ~isempty(rndSeed)); rand('state',rndSeed); end;

% run kmeans2_main nTrial times
msg = ['Running kmeans2 with k=' num2str(k)];
if( nTrial>1); msg=[msg ', ' num2str(nTrial) ' times.']; end
if( display); disp(msg); end

bstSumd = inf;
for i=1:nTrial
  tic
  msg = ['kmeans iteration ' num2str(i) ' of ' num2str(nTrial) ', step: '];
  if( display); disp(msg); end
  [IDX,C,sumd,nIter] = kmeans2_main(X,k,nOutl,minCsize,maxIter,display);
  if( sum(sumd)<sum(bstSumd)); bstIDX=IDX; bstC=C; bstSumd=sumd; end
  msg = ['\nCompleted iter ' num2str(i) ' of ' num2str(nTrial) '; ' ...
    'num steps= ' num2str(nIter) ';  sumd=' num2str(sum(sumd)) '\n'];
  if( display && nTrial>1 ); fprintf(msg); toc, end
end

IDX = bstIDX; C = bstC; sumd = bstSumd; k = max(IDX);
msg = ['Final num clusters = ' num2str( k ) ';  sumd=' num2str(sum(sumd))];
if(display); if(nTrial==1); fprintf('\n'); end; disp(msg); end

% sort IDX to have biggest clusters have lower indicies
cnts = zeros(1,k); for i=1:k; cnts(i) = sum( IDX==i ); end
[ids,order] = sort( -cnts );  C = C(order,:);  sumd = sumd(order);
IDX2 = IDX;  for i=1:k; IDX2(IDX==order(i))=i; end; IDX = IDX2;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ IDX, C, sumd, nIter ] = kmeans2_main( X, k, nOutl, ...
  minCsize, maxIter, display )

% initialize cluster centers to be k random X points
[N p] = size(X);
IDX = ones(N,1); oldIDX = zeros(N,1);
index = randsample(N,k);  C = X(index,:);

% MAIN LOOP: loop until the cluster assigments do not change
nIter = 0;  ndisdigits = ceil( log10(maxIter-1) );
if( display ); fprintf( ['\b' repmat( '0',[1,ndisdigits] )] ); end
while( sum(abs(oldIDX - IDX)) ~= 0 && nIter < maxIter)

  % assign each point to closest cluster center
  oldIDX = IDX;  D = dist_euclidean( X, C ); [mind IDX] = min(D,[],2);

  % do not use most distant nOutl elements in computation of  centers
  mindsort = sort(mind); thr = mindsort(end-nOutl);  IDX(mind > thr) = -1;

  % discard small clusters [add to outliers, will get included next iter]
  i=1; while(i<=k); if(sum(IDX==i)<minCsize); IDX(IDX==i)=-1;
      if(i<k); IDX(IDX==k)=i; end; k=k-1; else i=i+1; end; end
  if( k==0 ); IDX( randint2( 1,1, [1,N] ) ) = 1; k=1; end;
  for i=1:k;
    if((sum(IDX==i))==0); error('internal error - empty cluster'); end
  end;

  % Recalculate means based on new assignment (faster than looping over k)
  C = zeros(k,p);  cnts = zeros(k,1);
  for i=find(IDX>0)'
    IDx = IDX(i); cnts(IDx)=cnts(IDx)+1;
    C(IDx,:) = C(IDx,:)+X(i,:);
  end
  C = C ./ cnts(:,ones(1,p));

  nIter = nIter+1;
  if( display )
    fprintf( [repmat('\b',[1 ndisdigits]) int2str2(nIter,ndisdigits)] );
  end;
end

% record within-cluster sums of point-to-centroid distances
sumd = zeros(1,k); for i=1:k;  sumd(i) = sum( mind(IDX==i) ); end
