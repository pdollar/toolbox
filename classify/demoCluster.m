% Clustering demo.
%
% Used to test different clustering algorithms on 2D and 3D mixture of
% gaussian data. Alter demo by edititing this file.
%
% USAGE
%  demoCluster
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%  demoCluster

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

%%% generate data
if(1) % mixture of gaussians -- see demoGenData
  kTr = 5; sep = 3; ecc = 3; nFracTr = 0.1;  nPnts = 1000;  d = 2;
  [X,IDXtr] = demoGenData(nPnts,0,kTr,d,sep,ecc,nFracTr);
else
  % two parallel clusters - kmeans will fail
  kTr = 2;  nPnts = 200;  sep = 4;
  X = [([5 0; 0 .5] * randn(2,nPnts) + sep/2)' ; ...
    ([5 0; 0 .5] * randn(2,nPnts) - sep/2)' ] / 5;
  IDXtr = [ones(1,nPnts) 2*ones(1,nPnts)];
  nFracTr=0;
end;
nFrac = nFracTr;  k = kTr;


%%% cluster
switch 'kmeans2'
  case 'kmeans2'
    params = {'replicates', 4, 'display', 1, 'outlierfrac', nFrac};
    [IDX,C,sumd] = kmeans2( X, k, params{:} );  sum(sumd)
  case 'meanShift'
    %(X,radius,rate,maxiter,minCsize,blur)
    [IDX,C] = meanShift( X, .3, .2, 100 , 10, 0 );
end

%%% show data & clustering results
figure(1); clf; d2 = min(d,3);
subplot(2,2,1); visualize_data(X, d2); title('orig points');
if(~isempty(IDXtr))
  subplot(2,2,2); visualize_data(X, d2, IDXtr); title('true clusters');
end;
subplot(2,2,3); visualize_data(X, d2, IDX, [], C); title('rec clusters');
subplot(2,2,4); D=distMatrixShow(sqrt(dist_euclidean(X,X)),IDX,0); im(D);
