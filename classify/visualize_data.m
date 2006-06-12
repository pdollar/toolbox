% Project high dim. data unto principal components (PCA) for visualization.
%
% Optionally IDX can be specified to indicate different classes for the points;
% in this case points in different classes are displayed using different colors.
% Up to 12 types are handled (for technical reasons involving plot), any 
% cluster with a label>12 is assigned the label 12.
%
% INPUTS
%   X       - column vector of data - N vectors of dimension p (X is Nxp)
%   k       - dimension to which to reduce data (2 or 3)
%   IDX     - [optional] cluster membership [see kmeans2.m]
%   types   - [optional] cell array of length ntypes of text labels for each type 
%
% EXAMPLE
%   X=[randn(100,5); randn(100,5)+4];
%   IDX=[ones(100,1); 2*ones(100,1)];
%   visualize_data( X, 2, IDX, {'type1','type2' });
%
% DATESTAMP
%   29-Nov-2005  2:00pm
%
% See also KMEANS2

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function visualize_data( X, k, IDX, types )
    if( nargin<3 || isempty(IDX) ) IDX=[]; end;
    if( nargin<4 || isempty(types) ) types=[]; end;

    % apply PCA if necessary
    if( size(X,2)~= k )
        [ U, mu, variances ] = pca( X' );
        X = pca_apply( X', U, mu, variances, k )';
    end
    
    %%% get k
    k = size(X,2);
    if( k==1 ) X = [X zeros(size(X))]; k = 2; end;
    if( k>3 ) error( 'k must be <= 3'); end;
    
    
    %%% show points
    if( isempty(IDX) )
        if( k==2 )
            plot( X(:,1), X(:,2), '.' );
        elseif( k==3 )
            plot3( X(:,1), X(:,2), X(:,3), '.' );
        end;

    %%% show color-coded points (by class)
    else 
        IDX(IDX>12)=12;  c=1;  m=max(IDX);  % limit on number of types
        if( k==2)
            for i=1:m  
                R{c}=X(IDX==i,1);  R{c+1}=X(IDX==i,2);  
                R{c+2}='.';  c=c+3; 
            end; 
            R{c}=X(IDX==-1,1);  R{c+1}=X(IDX==-1,2);  
            R{c+2}='k.';  c=c+3;
            plot( R{:} ); axis('equal'); 
        elseif( k==3 )
            for i=1:m
                R{c}=X(IDX==i,1);  R{c+1}=X(IDX==i,2);  
                R{c+2}=X(IDX==i,3);  R{c+3}='.';  c=c+4; 
            end; 
            R{c}=X(IDX==-1,1);  R{c+1}=X(IDX==-1,2);  
            R{c+2}=X(IDX==-1,3);  R{c+3}='.';  c=c+4;
            plot3( R{:} ); axis('equal');
        end;
    end;
    
    %%% show legend if types is provided
    if(~isempty(types))  legend(types);  end;
