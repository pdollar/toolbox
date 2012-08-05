function [IDX,C] = meanShiftPost( X, IDX, C, minCl, forceOutl )
% Some post processing routines for meanShift not currently being used.
%
% USAGE
%  [IDX,C] = meanShiftPost( X, IDX, C, minCl, forceOutl )
%
% INPUTS
%  see meanShift
%
% OUTPUTS
%  see meanShift
%
% EXAMPLE
%
% See also MEANSHIFT, KMEANS2
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

%%% force outliers to belong to IDX (mainly for visualization)
if( forceOutl )
  for i=find(IDX<0)'
    D = pdist2( X(i,:), C );
    [mind IDx] = min(D,[],2);
    IDX(i) = IDx;
  end
end;

%%% Delete smallest cluster, reassign points, re-sort, repeat...
k = max(IDX);
ticId = ticStatus('meanShiftPost',[],5); kinit = k;
while( 1 )
  % sort clusters [largest first]
  cnts = zeros(1,k); for i=1:k; cnts(i) = sum( IDX==i ); end
  [cnts,order] = sort( -cnts ); cnts = -cnts; C = C(order,:);
  IDX2 = IDX;  for i=1:k; IDX2(IDX==order(i))=i; end; IDX = IDX2;

  % stop if smallest cluster is big enough
  if( cnts(k)>= minCl ); break; end;

  % otherwise discard smallest [last] cluster
  C( end, : ) = [];
  for i=find(IDX==k)'
    D = pdist2( X(i,:), C );
    [mind IDx] = min(D,[],2);
    IDX(i) = IDx;
  end;
  k = k-1;

  tocStatus( ticId, (kinit-k)/kinit );
end
tocStatus( ticId, 1 );
