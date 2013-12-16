function detector = acfTrain( varargin )
% Train aggregate channel features object detector.
%
% Train aggregate channel features (ACF) object detector as described in:
%  P. Dollár, R. Appel, S. Belongie and P. Perona
%   "Fast Feature Pyramids for Object Detection", PAMI 2014.
% The ACF detector is fast (30 fps on a single core) and achieves top
% accuracy on rigid object detection.
%
% Takes a set of parameters opts (described in detail below) and trains a
% detector from start to finish including performing multiple rounds of
% bootstrapping if need be. The return is a struct 'detector' for use with
% acfDetect.m which fully defines a sliding window detector. Training is
% fast (on the INRIA pedestrian dataset training takes ~10 minutes on a
% single core or ~3m using four cores). Taking advantage of parallel
% training requires launching matlabpool (see help for matlabpool). The
% trained detector may be altered in certain ways via acfModify(). Calling
% opts=acfTrain() returns all default options.
%
% (1) Specifying features and model: The channel features are defined by
% 'pPyramid'. See chnsCompute.m and chnsPyramid.m for more details. The
% model dimensions ('modelDs') define the window height and width. The
% padded dimensions ('modelDsPad') define the extended region around object
% candidates that are used for classification. For example, for 100 pixel
% tall pedestrians, typically a 128 pixel tall region is used to make a
% decision. 'pNms' controls non-maximal suppression (see bbNms.m), 'stride'
% controls the window stride, and 'cascThr' and 'cascCal' are the threshold
% and calibration used for the constant soft cascades. Typically, set
% 'cascThr' to -1 and adjust 'cascCal' until the desired recall is reached
% (setting 'cascCal' shifts the final scores output by the detector by the
% given amount). Training alternates between sampling (bootstrapping) and
% training an AdaBoost classifier (clf). 'nWeak' determines the number of
% training stages and number of trees after each stage, e.g. nWeak=[32 128
% 512 2048] defines four stages with the final clf having 2048 trees.
% 'pBoost' specifies parameters for AdaBoost, and 'pBoost.pTree' are the
% decision tree parameters, see adaBoostTrain.m for details. Finally,
% 'seed' is the random seed used and makes results reproducible and 'name'
% defines the location for storing the detector and log file.
%
% (2) Specifying training data location and amount: The training data can
% take on a number of different forms. The positives can be specified using
% either a dir of pre-cropped windows ('posWinDir') or dirs of full images
% ('posImgDir') and ground truth labels ('posGtDir'). The negatives can by
% specified using a dir of pre-cropped windows ('negWinDir'), a dir of full
% images without any positives and from which negatives can be sampled
% ('negImgDir'), and finally if neither 'negWinDir' or 'negImgDir' are
% given negatives are sampled from the images in 'posImgDir' (avoiding the
% positives). For the pre-cropped windows all images must have size at
% least modelDsPad and have the object (of size exactly modelDs) centered.
% 'imreadf' can be used to specify a custom function for loading an image,
% and 'imreadp' are custom additional parameters to imreadf. When sampling
% from full images, 'pLoad' determines how the ground truth is loaded and
% converted to a set of positive bbs (see bbGt>bbLoad). 'nPos' controls the
% total number of positives to sample for training (if nPos=inf the number
% of positives is limited by the training set). 'nNeg' controls the total
% number of negatives to sample and 'nPerNeg' limits the number of
% negatives to sample per image. 'nAccNeg' controls the maximum number of
% negatives that can accumulate over multiple stages of bootstrapping.
% Define 'pJitter' to jitter the positives (see jitterImage.m) and thus
% artificially increase the number of positive training windows. Finally if
% 'winsSave' is true cropped windows are saved to disk as a mat file.
%
% USAGE
%  detector = acfTrain( opts )
%  opts = acfTrain()
%
% INPUTS
%  opts       - parameters (struct or name/value pairs)
%   (1) features and model:
%   .pPyramid   - [{}] params for creating pyramid (see chnsPyramid)
%   .modelDs    - [] model height+width without padding (eg [100 41])
%   .modelDsPad - [] model height+width with padding (eg [128 64])
%   .pNms       - [..] params for non-maximal suppression (see bbNms.m)
%   .stride     - [4] spatial stride between detection windows
%   .cascThr    - [-1] constant cascade threshold (affects speed/accuracy)
%   .cascCal    - [.005] cascade calibration (affects speed/accuracy)
%   .nWeak      - [128] vector defining number weak clfs per stage
%   .pBoost     - [..] parameters for boosting (see adaBoostTrain.m)
%   .seed       - [0] seed for random stream (for reproducibility)
%   .name       - [''] name to prepend to clf and log filenames
%   (2) training data location and amount:
%   .posGtDir   - [''] dir containing ground truth
%   .posImgDir  - [''] dir containing full positive images
%   .negImgDir  - [''] dir containing full negative images
%   .posWinDir  - [''] dir containing cropped positive windows
%   .negWinDir  - [''] dir containing cropped negative windows
%   .imreadf    - [@imread] optional custom function for reading images
%   .imreadp    - [{}] optional custom parameters for imreadf
%   .pLoad      - [..] params for bbGt>bbLoad (see bbGt)
%   .nPos       - [inf] max number of pos windows to sample
%   .nNeg       - [5000] max number of neg windows to sample
%   .nPerNeg    - [25]  max number of neg windows to sample per image
%   .nAccNeg    - [10000] max number of neg windows to accumulate
%   .pJitter    - [{}] params for jittering pos windows (see jitterImage)
%   .winsSave   - [0] if true save cropped windows at each stage to disk
%
% OUTPUTS
%  detector   - trained object detector (modify only via acfModify)
%   .opts       - input parameters used for model training
%   .clf        - learned boosted tree classifier (see adaBoostTrain)
%   .info       - info about channels (see chnsCompute.m)
%
% EXAMPLE
%
% See also acfDetect, acfDemoInria, acfModify, acfTest, chnsCompute,
% chnsPyramid, adaBoostTrain, bbGt, bbNms, jitterImage
%
% Piotr's Image&Video Toolbox      Version 3.25
% Copyright 2013 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% initialize opts struct
opts = initializeOpts( varargin{:} );
if(nargin==0), detector=opts; return; end

% load or initialize detector and begin logging
nm=[opts.name 'Detector.mat']; t=exist(nm,'file');
if(t), if(nargout), t=load(nm); detector=t.detector; end; return; end
t=fileparts(nm); if(~isempty(t) && ~exist(t,'dir')), mkdir(t); end
detector = struct( 'opts',opts, 'clf',[], 'info',[] );
startTrain=clock; nm=[opts.name 'Log.txt'];
if(exist(nm,'file')), diary(nm); diary('off'); delete(nm); end; diary(nm);
RandStream.setGlobalStream(RandStream('mrg32k3a','Seed',opts.seed));

% iterate bootstraping and training
for stage = 0:numel(opts.nWeak)-1
  diary('on'); fprintf([repmat('-',[1 75]) '\n']);
  fprintf('Training stage %i\n',stage); startStage=clock;
  
  % sample positives and compute features
  if( stage==0 )
    Is1 = sampleWins( detector, stage, 1 );
    X1 = chnsCompute1( Is1, opts );
    X1 = reshape(X1,[],size(X1,4))';
  end
  
  % compute info about channels
  if( stage==0 )
    t=ndims(Is1); if(t==3), t=Is1(:,:,1); else t=Is1(:,:,:,1); end
    t=chnsCompute(t,opts.pPyramid.pChns); detector.info=t.info;
  end
  
  % compute lambdas
  if( stage==0 && isempty(opts.pPyramid.lambdas) )
    fprintf('Computing lambdas... '); start=clock;
    ds=size(Is1); ds(1:end-1)=1; Is1=mat2cell2(Is1,ds);
    ls=chnsScaling(opts.pPyramid.pChns,Is1,0);
    ls=round(ls*10^5)/10^5; detector.opts.pPyramid.lambdas=ls;
    fprintf('done (time=%.0fs).\n',etime(clock,start));
  end; clear Is1 ls;
  
  % sample negatives and compute features
  Is0 = sampleWins( detector, stage, 0 );
  X0 = chnsCompute1( Is0, opts ); clear Is0;
  X0 = reshape(X0,[],size(X0,4))';
  
  % accumulate negatives from previous stages
  if( stage>0 )
    n0=size(X0p,1); n1=max(opts.nNeg,opts.nAccNeg)-size(X0,1);
    if(n0>n1 && n1>0), X0p=X0p(randSample(n0,n1),:); end
    if(n0>0 && n1>0), X0=[X0p; X0]; end %#ok<AGROW>
  end; X0p=X0;
  
  % train boosted clf
  detector.opts.pBoost.nWeak = opts.nWeak(stage+1);
  detector.clf = adaBoostTrain(X0,X1,detector.opts.pBoost);
  detector.clf.hs = detector.clf.hs + opts.cascCal;
  
  % update log
  fprintf('Done training stage %i (time=%.0fs).\n',...
    stage,etime(clock,startStage)); diary('off');
end

% save detector
save([opts.name 'Detector.mat'],'detector');

% finalize logging
diary('on'); fprintf([repmat('-',[1 75]) '\n']);
fprintf('Done training (time=%.0fs).\n',...
  etime(clock,startTrain)); diary('off');

end

function opts = initializeOpts( varargin )
% Initialize opts struct.
dfs= { 'pPyramid',{}, 'modelDs',[100 41], 'modelDsPad',[128 64], ...
  'pNms',struct(), 'stride',4, 'cascThr',-1, 'cascCal',.005, ...
  'nWeak',128, 'pBoost', {}, 'seed',0, 'name','', 'posGtDir','', ...
  'posImgDir','', 'negImgDir','', 'posWinDir','', 'negWinDir','', ...
  'imreadf',@imread, 'imreadp',{}, 'pLoad',{}, 'nPos',inf, 'nNeg',5000, ...
  'nPerNeg',25, 'nAccNeg',10000, 'pJitter',{}, 'winsSave',0 };
opts = getPrmDflt(varargin,dfs,1);
% fill in remaining parameters
p=chnsPyramid([],opts.pPyramid); p=p.pPyramid;
p.minDs=opts.modelDs; shrink=p.pChns.shrink;
opts.modelDsPad=ceil(opts.modelDsPad/shrink)*shrink;
p.pad=ceil((opts.modelDsPad-opts.modelDs)/shrink/2)*shrink;
p=chnsPyramid([],p); p=p.pPyramid; p.complete=1;
p.pChns.complete=1; opts.pPyramid=p;
% initialize pNms, pBoost, pBoost.pTree, and pLoad
dfs={ 'type','maxg', 'overlap',.65, 'ovrDnm','min' };
opts.pNms=getPrmDflt(opts.pNms,dfs,-1);
dfs={ 'pTree',{}, 'nWeak',0, 'discrete',1, 'verbose',16 };
opts.pBoost=getPrmDflt(opts.pBoost,dfs,1);
dfs={'nBins',256,'maxDepth',2,'minWeight',.01,'fracFtrs',1,'nThreads',1e5};
opts.pBoost.pTree=getPrmDflt(opts.pBoost.pTree,dfs,1);
opts.pLoad=getPrmDflt(opts.pLoad,{'squarify',{0,1}},-1);
opts.pLoad.squarify{2}=opts.modelDs(2)/opts.modelDs(1);
end

function Is = sampleWins( detector, stage, positive )
% Load or sample windows for training detector.
opts=detector.opts; start=clock;
if( positive ), n=opts.nPos; else n=opts.nNeg; end
if( positive ), crDir=opts.posWinDir; else crDir=opts.negWinDir; end
if( exist(crDir,'dir') && stage==0 )
  % if window directory is specified simply load windows
  fs=bbGt('getFiles',{crDir}); nImg=length(fs); assert(nImg>0);
  if(nImg>n), fs=fs(:,randSample(nImg,n)); end; n=nImg;
  for i=1:n, fs{i}=[{opts.imreadf},fs(i),opts.imreadp]; end
  Is=cell(1,n); parfor i=1:n, Is{i}=feval(fs{i}{:}); end
else
  % sample windows from full images using sampleWins1()
  hasGt=positive||isempty(opts.negImgDir); fs={opts.negImgDir};
  if(hasGt), fs={opts.posImgDir,opts.posGtDir}; end
  fs=bbGt('getFiles',fs); nImg=size(fs,2); assert(nImg>0);
  if(~isinf(n)), fs=fs(:,randperm(nImg)); end; Is=cell(nImg*1000,1);
  tid=ticStatus('Sampling windows',1,30); k=0; i=0; batch=64;
  while( i<nImg && k<n )
    batch=min(batch,nImg-i); Is1=cell(1,batch);
    parfor j=1:batch, ij=i+j;
      I = feval(opts.imreadf,fs{1,ij},opts.imreadp{:}); %#ok<PFBNS>
      gt=[]; if(hasGt), [~,gt]=bbGt('bbLoad',fs{2,ij},opts.pLoad); end
      Is1{j} = sampleWins1( I, gt, detector, stage, positive );
    end
    Is1=[Is1{:}]; k1=length(Is1); Is(k+1:k+k1)=Is1; k=k+k1;
    if(k>n), Is=Is(randSample(k,n)); k=n; end
    i=i+batch; tocStatus(tid,max(i/nImg,k/n));
  end
  Is=Is(1:k); fprintf('Sampled %i windows from %i images.\n',k,i);
end
% optionally jitter positive windows
if(length(Is)<2), Is={}; return; end
nd=ndims(Is{1})+1; Is=cat(nd,Is{:});
if( positive && isstruct(opts.pJitter) )
  opts.pJitter.hasChn=(nd==4); Is=jitterImage(Is,opts.pJitter);
  ds=size(Is); ds(nd)=ds(nd)*ds(nd+1); Is=reshape(Is,ds(1:nd));
end
% make sure dims are divisible by shrink and not smaller than modelDsPad
ds=size(Is); cr=rem(ds(1:2),opts.pPyramid.pChns.shrink); s=floor(cr/2)+1;
e=ceil(cr/2); Is=Is(s(1):end-e(1),s(2):end-e(2),:,:); ds=size(Is);
if(any(ds(1:2)<opts.modelDsPad)), error('Windows too small.'); end
% optionally save windows to disk and update log
nm=[opts.name 'Is' int2str(positive) 'Stage' int2str(stage)];
if( opts.winsSave ), save(nm,'Is','-v7.3'); end
fprintf('Done sampling windows (time=%.0fs).\n',etime(clock,start));
end

function Is = sampleWins1( I, gt, detector, stage, positive )
% Sample windows from I given its ground truth gt.
opts=detector.opts; shrink=opts.pPyramid.pChns.shrink;
modelDs=opts.modelDs; modelDsPad=opts.modelDsPad;
if( positive ), bbs=gt; bbs=bbs(bbs(:,5)==0,:); else
  if( stage==0 )
    % generate candidate bounding boxes in a grid
    [h,w,~]=size(I); h1=modelDs(1); w1=modelDs(2);
    n=opts.nPerNeg; ny=sqrt(n*h/w); nx=n/ny; ny=ceil(ny); nx=ceil(nx);
    [xs,ys]=meshgrid(linspace(1,w-w1,nx),linspace(1,h-h1,ny));
    bbs=[xs(:) ys(:)]; bbs(:,3)=w1; bbs(:,4)=h1; bbs=bbs(1:n,:);
  else
    % run detector to generate candidate bounding boxes
    bbs=acfDetect(I,detector); [~,ord]=sort(bbs(:,5),'descend');
    bbs=bbs(ord(1:min(end,opts.nPerNeg)),1:4);
  end
  if( ~isempty(gt) )
    % discard any candidate negative bb that matches the gt
    n=size(bbs,1); keep=false(1,n);
    for i=1:n, keep(i)=all(bbGt('compOas',bbs(i,:),gt,gt(:,5))<.1); end
    bbs=bbs(keep,:);
  end
end
% grow bbs to a large padded size and finally crop windows
modelDsBig=max(8*shrink,modelDsPad)+max(2,ceil(64/shrink))*shrink;
r=modelDs(2)/modelDs(1); assert(all(abs(bbs(:,3)./bbs(:,4)-r)<1e-5));
r=modelDsBig./modelDs; bbs=bbApply('resize',bbs,r(1),r(2));
Is=bbApply('crop',I,bbs,'replicate',modelDsBig([2 1]));
end

function chns = chnsCompute1( Is, opts )
% Compute single scale channels of dimensions modelDsPad.
if(isempty(Is)), chns=[]; return; end
fprintf('Extracting features... '); start=clock;
pChns=opts.pPyramid.pChns; smooth=opts.pPyramid.smooth;
dsTar=opts.modelDsPad/pChns.shrink; ds=size(Is); ds(1:end-1)=1;
Is=squeeze(mat2cell2(Is,ds)); n=length(Is); chns=cell(1,n);
parfor i=1:n
  C=chnsCompute(Is{i},pChns); C=convTri(cat(3,C.data{:}),smooth);
  ds=size(C); cr=ds(1:2)-dsTar; s=floor(cr/2)+1; e=ceil(cr/2);
  C=C(s(1):end-e(1),s(2):end-e(2),:); chns{i}=C;
end; chns=cat(4,chns{:});
fprintf('done (time=%.0fs).\n',etime(clock,start));
end
