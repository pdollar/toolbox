function visualizeData( X, k, IDX, types, C )
% Project high dim. data unto principal components (PCA) for visualization.
%
% Optionally IDX can be specified to indicate different classes for the
% points; in this case points in different classes are displayed using
% different colors. Up to 12 types are handled (for technical reasons
% involving plot), any cluster with a label>12 is assigned the label 12.
%
% USAGE
%  visualizeData( X, k, [IDX], [types], [C] )
%
% INPUTS
%  X       - column vector of data - N vectors of dimension p (X is Nxp)
%  k       - dimension to which to reduce data (2 or 3)
%  IDX     - [] cluster membership [see kmeans2.m]
%  types   - [] cell array of length ntypes of text labels for each type
%  C       - [] cluster centers (Kxp)
%
% OUTPUTS
%
% EXAMPLE
%  X = [randn(100,5); randn(100,5)+4];
%  C = [mean(X(1:100,:)); mean(X(101:200,:))];
%  IDX = [ones(100,1); 2*ones(100,1)];
%  visualizeData( X, 2, IDX, {'type1','type2' }, C);
%
% See also KMEANS2, DEMOCLUSTER
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(IDX) ); IDX=[]; end
if( nargin<4 || isempty(types) ); types=[]; end
if( nargin<5 || isempty(C) ); C=[]; end

% apply PCA if necessary
if( size(X,2)~= k )
  [ U, mu ] = pca( X' );
  X = pcaApply( X', U, mu, k )';
  if(~isempty(C)); C = pcaApply( C', U, mu, k )'; end
end

%%% get k
k = size(X,2);
if( k==1 ); X = [X zeros(size(X))]; k = 2; end
if( k>3 ); error( 'k must be <= 3'); end

%%% show points
if( isempty(IDX) )
  if( k==2 )
    plot( X(:,1), X(:,2), '.' );
  elseif( k==3 )
    plot3( X(:,1), X(:,2), X(:,3), '.' );
  end;

else
  IDX(IDX>12)=12;  m=max(IDX);

  if( k==2)
    % plot points
    R = cell(1,3*m+3);
    for i=1:m;
      R((3*i-2):(3*i)) = {X(IDX==i,1), X(IDX==i,2), '.'};
    end;
    R((3*m+1):(3*m+3)) = {X(IDX==-1,1), X(IDX==-1,2), 'k.'};
    plot( R{:} );

    % plot centers
    if( ~isempty(C) )
      R=cell(1,3*m);
      for i=1:m;  R((3*i-2):(3*i)) = {C(i,1), C(i,2), 'x'}; end
      hold('on');  plot( R{:}, 'MarkerSize', 30 );  hold('off');
    end;

  elseif( k==3 )
    % plot points
    R = cell(1,4*m+4);
    for i=1:m;
      R((4*i-3):(4*i)) = {X(IDX==i,1), X(IDX==i,2), X(IDX==i,3), '.'};
    end;
    R((4*m+1):(4*m+4)) = {X(IDX==-1,1), X(IDX==-1,2), X(IDX==-1,3), 'k.'};
    plot3( R{:} );

    % plot centers
    if( ~isempty(C) )
      R=cell(1,4*m);
      for i=1:m;  R((4*i-3):(4*i)) = {C(i,1), C(i,2), C(i,3), 'x'}; end
      hold('on'); plot3( R{:}, 'MarkerSize', 30 );  hold('off');
    end
  end
end
axis('equal');

%%% show legend if types is provided
if(~isempty(types));  legend(types); end
