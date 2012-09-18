function forest = forestTrain( data, hs, varargin )
% Train random forest classifier.
%
% Dimensions:
%  M - number trees
%  F - number features
%  N - number input vectors
%  H - number classes
%
% USAGE
%  forest = forestTrain( data, hs, [varargin] )
%
% INPUTS
%  data     - [NxF] N length F feature vectors
%  hs       - [Nx1] target output hs in [1,H]
%  varargin - additional params (struct or name/value pairs)
%   .M        - [1] number of trees to train
%   .N1       - [5*N/M] number of data points for training each tree
%   .F1       - [sqrt(F)] number features to sample for each node split
%   .minCount - [1] minimum number of data points to allow split
%   .maxDepth - [64] maximum depth of tree
%   .dWts     - [] weights used for sampling and weighing each data point
%   .fWts     - [] weights used for sampling features
%
% OUTPUTS
%  forest   - learned forest model struct array w the following fields
%   .fids     - [Mx1] feature ids for each node
%   .thrs     - [Mx1] threshold corresponding to each fid
%   .child    - [Mx1] index of child for each node
%   .distr    - [MxH] prob distribution at each node
%   .count    - [Mx1] number of data points at each node
%   .depth    - [Mx1] depth of each node
%
% EXAMPLE
%  N=10000; H=5; d=2; [xs0,hs0,xs1,hs1]=demoGenData(N,N,H,d,1,1);
%  xs0=single(xs0); xs1=single(xs1);
%  pTrain={'maxDepth',50,'F1',2,'M',150};
%  tic, forest=forestTrain(xs0,hs0,pTrain{:}); toc
%  hsPr0 = forestApply(xs0,forest);
%  hsPr1 = forestApply(xs1,forest);
%  e0=mean(hsPr0~=hs0); e1=mean(hsPr1~=hs1);
%  fprintf('errors trn=%f tst=%f\n',e0,e1); figure(1);
%  subplot(2,2,1); visualizeData(xs0,2,hs0);
%  subplot(2,2,2); visualizeData(xs0,2,hsPr0);
%  subplot(2,2,3); visualizeData(xs1,2,hs1);
%  subplot(2,2,4); visualizeData(xs1,2,hsPr1);
%
% See also forestApply, fernsClfTrain
%
% Piotr's Image&Video Toolbox      Version 3.01
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get additional parameters and fill in remaining parameters
dfs={'M',1,'N1',[],'F1',[],'minCount',1,'maxDepth',64,'dWts',[],'fWts',[]};
[M,N1,F1,minCount,maxDepth,dWts,fWts]=getPrmDflt(varargin,dfs,1);
[N,F]=size(data); assert(length(hs)==N); assert(all(hs>0));
if(isempty(N1)), N1=round(5*N/M); end; N1=min(N,N1);
if(isempty(F1)), F1=round(sqrt(F)); end; F1=min(F,F1);
if(isempty(dWts)), dWts=ones(1,N,'single'); end; dWts=dWts/sum(dWts);
if(isempty(fWts)), fWts=ones(1,F,'single'); end; fWts=fWts/sum(fWts);

% make sure data has correct types
if(~isa(data,'single')), data=single(data); end
if(~isa(hs,'uint32')), hs=uint32(hs); end
if(~isa(fWts,'single')), fWts=single(fWts); end
if(~isa(dWts,'single')), dWts=single(dWts); end

% train M random trees on different subsets of data
for i=1:M
  if(N==N1), data1=data; hs1=hs; dWts1=dWts; else
    d=wswor(dWts,N1,4); data1=data(d,:); hs1=hs(d);
    dWts1=dWts(d); dWts1=dWts1/sum(dWts1);
  end
  tree=treeTrain(data1,hs1,F1,minCount,maxDepth,dWts1,fWts);
  if(i==1), forest=tree(ones(M,1)); else forest(i)=tree; end
end

end

function tree = treeTrain(data,hs,F1,minCount,maxDepth,dWts,fWts)
% Train single random tree.
N=size(data,1); H=max(hs); K=2*N-1;
thrs=zeros(K,1,'single'); distr=zeros(K,H,'single');
fids=zeros(K,1,'uint32'); child=fids; count=fids; depth=fids;
dids=cell(K,1); dids{1}=1:N; k=1; K=2;
while( k < K )
  dids1=dids{k}; hs1=hs(dids1); count(k)=length(dids1);
  if( all(hs1(1)==hs1) )
    % pure node, set distribution to delta function and stop
    distr(k,hs1(1)) = 1;
  elseif( count(k)<=1 || count(k)<=minCount || depth(k)>maxDepth )
    % insufficient data, store distribution and stop
    distr(k,:)=histc(hs1,1:H)/single(count(k));
  else
    % train split and continue
    fids1=wswor(fWts,F1,4); data1=data(dids1,fids1);
    [~,order1]=sort(data1); order1=uint32(order1-1);
    [fid,thr,gini]=forestFindThr(data1,hs1,dWts(dids1),order1,H);
    if( gini<100 )
      fid=fids1(fid); left=data(dids1,fid)<thr;
      child(k)=K; fids(k)=fid-1; thrs(k)=thr;
      dids{K}=dids1(left); dids{K+1}=dids1(~left);
      depth(K:K+1)=depth(k)+1; K=K+2;
    end
    distr(k,:)=histc(hs1,1:H)/single(count(k));
  end
  dids{k}=[]; k=k+1;
end; K=K-1;
% create output model struct
tree=struct('fids',fids(1:K),'thrs',thrs(1:K),'child',child(1:K),...
  'distr',distr(1:K,:),'count',count(1:K),'depth',depth(1:K));
end

function ids = wswor( prob, N, trials )
% Fast weighted sample without replacement. Alternative to:
%  ids=datasample(1:length(prob),N,'weights',prob,'replace',false);
M=length(prob); assert(N<=M); if(N==M), ids=1:N; return; end
if(all(prob(1)==prob)), ids=randperm(M,N); return; end
cumprob=min([0 cumsum(prob)],1); assert(abs(cumprob(end)-1)<.01);
cumprob(end)=1; [~,ids]=histc(rand(N*trials,1),cumprob);
[s,ord]=sort(ids); K(ord)=[1; diff(s)]~=0; ids=ids(K);
if(length(ids)<N), ids=wswor(cumprob,N,trials*2); end
ids=ids(1:N)';
end
