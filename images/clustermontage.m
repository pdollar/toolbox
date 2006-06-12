% Used for visualization of clusters of images and videos.  
%
% To display only a subset of clusters, given in a vector cs, use IDXb:
%   IDXb = zeros(size(IDX)); for i=1:length(cs) IDXb(IDX==cs(i))=i; end;
%
% To save created movie:
%   movie2avi(M, ['example.avi'], 'compression','Cinepak');
%
% INPUTS
%   X       - MxNxR array of images or MxNxTxR array of videos
%   IDX     - cluster membership (Rx1 integer vector) [see kmeans2.m]
%   nvals   - max number of instances to show of each cluster
%   pad     - pads each cluster w blanks so it has exactly nvals elements, if necessary
%
% OUTPUTS
%   XC       - if pad==1
%              M x N x nvals x nclusters if X contains images
%              M x N x T x nvals x nclusters if X contains videos
%            - if pad==0
%              nclusters cell of M x N x c arrays if X contains images
%              nclusters cell of M x N x T x c arrays if X contains videos
%
% EXAMPLE
%
% DATESTAMP
%   29-Nov-2005  10:00am
%
% See also KMEANS2, MONTAGES, MAKEMOVIESETS, CELL2ARRAY

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function XC = clustermontage( X, IDX, nvals, pad )
    %%% error check 
    siz = size(X); nd = ndims(X); k = max(IDX);
    if(nd~=3 && nd~=4) error('X must be 3 or 4 dimensional array'); end;
    inds = {':'}; inds = inds(:,ones(1,nd-1));   

    %%% sample both X and IDX so have nvals per cluster
    keeplocs = find( IDX>0 ); IDX = IDX(keeplocs); X=X(inds{:},keeplocs);
    for i=1:k
        locs = find(IDX==i); nlocs = length(locs);
        if( nlocs>nvals ) 
            rperm=randperm(nlocs); 
            keeplocs = [find(IDX~=i); locs(rperm(1:nvals))];
            IDX = IDX(keeplocs); X=X(inds{:},keeplocs);
        elseif( nlocs<nvals && pad )
            addn = nvals-nlocs;
            IDX = [IDX; repmat(i,[addn,1])];
            X = cat( nd, X, repmat(uint8(0),[siz(1:nd-1) addn]));
        end;
    end;

    %%% string out X
    if( pad )
        XC = repmat( uint8(0), [siz(1:nd-1), nvals, k] );
        for i=1:k XC(inds{:},:,i) = X(inds{:},find(IDX==i)); end
    else
        XC = cell(1,k);
        for i=1:k XC{i} = X(inds{:},find(IDX==i)); end;
    end;
        
       
