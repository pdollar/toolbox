% Project high dim. data unto principal components (PCA) for visualization.
%
% Optionally IDX can be specified to indicate different classes for the
% points; in this case points in different classes are displayed using
% different colors. Up to 12 types are handled (for technical reasons
% involving plot), any cluster with a label>12 is assigned the label 12.
%
% USAGE
%  visualize_data( X, k, [IDX], [types] )
%
% INPUTS
%  X       - column vector of data - N vectors of dimension p (X is Nxp)
%  k       - dimension to which to reduce data (2 or 3)
%  IDX     - [] cluster membership [see kmeans2.m]
%  types   - [] cell array of length ntypes of text labels for each type 
%
% OUTPUTS
%
% EXAMPLE
%  X=[randn(100,5); randn(100,5)+4];
%  IDX=[ones(100,1); 2*ones(100,1)];
%  visualize_data( X, 2, IDX, {'type1','type2' });
%
% See also KMEANS2

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function visualize_data( X, k, IDX, types )

if( nargin<3 || isempty(IDX) ); IDX=[]; end;
if( nargin<4 || isempty(types) ); types=[]; end;

% apply PCA if necessary
if( size(X,2)~= k )
  [ U, mu, variances ] = pca( X' );
  X = pca_apply( X', U, mu, variances, k )';
end

%%% get k
k = size(X,2);
if( k==1 ); X = [X zeros(size(X))]; k = 2; end;
if( k>3 ); error( 'k must be <= 3'); end;

%%% show points
if( isempty(IDX) ) % no color
  if( k==2 )
    plot( X(:,1), X(:,2), '.' );
  elseif( k==3 )
    plot3( X(:,1), X(:,2), X(:,3), '.' );
  end;
  
else % color coded
  IDX(IDX>12)=12;  m=max(IDX);  % limit on number of types
  if( k==2)
    R = cell(1,3*m+3);
    for i=1:m;  
      R((3*i-2):(3*i)) = { X(IDX==i,1), X(IDX==i,2),'.' };  
    end; 
    R((3*m+1):(3*m+3)) = { X(IDX==-1,1), X(IDX==-1,2), 'k.' };
    plot( R{:} ); axis('equal'); 
  elseif( k==3 )
    R = cell(1,4*m+4);
    for i=1:m;  
      R((4*i-3):(4*i)) = { X(IDX==i,1), X(IDX==i,2), X(IDX==i,3), '.' };  
    end; 
    R((4*m+1):(4*m+4)) = { X(IDX==-1,1), X(IDX==-1,2), X(IDX==-1,3), 'k.'};
    plot3( R{:} ); axis('equal');
  end;
end;

%%% show legend if types is provided
if(~isempty(types));  legend(types);  end;
