% Find neighbors (must be close in Euclidean space and from the same set).
%
% sizes/dimensions:
%   nSet    - number of point sets
%   nPoint  - number of points / set
%   D       - dimension of each point
%   n       - nSet*nPoint
%
% USAGE
%   neigh = computeNeighbor( X, prm )
%
% INPUT
%   X or X3    - data [D x n] or [nSet x nPoint x D] or matrix
%   prm        - parameters
%        .k          - number of nearest neighbors
%        .maxDist    - maximum sqrd dist defining neighbors (used if k=[])
%        .forceSym   - [1] force symmetry (N(i,j)~=N(j,i) poss if using k)
%        .forceConn  - [0] force connectivity, increases k/maxDist as req
%        .show       - [0] optionally display neighbors in figure(show)
%
% OUTPUT
%   neigh      - struct containing neighborhood information
%        .N       - [nxNi] cell array of lists of neighbors for each i
%        .Nmat    - [nxn] sparse matrix st N(i,j)=1 iff i,j are neighbors
%        .Dmat    - [nxn] sparse matrix of euc distance between neighbors
%        .stats   - [1xmaxk] histogram of neighbor counts for all points
%        .scale   - [1xnSet] the median dist to the nearest neighbor
%        .conn    - [1xnSet] true iff neighborhood graph is connected
%        .maxDist - [scalar] value used (can increase if forceConn)
%        .k       - [scalar] value used (can increase if forceConn)
%
% EXAMPLE
%
% See also 

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function neigh = computeNeighbor( X3, prm )

dfs = {'maxDist',[], 'k',[], 'forceSym',1, 'forceConn',0, 'show',0 };
prm = getParamDefaults( prm, dfs );
k = prm.k;  maxDist = prm.maxDist;  show=prm.show;
if( isempty(k) && isempty(maxDist)); error('k or maxDist REQ'); end;

if(ndims(X3)==2); X3=permute(reshape(X3',[],1,size(X3,1)),[2 1 3]); end;
[nSet, nPoint, D] = size(X3);  n = nSet*nPoint;
if( nSet<1 || nPoint <1 || D<=1 )
  error( 'X has bad dimensions' ); end;

% create Nmat, Dmat
Nmat = logical(sparse(n,n)); Dmat=sparse(n,n);
scale=zeros(1,nSet);
for i=1:nSet
  Xi = squeeze( X3(i,:,:) );
  Di = dist_euclidean( Xi, Xi );
  Di = Di + eye(nPoint)*realmax;
  if( ~isempty( k ) )
    [ordered]=sort(Di,2);
    scale(i) = sqrt(median(ordered(:,1)));
    ordered = repmat( ordered(:,k), 1, nPoint );
    Ni = sparse(Di <= (ordered+eps));
  else
    Ni = sparse(Di <= maxDist^2);
    scale(i) = sqrt(median(min(Di)));
  end
  Di(~Ni)=0; Di=sqrt(sparse(Di));

  if(nSet==1);  Nmat=Ni; Dmat=Di;  else
    str = (i-1)*nPoint+1; fin=str+nPoint-1;
    Nmat( str:fin, str:fin ) = Ni;
    Dmat( str:fin, str:fin ) = Di;
  end
end

% force symmetry
if( ~isempty(k) && prm.forceSym )
  Nmat = max(Nmat,Nmat');
  Dmat = max(Dmat,Dmat');
end

% check for connectivity
conn = zeros(1,nSet);
for i=1:nSet
  if(nSet==1); Di=Dmat; else
    str = (i-1)*nPoint+1; fin=str+nPoint-1;
    Di = Dmat( str:fin, str:fin );
  end
  [temp,prev] = dijkstra(Di,1);
  conn(i) = all(prev(2:end)>0);
end

% force connectivity
if( (prm.forceConn>0 && any(conn==0)) || prm.forceConn>1 )
  if(~isempty(k)); prm.k=k+1; else prm.maxDist=maxDist*1.05; end
  if( all(conn==1) ); prm.forceConn=prm.forceConn-1; end
  neigh = computeNeighbor( X3, prm ); return;
end;

% compute N (neighbors list); stats; store
N=cell(1,n);  for i=1:n; N{i}=find(Nmat(i,:)); end
stats = zeros(n,1) + sum(Nmat,2);
stats = histc( stats, 0:max(stats) );
neigh = struct( 'N',{N}, 'Nmat',Nmat, 'Dmat',Dmat, ...
  'stats',stats, 'scale',scale, 'conn',conn, ...
  'maxDist',maxDist, 'k',k );

% optionally show results
if( show )
  visualizeManifold(X3,show,struct('N',{N}));
end
