function demoClassify
%DEMOCLASSIFY A demo used to test and demonstrate the usage of classifiers (clf*)
%
% To change the demo parameters alter this function. Note that the
% visualization of the train and test data may look different due to
% different 2D projections (see visualizeData).
%
% USAGE
%  demoClassify
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%  demoClassify
%
% See also CLFKNN, CLFLDA, CLFSVM, CLFECOC, CLFDECTREE, VISUALIZEDATA
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

%%% generate data
nClasses = 4;  d = 3;  nTrn=250;  nTst=150;  show = 1;

[trnData,trnIDX,tstData,tstIDX] = demoGenData(nTrn,nTst,nClasses,d,1,6);
nTrn=size(trnData,1);  nTst=size(tstData,1); %#ok<NASGU>
if( show ) % make look different due to different projections
  figure(show); clf;
  subplot(3,1,1); visualizeData(trnData, 2, trnIDX ); title( 'train set');
  subplot(3,1,2); visualizeData(tstData, 2, tstIDX ); title( 'test set');
end;

%%% initialize learners:
nnets=0; labels={};
if(1); nnets=nnets+1; % linear LDA
  nets{nnets}.funNetInit = @clfLda;
  nets{nnets}.netPrms={'linear'};
  labels{nnets} = 'linear LDA';
end
if(1); nnets=nnets+1; % quadratic LDA
  nets{nnets}.funNetInit = @clfLda;
  nets{nnets}.netPrms={'quadratic'};
  labels{nnets} = 'quadratic LDA';
end
if(1); nnets=nnets+1; % kNN 5
  nets{nnets}.funNetInit = @clfKnn;
  nets{nnets}.netPrms={5};
  labels{nnets} = 'kNN 5';
end
if(0); nnets=nnets+1; % svm ecoc [VERY SLOW]
  nets{nnets}.funNetInit = @clfEcoc;
  nets{nnets}.netPrms={@clfSvm,{'rbf',2^-1},nClasses};
  labels{nnets} = 'ecoc svm-rbf';
end

%%% train each learner, and apply to test data
pred = zeros( nTst, nnets );
for i=1:nnets
  disp(['training ' labels{i} ' classifier']);
  net = feval( nets{i}.funNetInit, d, nets{i}.netPrms{:} );
  net = feval( net.funTrain, net, trnData, trnIDX );
  pred(:,i) = feval( net.funFwd, net, tstData );
  ncorrect = length(find(tstIDX==pred(:,i)));
  fprintf(['Classification result for ' labels{i} ...
    ':\n%i out of %i correct\n\n'], ncorrect, nTst);
end;

%%% calculate and show confusion matricies [not using confMatrixShow]
CM = zeros( nClasses, nClasses, nnets );
for i=1:nnets
  CMi = confMatrix( tstIDX, pred(:,i), nClasses );
  CM(:,:,i) = CMi ./ repmat( sum(CMi,2), [1 size(CMi,2)] );
end;
prm = struct('extraInfo',1,'cLim',[0,1],'mm',1,'labels',{labels});
subplot(3,1,3); montage2( CM, prm );
