% Used for visualization of clusters of images and videos.
%
% To display only a subset of clusters, given in a vector cs, use IDXb:
%  IDXb = zeros(size(IDX)); for i=1:length(cs) IDXb(IDX==cs(i))=i; end;
%
% To save created movie:
%  movie2avi( M, 'example.avi', 'compression', 'Cinepak' );
%
% USAGE
%  XC = clustermontage( X, IDX, nvals, pad )
%
% INPUTS
%  X       - MxNxR array of images or MxNxTxR array of videos
%  IDX     - cluster membership (Rx1 integer vector) [see kmeans2.m]
%  nvals   - max number of instances to show of each cluster
%  pad     - pads each cluster w blanks so it has exactly nvals elements,
%            if necessary
%
% OUTPUTS
%  XC      - if pad==1
%            M x N x nvals x nclusters if X contains images
%            M x N x T x nvals x nclusters if X contains videos
%          - if pad==0
%            nclusters cell of M x N x c arrays if X contains images
%            nclusters cell of M x N x T x c arrays if X contains videos
%
% EXAMPLE
%
% See also KMEANS2, MONTAGES, MAKEMOVIESETS, CELL2ARRAY

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!
 
function XC = clustermontage( X, IDX, nvals, pad )

% error check
siz = size(X); nd = ndims(X);
if(nd~=3 && nd~=4); error('X must be 3 or 4 dimensional array'); end;
inds = {':'}; inds = inds(:,ones(1,nd-1));

% sample both X and IDX so have nvals per cluster
keeplocs = find( IDX>0 ); IDX = IDX(keeplocs); X=X(inds{:},keeplocs);
uIDX=unique(IDX)';
for i=uIDX
  locs = find(IDX==i); nlocs = length(locs);
  if( nlocs>nvals )
    rperm=randperm(nlocs);
    keeplocs = [find(IDX~=i); locs(rperm(1:nvals))];
    IDX = IDX(keeplocs); X=X(inds{:},keeplocs);
  elseif( nlocs<nvals && pad )
    addn = nvals-nlocs;
    IDX = [IDX; repmat(i,[addn,1])]; %#ok<AGROW>
    X = cat( nd, X, repmat(uint8(0),[siz(1:nd-1) addn]));
  end;
end;

% string out X
if( pad )
  XC = repmat( uint8(0), [siz(1:nd-1), nvals, length(uIDX)] );
  for i=uIDX; XC(inds{:},:,i) = X(inds{:},IDX==i); end
else
  XC = cell(1,length(IDX));
  for i=uIDX; XC{i} = X(inds{:},IDX==i); end
end

