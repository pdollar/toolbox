% k-nearest neighbor classifier based on a distance matrix D.
%
% k==1 is much faster than k>1.  For k>1, ties are broken randomly.
%
% INPUTS
%   D       - MxN array of distances from M-TEST points to N-TRAIN points.
%   IDX     - ntrain length vector of class memberships 
%             if IDX(i)==IDX(j) than sample i and j are part of the same class
%   k       - [optional] number of nearest neighbors to use, 1 by default
%
% OUTPUTS
%   IDXpred - length M vector of classes for training data
%
% EXAMPLE
%   % [given D and IDX]
%   for k=1:size(D,2) err(k)=sum(IDX==clf_knn_dist(D,IDX,k)); end; 
%   figure(1); plot(err)
%
% DATESTAMP
%   11-Oct-2005  8:00pm
%
% See also CLF_KNN

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function IDXpred = clf_knn_dist( D, IDX, k )
    if( nargin<3 | isempty(k) ) k=1;  end;
    
    [n ntrain] = size(D);
    if( ntrain ~= length(IDX) );
        error('Distance matrix and IDX vector dimensions do not match.'); end;
    
    %%% 1NN [fast and easy]
    if( k==1 )
        [dis,Dind]=min(D,[],2); 
        IDXpred=IDX(Dind);

    %%% kNN
    else 
        [IDXnames,dis,IDX]=unique(IDX);
        
        %%% get closests k prototypes [n x k  matrix]
        [D,knns_inds] = sort(D,2);
        knns_inds = knns_inds(:,1:k);
        knns = IDX(knns_inds);        
        if( n==1 ) knns = knns'; end;
        
        %%% get counts of each of the prototypes
        nclasses = max(IDX);
        counts = zeros(n,nclasses);
        for i=1:nclasses  counts(:,i)=sum(knns==i,2);  end;
        counts = counts + randn(size(counts))/1000; % hack to break ties randomly!
        [ counts, classes ] = sort(counts,2,'descend');
        
        %%% get IDXpred
        IDXpred = IDXnames( classes(:,1) );
    end
