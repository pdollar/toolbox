function [tree,data,err] = binaryTreeTrain( data, varargin )
% Train binary decision tree classifier.
%
% Highly optimized code for training decision trees over binary variables.
% Training a decision stump (depth=1) over 5000 features and 10000 training
% examples takes 70ms on a single core machine and *7ms* with 12 cores and
% OpenMP enabled (OpenMP is enabled by default, see toolboxCompile). This
% code shares similarities with forestTrain.m but is optimized for binary
% labels. Moreover, while forestTrain is meant for training random decision
% forests, this code is tuned for use with boosting (see adaBoostTrain.m).
%
% For more information on how to quickly boost decision trees see:
%   [1] R. Appel, T. Fuchs, P. Dollár, P. Perona; "Quickly Boosting
%   Decision Trees – Pruning Underachieving Features Early," ICML 2013.
% The code here implements a simple brute-force strategy with the option to
% sample features used for training each node for additional speedups.
% Further gains using the ideas from the ICML paper are possible. If you
% use this code please consider citing our ICML paper.
%
% During training each feature is quantized to lie between [0,nBins-1],
% where nBins<=256. Quantization is expensive and should be performed just
% once if training multiple trees. Note that the second output of the
% algorithm is the quantized data, this can be reused in future training.
%
% USAGE
%  [tree,data,err] = binaryTreeTrain( data, [pTree] )
%
% INPUTS
%  data       - data for training tree
%   .X0         - [N0xF] negative feature vectors
%   .X1         - [N1xF] positive feature vectors
%   .wts0       - [N0x1] negative weights
%   .wts1       - [N1x1] positive weights
%   .xMin       - [1xF] optional vals defining feature quantization
%   .xStep      - [1xF] optional vals defining feature quantization
%   .xType      - [] optional original data type for features
%  pTree      - additional params (struct or name/value pairs)
%   .nBins      - [256] maximum number of quanizaton bins (<=256)
%   .maxDepth   - [1] maximum depth of tree
%   .minWeight  - [.01] minimum sample weigth to allow split
%   .fracFtrs   - [1] fraction of features to sample for each node split
%   .nThreads   - [16] max number of computational threads to use
%
% OUTPUTS
%  tree       - learned decision tree model struct w the following fields
%   .fids       - [Kx1] feature ids for each node
%   .thrs       - [Kx1] threshold corresponding to each fid
%   .child      - [Kx1] index of child for each node (1-indexed)
%   .hs         - [Kx1] log ratio (.5*log(p/(1-p)) at each node
%   .weights    - [Kx1] total sample weight at each node
%   .depth      - [Kx1] depth of each node
%  data       - data used for training tree (quantized version of input)
%  err        - decision tree training error
%
% EXAMPLE
%
% See also binaryTreeApply, adaBoostTrain, forestTrain
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.40
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get parameters
dfs={'nBins',256,'maxDepth',1,'minWeight',.01,'fracFtrs',1,'nThreads',16};
[nBins,maxDepth,minWeight,fracFtrs,nThreads]=getPrmDflt(varargin,dfs,1);
assert(nBins<=256);

% get data and normalize weights
dfs={ 'X0','REQ', 'X1','REQ', 'wts0',[], 'wts1',[], ...
  'xMin',[], 'xStep',[], 'xType',[] };
[X0,X1,wts0,wts1,xMin,xStep,xType]=getPrmDflt(data,dfs,1);
[N0,F]=size(X0); [N1,F1]=size(X1); assert(F==F1);
if(isempty(xType)), xMin=zeros(1,F); xStep=ones(1,F); xType=class(X0); end
assert(isfloat(wts0)); if(isempty(wts0)), wts0=ones(N0,1)/N0; end
assert(isfloat(wts1)); if(isempty(wts1)), wts1=ones(N1,1)/N1; end
w=sum(wts0)+sum(wts1); if(abs(w-1)>1e-3), wts0=wts0/w; wts1=wts1/w; end

% quantize data to be between [0,nBins-1] if not already quantized
if( ~isa(X0,'uint8') || ~isa(X1,'uint8') )
  xMin = min(min(X0),min(X1))-.01;
  xMax = max(max(X0),max(X1))+.01;
  xStep = (xMax-xMin) / (nBins-1);
  X0 = uint8(bsxfun(@times,bsxfun(@minus,X0,xMin),1./xStep));
  X1 = uint8(bsxfun(@times,bsxfun(@minus,X1,xMin),1./xStep));
end
data=struct( 'X0',X0, 'X1',X1, 'wts0',wts0, 'wts1',wts1, ...
  'xMin',xMin, 'xStep',xStep, 'xType',xType );

% train decision tree classifier
K=2*(N0+N1); thrs=zeros(K,1,xType);
hs=zeros(K,1,'single'); weights=hs; errs=hs;
fids=zeros(K,1,'uint32'); child=fids; depth=fids;
wtsAll0=cell(K,1); wtsAll0{1}=wts0;
wtsAll1=cell(K,1); wtsAll1{1}=wts1; k=1; K=2;
while( k < K )
  % get node weights and prior
  wts0=wtsAll0{k}; wtsAll0{k}=[]; w0=sum(wts0);
  wts1=wtsAll1{k}; wtsAll1{k}=[]; w1=sum(wts1);
  w=w0+w1; prior=w1/w; weights(k)=w; errs(k)=min(prior,1-prior);
  hs(k)=max(-4,min(4,.5*log(prior/(1-prior))));
  % if nearly pure node or insufficient data don't train split
  if( prior<1e-3||prior>1-1e-3||depth(k)>=maxDepth||w<minWeight )
    k=k+1; continue; end
  % train best stump
  fidsSt=1:F; if(fracFtrs<1), fidsSt=randperm(F,floor(F*fracFtrs)); end
  [errsSt,thrsSt] = binaryTreeTrain1(X0,X1,single(wts0/w),...
    single(wts1/w),nBins,prior,uint32(fidsSt-1),nThreads);
  [~,fid]=min(errsSt); thr=single(thrsSt(fid))+.5; fid=fidsSt(fid);
  % split data and continue
  left0=X0(:,fid)<thr; left1=X1(:,fid)<thr;
  if( (any(left0)||any(left1)) && (any(~left0)||any(~left1)) )
    thr = xMin(fid)+xStep(fid)*thr;
    child(k)=K; fids(k)=fid-1; thrs(k)=thr;
    wtsAll0{K}=wts0.*left0; wtsAll0{K+1}=wts0.*~left0;
    wtsAll1{K}=wts1.*left1; wtsAll1{K+1}=wts1.*~left1;
    depth(K:K+1)=depth(k)+1; K=K+2;
  end; k=k+1;
end; K=K-1;

% create output model struct
tree=struct('fids',fids(1:K),'thrs',thrs(1:K),'child',child(1:K),...
  'hs',hs(1:K),'weights',weights(1:K),'depth',depth(1:K));
if(nargout>=3), err=sum(errs(1:K).*tree.weights.*(tree.child==0)); end

end
