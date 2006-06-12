% Very fast version of kmeans clustering.
%
% Cluster the N x p matrix X into k clusters using the kmeans algorithm. It returns the
% cluster memberships for each data point in the N x 1 vector IDX and the K x p matrix of
% cluster means in C. 
%
% Custom implementation of the kmeans algorithm.  In some ways it is less general (for
% example only uses euclidian distance), but it has some options that the matlab version
% does not (for example, it has a notion of outliers and min-cluster size).  It is also
% many times faster than matlab's kmeans.  General kmeans help can be found in help for
% the matlab implementation of kmeans. Note that the although the names and conventions
% for this algorithm are taken from Matlab's implementation, there are slight
% alterations (for example, IDX==-1 is used to indicate outliers).
%
% 
% -------------------------------------------------------------------------
% INPUTS
% 
%  X
% n-by-p data matrix of n p-dimensional vectors.  That is X(i,:) is the ith point in X.
%
%  k
% Integer indicating the maximum nuber of clusters for kmeans to find. Actual number may
% be smaller (for example if clusters shrink and are eliminated).
%
% -------------------------------------------------------------------------
% ADDITIONAL INPUTS
%
% [...] = kmeans2(...,'param1',val1,'param2',val2,...) enables you to
% specify optional parameter name-value pairs to control the iterative
% algorithm used by kmeans. Valid parameters are the following:
%   'replicates'  - Number of times to repeat the clustering, each with a
%                   new set of initial cluster centroid positions. kmeans
%                   returns the solution with the lowest value for sumd.
%   'maxiter'     - Maximum number of iterations. Default is 100.
%   'display'     - Whether or not to display algorithm status (default==0)
%   'randstate'   - seed with which to initialize kmeans.  Useful for
%                   replicability of algoirhtm.
%   'outlierfrac' - maximum fraction of points that can be treated as
%                   outliers   
%   'minCsize'    - minimum size for a cluster (smaller clusters get
%                   eliminated)
%
% -------------------------------------------------------------------------
% OUTPUTS
%
%  IDX
% n-by-1 vector used to indicated cluster membership.  Let X be a set of n points.  Then
% the ID of X - or IDX is a column vector of length n, where each element is an integer
% indicating the cluster membership of the corresponding point in X.  That is IDX(i)=c
% indicates that the ith point in X belongs to cluster c. Cluster labels range from 1 to
% k, and thus k=max(IDX) is typically the number of clusters IDX divides X into.  The
% cluster label "-1" is reserved for outliers.  That is IDX(i)==-1 indicates that the
% given point does not belong to any of the discovered clusters.  Note that matlab's
% version of kmeans does not have outliers.
%
%  C        
% k-by-p matrix of centroid locations.  That is C(j,:) is the cluster centroid of points
% belonging to cluster j.  In kmeans, given X and IDX, a cluster centroid is simply the
% mean of the points belonging to the given cluster, ie: C(j,:) = mean( X(IDX==j,:) ). 
%
%  sumd
% 1-by-k vector of within-cluster sums of point-to-centroid distances. That is sumd(j) is
% the sum of the distances from X(IDX==j,:) to C(j,:). The total sum, sum(sumd), is a
% typical error measure of the quality of a clustering. 
%
% -------------------------------------------------------------------------
%
% DATESTAMP
%   13-May-2006  6:00pm
%
% See also DEMOCLUSTER

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [IDX,C,sumd] = kmeans2( X,k,varargin )

    %%% get input args   (NOT SUPPORTED:  distance, emptyaction, start )
    pnames = {  'replicates' 'maxiter' 'display' 'randstate' 'outlierfrac' 'minCsize'};
    dflts =  {       1        100         0           []          0             1    };
    [errmsg,replicates,maxiter,display,randstate,outlierfrac,minCsize] = ...
                                                    getargs(pnames, dflts, varargin{:});
    error(errmsg);
    if (k<=1) error('k must be greater than 1'); end;
    if(ndims(X)~=2 || any(size(X)==0)) error('Illegal X'); end;
    if (outlierfrac<0 || outlierfrac>=1) 
        error('fraction of outliers must be between 0 and 1'); end;
    noutliers = floor( size(X,1)*outlierfrac );

    % initialize seed if it was not specified by user, otherwise set it.
    if (isempty(randstate)) randstate = rand('state'); else rand('state',randstate); end;

    % run kmeans2_main replicates times
    msg = ['Running kmeans2 with k=' num2str(k)]; 
    if (replicates>1) msg=[msg ', ' num2str(replicates) ' times.']; end;
    if (display) disp(msg); end;
    
    bestsumd = inf; 
    for i=1:replicates
        tic
        msg = ['kmeans iteration ' num2str(i) ' of ' num2str(replicates) ', step: '];
        if (display) disp(msg); end;
        [IDX,C,sumd,niters] = kmeans2_main(X,k,noutliers,minCsize,maxiter,display);
        if (sum(sumd)<sum(bestsumd)) bestIDX = IDX; bestC = C; bestsumd = sumd; end
        msg = ['\nCompleted kmeans iteration ' num2str(i) ' of ' num2str(replicates)];
        msg = [ msg ';  number of kmeans steps= ' num2str(niters) ...
                                                    ';  sumd=' num2str(sum(sumd)) '\n' ]; 
        if (display && replicates>1) fprintf(msg); toc, end;
    end
    
    IDX = bestIDX; C = bestC; sumd = bestsumd; k = max(IDX);  
    msg = ['Final number of clusters = ' num2str( k ) ';  sumd=' num2str(sum(sumd))]; 
    if (display) if(replicates==1) fprintf('\n'); end; disp(msg); end;    
    
    % sort IDX to have biggest clusters have lower indicies
    clustercounts = zeros(1,k); for i=1:k clustercounts(i) = sum( IDX==i ); end
    [ids,order] = sort( -clustercounts );  C = C(order,:);  sumd = sumd(order);
    IDX2 = IDX;  for i=1:k IDX2(IDX==order(i))=i; end; IDX = IDX2; 
    
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [IDX,C,sumd,niters] = kmeans2_main(X,k,noutliers,minCsize,maxiter,display)    

    % initialize the vectors containing the IDX assignments
    % and set initial cluster centers to be k random X points
    [N p] = size(X);
    IDX = ones(N,1); oldIDX = zeros(N,1);
    index = randperm2(N,k);  C = X(index,:); 
    
    % MAIN LOOP: loop until the cluster assigments do not change
    niters = 0;  ndisdigits = ceil( log10(maxiter-1) );
    if( display ) fprintf( ['\b' repmat( '0',[1,ndisdigits] )] ); end;
    while( sum(abs(oldIDX - IDX)) ~= 0 && niters < maxiter)

        % calculate the Euclidean distance between each point and each cluster mean
        % and find the closest cluster mean for each point and assign it to that cluster
        oldIDX = IDX;  D = dist_euclidean( X, C ); [mind IDX] = min(D,[],2);  

        % do not use most distant noutliers elements in computation of cluster centers
        mindsort = sort( mind ); thr = mindsort( end-noutliers );  IDX( mind > thr ) = -1; 

        % discard small clusters [place in outlier set, will get included next time around]
        i=1; while(i<=k) if (sum(IDX==i)<minCsize) IDX(IDX==i)=-1; 
                if(i<k) IDX(IDX==k)=i; end; k=k-1; else i=i+1; end; end
        if( k==0 ) IDX( randint2( 1,1, [1,N] ) ) = 1; k=1; end;
        for i=1:k if ((sum(IDX==i))==0) 
                error('should never happen - empty cluster!'); end; end;        

        % Recalculate the cluster means based on new assignment (loop is compiled - fast!)
        % Actually better then looping over k, because X(IDX==i) is slow. 
        C = zeros(k,p);  counts = zeros(k,1);
        for i=find(IDX>0)' IDx = IDX(i); counts(IDx)=counts(IDx)+1; 
            C(IDx,:) = C(IDx,:)+X(i,:); end
        C = C ./ counts(:,ones(1,p));
        
        niters = niters+1;
        if( display ) 
            fprintf( [repmat('\b',[1 ndisdigits]) int2str2(niters,ndisdigits)] ); end;
    end

    % record within-cluster sums of point-to-centroid distances 
    sumd = zeros(1,k); for i=1:k sumd(i) = sum( mind(IDX==i) ); end

    
    
    
    
    
