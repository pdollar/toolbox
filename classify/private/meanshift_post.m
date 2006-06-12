% Some post processing routines for meanshift not currently being used.
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [IDX,C] = meanshift_post( X, IDX, C, minCsize, forceoutliers )
    k = max(IDX); n = length(IDX);

    %%% force outliers to belong to IDX if ~outliersflag (mainly for visualization)
    if( forceoutliers ) 
        for i=find(IDX<0)' 
            D = dist_euclidean( X(i,:), C ); 
            [mind IDx] = min(D,[],2);  
            IDX(i) = IDx;
        end 
    end; 
    
    %%% Delete smallest cluster, reassign points, resort, delete smallest cluster..
    ticstatusid = ticstatus('meanshift_post',[],5); kinit = k;
    while( 1 )
        % sort clusters [largest first] 
        ccounts = zeros(1,k); for i=1:k ccounts(i) = sum( IDX==i ); end
        [ccounts,order] = sort( -ccounts ); ccounts = -ccounts; C = C(order,:);  
        IDX2 = IDX;  for i=1:k IDX2(IDX==order(i))=i; end; IDX = IDX2;     

        % stop if smallest cluster is big enough
        if( ccounts(k)>= minCsize ) break; end;
        
        % otherwise discard smallest [last] cluster
        C( end, : ) = []; 
        for i=find(IDX==k)' 
            D = dist_euclidean( X(i,:), C ); 
            [mind IDx] = min(D,[],2);  
            IDX(i) = IDx;
        end; 
        k = k-1;
            
        tocstatus( ticstatusid, (kinit-k)/kinit );
    end
    tocstatus( ticstatusid, 1 );
