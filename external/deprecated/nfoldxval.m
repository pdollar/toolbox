function CM=nfoldxval( data, IDX, clfInit, clfparams, ...
  types, ignoreT, fname, show )
% Runs n-fold cross validation on data with a given classifier.
%
% Given n separate labeled data sets, trains classifier using n-1 data
% sets, test on remaining one.  Average results over all n such runs.
% Shows overall results in average confusion matrix.
%
% The classifier is passed in as a parameter.  For this to work the
% classifier (clf) must follow certain conventions.  The conventions are:
%  1) To initialize the clf ('p' is the dimension of the data):
%     clf = clfInit( p, clfparams{:} )
%  2) clf must point to 2 functions for training and applying it:
%     clf.funTrain    and   clf.funFwd
%  3) For training the following will be called:
%     clf = clf.funTrain( clf, X, Y );
%  4) For testing the following will be called:
%     pred = clf.funFwd( clf, Xtest );
% The format for X is nxp where there are n data points and p is their
% dimension. The format for Y is nx1.
%
% Given data in a cell array, to string out into single array:
%  IDX = cell2mat(permute(IDX,[2 1]));
%  data = cell2mat(permute(data,[2 1]));
% For a simple, small dataset, can do leave one out clf as follows:
%  [n,p]=size(data); IDX=mat2cell(IDX,ones(1,n),1);
%  data=mat2cell(data,ones(1,n),p);
% Overall error can be calculated via:
%   er = 1-sum(diag(CM))/sum(CM(:))
% Normalized confusion matrix can be calculated via:
%   CMn = CM ./ repmat( sum(CM,2), [1 size(CM,2)] );
%
% USAGE
%  CM=nfoldxval( data, IDX, clfInit, clfparams, ...
%                [types], [ignoreT], [fname], [show] )
% INPUTS
%  data        - cell array of (n x p) arrays each of n samples of dim p
%  IDX         - cell array of (n x 1) arrays each of n labels
%  clfInit     - classifier initialization function
%  clfparams   - classifier parameters
%  types       - [] cell array of string labels for types
%  ignoreT     - [] array of types to ignore {eg: [1 4 5]}.
%  fname       - [] specify a file to save CM to, as well as image
%  show        - [] will display results in figure(show)
%
% OUTPUTS
%  CM          - confusion matrix
%
% EXAMPLE
%  load clfData;
%  %%% 2 class
%  nfoldxval( data, IDX, @clfLda,{'linear'}, [],[],[],1 );   % LDA
%  nfoldxval( data, IDX, @clfKnn,{4},[],[],[],2 );           % 4 kNN
%  nfoldxval( data, IDX, @clfSvm,{'poly',2},[],[],[],3 );    % poly SVM
%  nfoldxval( data, IDX, @clfSvm,{'rbf',2^-12},[],[],[],4 ); % rbf SVM
%  nfoldxval( data, IDX, @clfDecTree,{},[],[],[],5 );        % dec. tree
%  %%% multiclass
%  clfparams = {@clfSvm,{'rbf',2^-12},nclasses};
%  nfoldxval( data, IDX, @clfEcoc,clfparams,[],[],[],6 );    % ECOC
%
% See also CLFKNN, CLFLDA, CLFSVM, CLFECOC, CLFDECTREE, DEMOCLASSIFY
%
% Piotr's Image&Video Toolbox      Version 2.30
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<5 || isempty(types) ); types=[]; end
if( nargin<6 || isempty(ignoreT) ); ignoreT=[]; end
if( nargin<7 || isempty(fname) ); fname=[]; end
if( nargin<8 || isempty(show) ); show=[]; end
dispflag = 0;

%%% divide n data points into n different sets, perform nfoldxval on each
if( ~iscell(data) && ~iscell(IDX) )
  [n,p]=size(data);
  IDX=mat2cell(IDX,ones(1,n),1); %#ok<MMTC>
  data=mat2cell(data,ones(1,n),p);
end

%%% correct format
data={data{:}}; IDX={IDX{:}}; %#ok<CCAT>
nsets = length( data );

%%% remove data points with type specified by ignoreT
if( ~isempty(ignoreT) )
  if(~isempty(types))
    keeptypes = setdiff( 1:length(types), ignoreT );
    types = types( keeptypes ); ntypes = length(types);  %#ok<NASGU>
  end;
  ignoreT = sort(ignoreT);
  while( ~isempty(ignoreT) )
    for i=1:nsets
      keeplocs = (IDX{i}~=ignoreT(1));
      data{i} = data{i}(keeplocs,:);  IDXi = IDX{i}(keeplocs);
      big=IDXi>ignoreT(1); IDXi(big)=IDXi(big)-1; IDX{i}=IDXi;
    end;
    ignoreT=ignoreT(2:end)-1;
  end;
end;

%%% for binary classes convert to most common form [-1/+1]
IDXall = cell2mat( permute( IDX, [2 1] ) );
minIDX = min(IDXall);  maxIDX = max(IDXall);
if( minIDX==0 && maxIDX==1 )
  for i=1:nsets; IDX{i}(IDX{i}==0)=-1; end
elseif( minIDX==1 && maxIDX==2 )
  for i=1:nsets; IDX{i}(IDX{i}==2)=-1; end
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
  visualizeData( dataALL, 3, IDXall+2, types );
end;

%%% train on n-1 of the sets, test on the remaining; repeat n times
CM = zeros(ntypes);
for testind = 1:nsets

  % get training/testing data sets
  allinds = true(1,nsets);
  traininds = allinds; traininds( testind ) = false;
  train = cell2mat( permute( {data{traininds}}, [2 1] ) );
  test = cell2mat( permute( {data{~traininds}}, [2 1] ) );
  trainIDX = cell2mat( permute( {IDX{traininds}}, [2 1] ) );
  testIDX = cell2mat( permute( {IDX{~traininds}}, [2 1] ) );
  nTrain=size(train,1);  [nTest p]=size(test);

  % apply dim reduction [make sure data is well conditioned]
  if( 0 )
    [ U, mu ] = pca( train' );
    maxp = size(U,2) -6; % -20; further reduce? -6
    if( maxp < p )
      warning(['reducing dim of data from: ' ...
        int2str(p) ' to ' int2str(maxp)]); %#ok<WNTAG>
      train = pcaApply( train', U, mu, maxp )';
      test  = pcaApply( test',  U, mu, maxp )';
      p = maxp;
    end
  end

  % display update
  if( dispflag )
    msg = ['test set ' int2str(testind)];
    disp([msg '; nTrain=' num2str(nTrain) ', nTest=' num2str(nTest)]);
  end
  if( nTest==0 ); if(dispflag); disp('no test data'); end; continue; end

  % learn a classifier on train and classify test
  clf = feval( clfInit, p, clfparams{:} );
  clf = feval( clf.funTrain, clf, train, trainIDX );
  testIDXpred = feval( clf.funFwd, clf, test );
  CMi = confMatrix( testIDX, testIDXpred, ntypes );
  CM = CM + CMi;
end

%%% show confusion matrix, optionally save image to file
if( show )
  figure(show); %show=show+1;
  confMatrixShow( CM, types );
  if( isempty(fname) )
    title( clf.type, 'FontSize', 20 );
  else
    title( fname, 'FontSize', 20 );
    print( [fname '.jpg'], '-djpeg' );
  end
end

%%% save data to file
if( ~isempty(fname) )
  er = 1-sum(diag(CM))/sum(CM(:)); %#ok<NASGU>
  CMn = CM ./ repmat( sum(CM,2), [1 size(CM,2)] ); %#ok<NASGU>
  save( fname, 'CM', 'CMn', 'er' );
  if( dispflag ); fprintf(['finished: ' fname '.\n\n\n']); end
else
  if( dispflag ); fprintf('finished.\n\n\n'); end
end
