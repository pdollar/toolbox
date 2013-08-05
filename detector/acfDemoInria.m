% Demo for aggregate channel features object detector on Inria dataset.
%
% (1) Download data and helper routines from Caltech Peds Website
%  www.vision.caltech.edu/Image_Datasets/CaltechPedestrians/
%  (1a) Download INRIA files: set00.tar, set01.tar, and annotations.zip
%  (1b) Copy above three files to dataDir/ and untar/unzip contents
%  (1c) Download evaluation code (routines necessary for extracting images)
% (2) Set dataDir/ variable below to point to location of INRIA data.
% (3) Launch "matlabpool open" for faster training if available.
% (4) Run demo script and enjoy your newly minted fast ped detector!
%
% Note: pre-trained model files are provided (delete to re-train).
% Re-training may give slightly variable results on different machines.
%
% Piotr's Image&Video Toolbox      Version 3.22
% Copyright 2013 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

%% extract training and testing images and ground truth
dataDir = 'D:\code\research\detectorAcf\data\Inria\';
for s=1:2
  if(s==1), set='00'; type='train'; else set='01'; type='test'; end
  if(exist([dataDir type '/posGt'],'dir')), continue; end
  seqIo([dataDir 'set' set '/V000'],'toImgs',[dataDir type '/pos']);
  seqIo([dataDir 'set' set '/V001'],'toImgs',[dataDir type '/neg']);
  V=vbb('vbbLoad',[dataDir 'annotations/set' set '/V000']);
  vbb('vbbToFiles',V,[dataDir type '/posGt']);
end

%% set up opts for training detector (see acfTrain)
opts=acfTrain(); opts.modelDs=[100 41]; opts.modelDsPad=[128 64];
opts.posGtDir=[dataDir 'train/posGt']; opts.nWeak=[32 128 512 2048];
opts.posImgDir=[dataDir 'train/pos']; opts.pJitter=struct('flip',1);
opts.negImgDir=[dataDir 'train/neg']; opts.pBoost.pTree.fracFtrs=1/16;
opts.pLoad={'squarify',{3,.41}}; opts.name='models/AcfInria';

%% train detector (see acfTrain)
detector = acfTrain( opts );

%% modify detector (see acfModify)
detector = acfModify(detector,'cascThr',-1,'cascCal',0);

%% run detector on a sample image (see acfDetect)
imgNms=bbGt('getFiles',{[dataDir 'test/pos']});
I=imread(imgNms{1}); tic, bbs=acfDetect(I,detector); toc
figure(1); im(I); bbApply('draw',bbs); pause(.1);

%% test detector and plot roc (see acfTest)
[miss,~,gt,dt]=acfTest('name',opts.name,'imgDir',[dataDir 'test/pos'],...
  'gtDir',[dataDir 'test/posGt'],'pLoad',opts.pLoad,'show',2);

%% optional timing test for detector (should be ~30 fps)
if( 0 )
  detector1=acfModify(detector,'pad',[0 0]); n=60; Is=cell(1,n);
  for i=1:n, Is{i}=imResample(imread(imgNms{i}),[480 640]); end
  tic, for i=1:n, acfDetect(Is{i},detector1); end;
  fprintf('Detector runs at %.2f fps on 640x480 images.\n',n/toc);
end

%% optionally show top false positives ('type' can be 'fp','fn','tp','dt')
if( 0 ), bbGt('cropRes',gt,dt,imgNms,'type','fn','n',50,...
    'show',3,'dims',opts.modelDs([2 1])); end
