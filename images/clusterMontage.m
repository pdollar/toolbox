function IC = clusterMontage( I, IDX, nElem, pad )
% Used for visualization of clusters of images and videos.
%
% Organizes the matrix I, which is either MxNxR for images or MxNxTxR for
% videos, into a [M x N x T x nElem x nCluster] array IC, where each
% element IC(:,:,:,:,i) is the set of objects belonging to cluster i.
% If not all clusters have the same size, if pad==1 blank elements are
% added to pad the clusters so they do in fact have the same size, and if
% pad is 0 then IC is a cell vector where IC{i} is the set of objects
% belonging to cluster i.
%
% To display only a subset of clusters, given in a vector cs, use IDXb:
%  IDXb = zeros(size(IDX)); for i=1:length(cs) IDXb(IDX==cs(i))=i; end;
%
% USAGE
%  IC = clusterMontage( I, IDX, nElem, [pad] )
%
% INPUTS
%  I       - MxNxR array of images or MxNxTxR array of videos
%  IDX     - cluster membership (Rx1 integer vector) [see kmeans2.m]
%  nElem   - max number of instances to show of each cluster
%  pad     - [1] pads each cluster w blanks so it has exactly nElem
%
% OUTPUTS
%  IC      - if pad==1  [M x N x T x nElem x nCluster] array
%          - if pad==0  nCluster cell of [M x N x T x nElem_i] arrays
%
% EXAMPLE - images
%  load( 'images.mat' );
%  keep=randSample(144,80); IDXi=IDXi(keep); images=images(:,:,keep);
%  IC = clusterMontage( images, IDXi, 9, 0 );
%  figure(1); montage2( IC )
%
% EXAMPLE - videos
%  load( 'images.mat' );
%  IC = clusterMontage( videos, IDXv, 9, 0 );
%  figure(1); playMovie( IC )
%
% See also KMEANS2, MONTAGE2, PLAYMOVIE, CELL2ARRAY
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(pad) ); pad=1; end

% error check
siz = size(I); nd = ndims(I);
if(nd~=3 && nd~=4); error('I must be 3 or 4 dimensional array'); end;
inds = {':'}; inds = inds(:,ones(1,nd-1));

% discard outliers
keepLocs = find( IDX>0 ); IDX = IDX(keepLocs); I=I(inds{:},keepLocs);

% sample both I and IDX so have nElem per cluster
uIDX=unique(IDX)';
for i=uIDX
  locs = find(IDX==i);  nLocs = length(locs);
  if( nLocs>nElem )
    keepLocs = [find(IDX~=i); locs(randSample(nLocs,nElem))];
    IDX = IDX(keepLocs); I=I(inds{:},keepLocs);
  elseif( nLocs<nElem && pad )
    nAdd = nElem-nLocs;
    IDX = [IDX; repmat(i,[nAdd,1])]; %#ok<AGROW>
    I = cat( nd, I, repmat(uint8(0),[siz(1:nd-1) nAdd]));
  end;
end;

% string out I
if( pad )
  IC = repmat( uint8(0), [siz(1:nd-1), nElem, length(uIDX)] );
  for i=uIDX; IC(inds{:},:,i) = I(inds{:},IDX==i); end
else
  IC = cell(1,max(IDX));
  for i=uIDX; IC{i} = I(inds{:},IDX==i); end
end
