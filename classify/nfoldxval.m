% Runs n-fold cross validation on data with a given classifier.
%
% Given n separate labeled data sets, trains classifier using n-1 data sets, test on
% remaining one.  Average results over all n such runs.  Shows overall results in average
% confusion matrix.
%
% The classifier is passed in as a parameter.  For this to work the classifier (clf) must
% follow certain conventions.  The conventions are as follows:
%   1) The following must initialize the clf ('p' is the dimension of the data):
%       clf = clfinit( p, clfparams{:} ) 
%   2) The created clf must point to 2 functions for training and applying it:
%       clf.fun_train    and   clf.fun_fwd
%   3) For training the following will be called:
%       clf = clf.fun_train( clf, X, Y );
%   4) For testing the following will be called:
%       pred = clf.fun_fwd( clf, Xtest );
% The format for X is nxp where n is the number of data points and p is their dimension.
% The format for Y is nx1.  Example of a classifier is: clfinit = @clf_lda
%
% Given data in a cell array format, it might be useful to string out into single array:
%   IDX = cell2mat( permute( IDX, [2 1] ) );  data = cell2mat( permute( data, [2 1] ) );
% For a simple, small dataset, can do the following to do leave one out classification:
%   [n,p]=size(data); IDX=mat2cell(IDX,ones(1,n),1);  data=mat2cell(data,ones(1,n),p);
%
% Overall error can be calculated via:
%   er = 1-sum(diag(CM))/sum(CM(:))
% Normalized confusion matrix can be calculated via:
%   CMn = CM ./ repmat( sum(CM,2), [1 size(CM,2)] );
%
% INPUTS
%   data        - cell array of (n x p) arrays each of n samples of dim p
%   IDX         - cell array of (n x 1) arrays each of n labels
%   clfinit     - classifier initialization function
%   clfparams   - classifier parameters 
%   types       - [optional] cell array of string labels for types
%   ignoretypes - [optional] array of types we aren't interested in {eg: [1 4 5]}.
%   fname       - [optional] specify a file to save CM to, as well as image
%   show        - [optional] will display results in figure(show) 
%
% OUTPUTS
%   CM          - confusion matrix
%
% EXAMPLE
%   load clf_data; % 2 class data
%   nfoldxval( data, IDX, @clf_lda,{'linear'}, [],[],[],1 );      % LDA
%   nfoldxval( data, IDX, @clf_knn,{4},[],[],[],2 );              % 4 k nearest neighbor
%   nfoldxval( data, IDX, @clf_svm,{'poly',2},[],[],[],3 );       % polynomial SVM
%   nfoldxval( data, IDX, @clf_svm,{'rbf',2^-12},[],[],[],4 );    % rbf SVM
%   nfoldxval( data, IDX, @clf_dectree,{},[],[],[],5 );           % decision tree
%   % for multi-class data
%   nfoldxval( data, IDX, @clf_ecoc,{@clf_svm,{'rbf',2^-12},nclasses},[],[],[],6 ); % ECOC
%
% DATESTAMP
%   11-Oct-2005  2:45pm
%
% See also CLF_LDA, CLF_KNN, CLF_SVM, CLF_ECOC

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function CM=nfoldxval( data, IDX, clfinit, clfparams, types, ignoretypes, fname, show )
    if( nargin<5 || isempty(types) ) types=[]; end;
    if( nargin<6 || isempty(ignoretypes) ) ignoretypes=[]; end;
    if( nargin<7 || isempty(fname) ) fname=[]; end;
    if( nargin<8 || isempty(show) ) show=[]; end;
    dispflag = 0;

    %%% divide n data points into n different sets, perform nfoldxval on each
    if( ~iscell(data) && ~iscell(IDX) )
        [n,p]=size(data);  
        IDX=mat2cell(IDX,ones(1,n),1);  
        data=mat2cell(data,ones(1,n),p);
    end
    
    %%% correct format
    data={data{:}}; IDX={IDX{:}};
    nsets = length( data );
    
    %%% remove data points with type specified by ignoretypes
    if( ~isempty(ignoretypes) )
        if(~isempty(types)) 
            keeptypes = setdiff( 1:length(types), ignoretypes );
            types = types( keeptypes ); ntypes = length(types); 
        end;   
        ignoretypes = sort(ignoretypes);
        while( length(ignoretypes)>0 )
            for i=1:nsets 
                keeplocs = (IDX{i}~=ignoretypes(1));
                data{i} = data{i}(keeplocs,:);  IDXi = IDX{i}(keeplocs);
                big=IDXi>ignoretypes(1); IDXi(big)=IDXi(big)-1; IDX{i}=IDXi; 
            end;
            ignoretypes=ignoretypes(2:end)-1;
        end;
    end;

    %%% for binary classes convert to most common form [-1/+1]
    IDXall = cell2mat( permute( IDX, [2 1] ) );
    minIDX = min(IDXall);  maxIDX = max(IDXall); 
    if( minIDX==0 && maxIDX==1 ) 
        for i=1:nsets IDX{i}(IDX{i}==0)=-1; end;
    elseif( minIDX==1 && maxIDX==2 ) 
        for i=1:nsets IDX{i}(IDX{i}==2)=-1; end;
    end;    
    
    %%% create types string for display if not exist
    if( isempty(types) )
        types = unique(IDXall);
        types = int2str2( types );
    end;
    ntypes = length(types);    
    
    %%% optionally visualize data by embedding in 3D space
    if( 0 )
        dataALL = cell2mat( permute( data, [2 1] ) );
        figure(show); show=show+1; 
        visualize_data( dataALL, 3, IDXall+2, types );
    end;
    
    %%% train on n-1 of the sets, test on the remaining; repeat n times
    CM = zeros(ntypes); 
    for testind = 1:nsets

        % get training/testing data sets
        allinds = logical( ones(1,nsets) );
        traininds = allinds; traininds( testind ) = logical(0); 
        train = cell2mat( permute( {data{traininds}}, [2 1] ) );
        test = cell2mat( permute( {data{~traininds}}, [2 1] ) );
        trainIDX = cell2mat( permute( {IDX{traininds}}, [2 1] ) );
        testIDX = cell2mat( permute( {IDX{~traininds}}, [2 1] ) );
        [ntrain p]=size(train);  [ntest p]=size(test);  

        % apply dim reduction [make sure data is well conditioned]
        if( 0 )
            [ U, mu, variances ] = pca( train' );
            maxp = size(U,2) -6; % -20; further reduce? -6
            if( maxp < p ) 
                warning(['reducing dim of data from: ' ...
                    int2str(p) ' to ' int2str(maxp)]);
                train = pca_apply( train', U, mu, variances, maxp )';
                test  = pca_apply( test',  U, mu, variances, maxp )';
                p = maxp;
            end;
        end;
        
        % display update
        if( dispflag )
            msg = ['test set ' int2str(testind)];
            disp([msg '; ntrain=' num2str(ntrain) ', ntest=' num2str(ntest)]);
        end
        if( ntest==0 ) if(dispflag) disp('no test data'); end; continue; end;

        % learn a classifier on train and classify test
        clf = feval( clfinit, p, clfparams{:} );
        clf = feval( clf.fun_train, clf, train, trainIDX );
        testIDXpred = feval( clf.fun_fwd, clf, test );
        CMi = confmatrix( testIDX, testIDXpred, ntypes );
        CM = CM + CMi;
    end
    
    %%% show confusion matrix, optionally save image to file
    if( show ) 
        figure(show); show=show+1; 
        confmatrix_show( CM, types );
        if( isempty(fname) )
            title( clf.type, 'FontSize', 20 );
        else
            title( fname, 'FontSize', 20 );
            print( [fname '.jpg'], '-djpeg' );
        end;
    end;
    
    %%% save data to file
    if( ~isempty(fname) )
        er = 1-sum(diag(CM))/sum(CM(:));
        CMn = CM ./ repmat( sum(CM,2), [1 size(CM,2)] );
        save( fname, 'CM', 'CMn', 'er' );
        if( dispflag ) fprintf(['finished: ' fname '.\n\n\n']); end;
    else
        if( dispflag ) fprintf(['finished.\n\n\n']); end;
    end;

