% A demo used to test and demonstrate the usage of classifiers (clf_*)
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also CLF_KNN, CLF_LDA, CLF_SVM, CLF_ECOC

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function democlassify
    
    %%% generate data
    nclasses = 4;  nin = 3;  ntrain=250;  ntest=150;
    [train,trainIDX,test,testIDX] = demogendata(ntrain,ntest,nclasses,nin,1,6);
    ntrain=size(train,1);  ntest=size(test,1);
    show = 1; if( show )
        % make look different due to different projections
        figure(show); clf; 
        subplot(3,1,1); visualize_data( train, 2, trainIDX ); title( 'training set');
        subplot(3,1,2); visualize_data( test, 2, testIDX ); title( 'testing set');
    end;

    %%% initialize learners:
    nnets=0; labels={};
    if(1) nnets=nnets+1; % linear LDA
        nets{nnets}.func_netinit = @clf_lda; 
        nets{nnets}.netparams={'linear'};
        labels{nnets} = 'linear LDA';
    end
    if(1) nnets=nnets+1; % quadratic LDA
        nets{nnets}.func_netinit = @clf_lda; 
        nets{nnets}.netparams={'quadratic'};
        labels{nnets} = 'quadratic LDA';
    end
    if(1) nnets=nnets+1; % kNN 5
        nets{nnets}.func_netinit = @clf_knn; 
        nets{nnets}.netparams={5};
        labels{nnets} = 'kNN 5';
    end
    if(0) nnets=nnets+1; % svm ecoc [VERY SLOW]
        nets{nnets}.func_netinit = @clf_ecoc; 
        nets{nnets}.netparams={@clf_svm,{'rbf',2^-1},nclasses};
        labels{nnets} = 'ecoc svm-rbf';
    end

    
    %%% train each learner, and apply to test data
    pred = zeros( ntest, nnets );
    for i=1:nnets
        disp(['training ' labels{i} ' classifier']);
        net = feval( nets{i}.func_netinit, nin, nets{i}.netparams{:} );
        net = feval( net.fun_train, net, train, trainIDX );
        pred(:,i) = feval( net.fun_fwd, net, test );
        ncorrect = length(find(testIDX==pred(:,i)));
        fprintf(['Classification result for ' labels{i} ...
                 ':\n%i out of %i correct\n\n'], ncorrect, ntest);
    end;
    
    %%% calculate and show confusion matricies [not using confmatrix_show]
    CM = zeros( nclasses, nclasses, nnets );
    for i=1:nnets
        CMi = confmatrix( testIDX, pred(:,i), nclasses );
        CM(:,:,i) = CMi ./ repmat( sum(CMi,2), [1 size(CMi,2)] );
    end;
    subplot(3,1,3); montage2( CM,1,1,[0,1],1,[],labels );

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
