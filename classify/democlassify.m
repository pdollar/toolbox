% A demo used to test and demonstrate the usage of classifiers (clf_*)
%
% To change the demo parameters alter this function. Note that the
% visualization of the train and test data may look different due to
% different 2D projections (see visualize_data).
%
% USAGE
%  democlassify
%
% INPUTS
%
% OUTPUTS
%
% EXAMPLE
%  democlassify
%
% See also CLF_KNN, CLF_LDA, CLF_SVM, CLF_ECOC, VISUALIZE_DATA

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!
 
function democlassify

%%% generate data
nClasses = 4;  d = 3;  nTrn=250;  nTst=150;  show = 1;

[trnData,trnIDX,tstData,tstIDX] = demogendata(nTrn,nTst,nClasses,d,1,6);
nTrn=size(trnData,1);  nTst=size(tstData,1); %#ok<NASGU>
if( show ) % make look different due to different projections
  figure(show); clf;
  subplot(3,1,1); visualize_data(trnData, 2, trnIDX ); title( 'train set');
  subplot(3,1,2); visualize_data(tstData, 2, tstIDX ); title( 'test set');
end;

%%% initialize learners:
nnets=0; labels={};
if(1); nnets=nnets+1; % linear LDA
  nets{nnets}.func_netinit = @clf_lda;
  nets{nnets}.netparams={'linear'};
  labels{nnets} = 'linear LDA';
end
if(1); nnets=nnets+1; % quadratic LDA
  nets{nnets}.func_netinit = @clf_lda;
  nets{nnets}.netparams={'quadratic'};
  labels{nnets} = 'quadratic LDA';
end
if(1); nnets=nnets+1; % kNN 5
  nets{nnets}.func_netinit = @clf_knn;
  nets{nnets}.netparams={5};
  labels{nnets} = 'kNN 5';
end
if(0); nnets=nnets+1; % svm ecoc [VERY SLOW]
  nets{nnets}.func_netinit = @clf_ecoc;
  nets{nnets}.netparams={@clf_svm,{'rbf',2^-1},nClasses};
  labels{nnets} = 'ecoc svm-rbf';
end

%%% train each learner, and apply to test data
pred = zeros( nTst, nnets );
for i=1:nnets
  disp(['training ' labels{i} ' classifier']);
  net = feval( nets{i}.func_netinit, d, nets{i}.netparams{:} );
  net = feval( net.fun_train, net, trnData, trnIDX );
  pred(:,i) = feval( net.fun_fwd, net, tstData );
  ncorrect = length(find(tstIDX==pred(:,i)));
  fprintf(['Classification result for ' labels{i} ...
    ':\n%i out of %i correct\n\n'], ncorrect, nTst);
end;

%%% calculate and show confusion matricies [not using confmatrix_show]
CM = zeros( nClasses, nClasses, nnets );
for i=1:nnets
  CMi = confmatrix( tstIDX, pred(:,i), nClasses );
  CM(:,:,i) = CMi ./ repmat( sum(CMi,2), [1 size(CMi,2)] );
end;
subplot(3,1,3); montage2( CM,1,1,[0,1],1,[],labels );





