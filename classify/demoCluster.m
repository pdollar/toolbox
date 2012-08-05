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
%
% See also KMEANS2, MEANSHIFT
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

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
    prm.nTrial=4; prm.display=1; prm.outFrac=nFrac;
    [IDX,C,sumd] = kmeans2( X, k, prm ); 
  case 'meanShift'
    %(X,radius,rate,maxiter,minCsize,blur)
    [IDX,C] = meanShift( X, .4, .2, 100 , 10, 0 );
end

%%% show data & clustering results
figure(1); clf; d2 = min(d,3);
subplot(2,2,1); visualizeData(X, d2); title('orig points');
if(~isempty(IDXtr))
  subplot(2,2,2); visualizeData(X, d2, IDXtr); title('true clusters');
end;
subplot(2,2,3); visualizeData(X, d2, IDX, [], C); title('rec clusters');
subplot(2,2,4); D=distMatrixShow(sqrt(pdist2(X,X)),IDX,0); im(D);
