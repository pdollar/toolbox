function [D, Dsm] = distMatrixShow( D, IDX, show )
% Useful visualization of a distance matrix of clustered points.
%
% D is sorted into k blocks, where the ith block contains all the points in
% cluster i. When D is displayed the blocks are shown explicitly.  Hence
% for a good clustering (under a spherical gaussian assumption) the
% 'diagonal' blocks ought to be mostly dark, and all other block ought to be
% relatively white.  One can thus quickly visualize the quality of the
% clustering, or even how clusterable the points are.  Outliers (according
% to IDX) are removed from D.
%
% USAGE
%  [D, Dsm] = distMatrixShow( D, IDX, [show] )
%
% INPUTS
%  D       - nxn distance matrix
%  IDX     - cluster membership [see kmeans2.m]
%  show    - [1] will display results in figure(show)
%
% OUTPUTS
%  D       - sorted nxn distance matrix
%  Dsm     - sorted and smoothed nxn distance matrix
%
% EXAMPLE
%  % not the best example since points are already ordered
%  [X,IDX] = demoGenData(100,0,5,2,10,2,0);
%  distMatrixShow( pdist2(X,X), IDX );
%
% See also VISUALIZEDATA, KMEANS2
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(show) ); show=1; end

k = max(IDX);
n = size(D,1);

%%% remove outliers from D and IDX
inliers = IDX>0;
D = D( inliers, inliers );
IDX = IDX( inliers );

%%% get order of points and rearrange D and IDX
order = IDX2order( IDX );
IDX = IDX( order );
D = D( order, order );

%%% compute smoothed version of D
cnts = zeros(1,k); for i=1:k; cnts(i)=sum(IDX==i); end
cumCnts = cumsum(cnts);  cumCnts2=[0 cumCnts];  Dsm = D;
inds = 1:k; inds = inds( cnts>0 );
for i=inds
  rs = cumCnts2(i)+1:cumCnts2(i+1);
  for j=inds
    cs = cumCnts2(j)+1:cumCnts2(j+1);
    ds = D( rs, cs  );
    Dsm( rs, cs ) = mean(ds(:));
  end;
end;

%%% show D and lines seperating super clusters.
if(show)
  figure(show); clf;
  subplot(1,2,1); im(D); hold('on')
  for i=1:k-1
    line( [.5,n+.5], [cumCnts(i)+.5,cumCnts(i)+.5] );
    line( [cumCnts(i)+.5,cumCnts(i)+.5], [.5,n+.5] );
  end;
  hold('off');
  subplot(1,2,2); im( Dsm );
end
