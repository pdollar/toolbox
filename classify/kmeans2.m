function [ IDX, C, d ] = kmeans2( X, k, varargin )
% Fast version of kmeans clustering.
%
% Cluster the N x p matrix X into k clusters using the kmeans algorithm. It
% returns the cluster memberships for each data point in the N x 1 vector
% IDX and the K x p matrix of cluster means in C.
%
% This function is in some ways less general than Matlab's kmeans.m (for
% example it only uses euclidian distance), but it has some options that
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
%  [ IDX, C, d ] = kmeans2( X, k, [varargin] )
%
% INPUTS
%  X       - [n x p] matrix of n p-dim vectors.
%  k       - maximum nuber of clusters (actual number may be smaller)
%  prm     - additional params (struct or name/value pairs)
%   .k         - [] alternate way of specifying k (if not given above)
%   .nTrial    - [1] number random restarts
%   .maxIter   - [100] max number of iterations
%   .display   - [0] Whether or not to display algorithm status
%   .rndSeed   - [] random seed for kmeans; useful for replicability
%   .outFrac   - [0] max frac points that can be treated as outliers
%   .minCl     - [1] min cluster size (smaller clusters get eliminated)
%   .metric    - [] metric for pdist2
%   .C0        - [] initial cluster centers for first trial
%
% OUTPUTS
%  IDX    - [n x 1] cluster membership (see above)
%  C      - [k x p] matrix of centroid locations C(j,:) = mean(X(IDX==j,:))
%  d      - [1 x k] d(j) is sum of distances from X(IDX==j,:) to C(j,:)
%           sum(d) is a typical measure of the quality of a clustering
%
% EXAMPLE
%
% See also DEMOCLUSTER
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.24
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get input args
dfs = {'nTrial',1, 'maxIter',100, 'display',0, 'rndSeed',[],...
  'outFrac',0, 'minCl',1, 'metric',[], 'C0',[],'k',k };
[nTrial,maxt,dsp,rndSeed,outFrac,minCl,metric,C0,k] = ...
  getPrmDflt(varargin,dfs); assert(~isempty(k) && k>0);

% error checking
if(k<1); error('k must be greater than 1'); end
if(~ismatrix(X) || any(size(X)==0)); error('Illegal X'); end
if(outFrac<0 || outFrac>=1), error('outFrac must be in [0,1)'); end
nOut = floor( size(X,1)*outFrac );

% initialize random seed if specified
if(~isempty(rndSeed)); rand('state',rndSeed); end; %#ok<RAND>

% run kmeans2main nTrial times
bd=inf; t0=clock;
for i=1:nTrial, t1=clock; if(i>1), C0=[]; end
  if(dsp), fprintf('kmeans2 iter %i/%i step: ',i,nTrial); end
  [IDX,C,d]=kmeans2main(X,k,nOut,minCl,maxt,dsp,metric,C0);
  if(sum(d)<sum(bd)), bIDX=IDX; bC=C; bd=d; end
  if(dsp), fprintf('  d=%f  t=%fs\n',sum(d),etime(clock,t1)); end
end
IDX=bIDX; C=bC; d=bd; k=max(IDX);
if(dsp), fprintf('k=%i  d=%f  t=%fs\n',k,sum(d),etime(clock,t0)); end

% sort IDX to have biggest clusters have lower indicies
cnts = zeros(1,k); for i=1:k; cnts(i) = sum( IDX==i ); end
[~,order] = sort( -cnts ); C = C(order,:); d = d(order);
IDX2=IDX; for i=1:k; IDX2(IDX==order(i))=i; end; IDX = IDX2;

end

function [IDX,C,d] = kmeans2main( X, k, nOut, minCl, maxt, dsp, metric, C )

% initialize cluster centers to be k random X points
[N,p] = size(X); k = min(k,N); t=0;
IDX = ones(N,1); oldIDX = zeros(N,1);
if(isempty(C)), C = X(randperm(N,k),:)+randn(k,p)/1e5; end

% MAIN LOOP: loop until the cluster assigments do not change
if(dsp), nDg=ceil(log10(maxt-1)); fprintf(int2str2(0,nDg)); end
while( any(oldIDX~=IDX) && t<maxt )
  % assign each point to closest cluster center
  oldIDX=IDX; D=pdist2(X,C,metric); [mind,IDX]=min(D,[],2);
  
  % do not use most distant nOut elements in computation of centers
  mind1=sort(mind); thr=mind1(end-nOut); IDX(mind>thr)=-1;
  
  % Recalculate means based on new assignment, discard small clusters
  k0=0; C=zeros(k,p);
  for IDx=1:k
    ids=find(IDX==IDx); nCl=size(ids,1);
    if( nCl<minCl ), IDX(ids)=-1; continue; end
    k0=k0+1; IDX(ids)=k0; C(k0,:)=sum(X(ids,:),1)/nCl;
  end
  if(k0>0), k=k0; C=C(1:k,:); else k=1; C=X(randint2(1,1,[1 N]),:); end
  t=t+1; if(dsp), fprintf([repmat('\b',[1 nDg]) int2str2(t,nDg)]); end
end

% record within-cluster sums of point-to-centroid distances
d=zeros(1,k); for i=1:k, d(i)=sum(mind(IDX==i)); end

end
