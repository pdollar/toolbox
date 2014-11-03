function acfSweeps
% Parameter sweeps for ACF pedestrian detector.
%
% Running the parameter sweeps requires altering internal flags.
% The sweeps are not well documented, use at your own discretion.
%
% Piotr's Computer Vision Matlab Toolbox      Version NEW
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% specify type and location of cluster (see fevalDistr.m)
rtDir=[fileparts(fileparts(fileparts(mfilename('fullpath')))) '/data/'];
pDistr={'type','parfor'}; if(0), matlabpool('open',11); end

% define all parameter sweeps
expNms = {'FtrsColorSpace','FtrsChnTypes','FtrsGradColorChn',...
  'FtrsGradNormRad','FtrsGradNormConst','FtrsGradOrients',...
  'FtrsGradSoftBins','FtrsSmoothIm','FtrsSmoothChns','FtrsShrink',...
  'DetModelDs','DetModelDsPad','DetStride','DetNumOctaves',...
  'DetNumApprox','DetLambda','DetCascThr','DetCascCal','DetNmsThr',...
  'TrnNumWeak','TrnNumBoot','TrnDepth','TrnNumBins','TrnFracFtrs',...
  'DataNumPos','DataNumNeg','DataNumNegAcc','DataNumNegPer',...
  'DataNumPosStump','DataJitterTran','DataJitterRot'};
expNms=expNms(:); T = 10;
[opts,lgd,lbl]=createExp(rtDir,expNms);

% run training and testing jobs
[jobsTrn,jobsTst] = createJobs( rtDir, opts, T ); N=length(expNms);
fprintf('nTrain = %i; nTest = %i\n',length(jobsTrn),length(jobsTst));
tic, s=fevalDistr('acfTrain',jobsTrn,pDistr); assert(s==1); toc
tic, s=fevalDistr('acfTest',jobsTst,pDistr); assert(s==1); toc

% create plots for all experiments
for e=1:N, plotExps(rtDir,expNms{e},opts{e},lgd{e},lbl{e},T); end

end

function plotExps( rtDir, expNm, opts, lgd, lbl, T )
% data location and parameters for plotting
plDir=[rtDir 'sweeps/plots/']; if(~exist(plDir,'dir')), mkdir(plDir); end
diary([plDir 'sweeps.txt']); disp([expNm ' [' lbl ']']); N=length(lgd);
pLoad=struct('squarify',{{3,.41}},'hRng',[0 inf]);
pTest=struct('name','', 'imgDir',[rtDir 'Inria/test/pos'],...
  'gtDir',[rtDir 'Inria/test/posGt'], 'pLoad',pLoad);
pTest=repmat(pTest,N,T); for e=1:N, for t=1:T,
    pTest(e,t).name=[opts(e).name 'T' int2str2(t,2)]; end; end
% get all miss rates and display error
miss=zeros(N,T); parfor e=1:N*T, miss(e)=acfTest(pTest(e)); end
stds=std(miss,0,2); R=mean(miss,2); msg=' %.2f +/- %.2f  [%s]\n';
for e=1:N, fprintf(msg,R(e)*100,stds(e)*100,lgd{e}); end
% plot sweeps
figPrp = {'Units','Pixels','Position',[800 600 800 400]};
figure(1); clf; set(1,figPrp{:}); set(gca,'FontSize',24); clr=[0 .69 .94];
pPl1={'LineWidth',3,'MarkerSize',15,'Color',clr,'MarkerFaceColor',clr};
pPl2=pPl1; clr=[1 .75 0]; pPl2{6}=clr; pPl2{8}=clr;
for e=1:N, if(lgd{e}(end)=='*'), def=e; end; end; lgd{def}(end)=[];
plot(R,'-d',pPl1{:}); hold on; plot(def,R(def),'d',pPl2{:}); e=.001;
ylabel('MR'); axis([.5 N+.5 min([R; .15]) max([R; .3])+e]);
if(isempty(lbl)), imLabel(lgd,'bottom',30,{'FontSize',24}); lgd=[]; end
xlabel(lbl); set(gca,'XTick',1:N,'XTickLabel',lgd);
% save plot
fFig=[plDir expNm]; diary('off');
for t=1:25, try savefig(fFig,1,'png'); break; catch, pause(1), end; end
end

function [jobsTrn,jobsTst] = createJobs( rtDir, opts, T )
% Prepare all jobs (one train and one test job per set of opts).
opts=[opts{:}]; N=length(opts); NT=N*T;
opts=repmat(opts,1,T); nms=cell(1,NT);
jobsTrn=cell(1,NT); doneTrn=zeros(1,NT);
jobsTst=cell(1,NT); doneTst=zeros(1,NT);
pLoad=struct('squarify',{{3,.41}},'hRng',[0 inf]);
pTest=struct('name','', 'imgDir',[rtDir 'Inria/test/pos'],...
  'gtDir',[rtDir 'Inria/test/posGt'], 'pLoad',pLoad);
for e=1:NT
  t=ceil(e/N); opts(e).seed=(t-1)*100000+1;
  nm=[opts(e).name 'T' int2str2(t,2)];
  opts(e).name=nm; pTest.name=nm; nms{e}=nm;
  doneTrn(e)=exist([nm 'Detector.mat'],'file')==2; jobsTrn{e}={opts(e)};
  doneTst(e)=exist([nm 'Dets.txt'],'file')==2; jobsTst{e}={pTest};
end
[~,kp]=unique(nms,'stable');
doneTrn=doneTrn(kp); jobsTrn=jobsTrn(kp); jobsTrn=jobsTrn(~doneTrn);
doneTst=doneTst(kp); jobsTst=jobsTst(kp); jobsTst=jobsTst(~doneTst);
end

function [opts,lgd,lbl] = createExp( rtDir, expNm )

% if expNm is a cell, call recursively and return
if( iscell(expNm) )
  N=length(expNm); opts=cell(1,N); lgd=cell(1,N); lbl=lgd;
  for e=1:N, [opts{e},lgd{e},lbl{e}]=createExp(rtDir,expNm{e}); end; return
end

% default params for detectorTrain.m
dataDir=[rtDir 'Inria/'];
opts=acfTrain(); opts.modelDs=[100 41]; opts.modelDsPad=[128 64];
opts.posGtDir=[dataDir 'train/posGt']; opts.nWeak=[32 128 512 2048];
opts.posImgDir=[dataDir 'train/pos']; opts.pJitter=struct('flip',1);
opts.negImgDir=[dataDir 'train/neg']; opts.pBoost.pTree.fracFtrs=1/16;
if(~exist([rtDir 'sweeps/res/'],'dir')), mkdir([rtDir 'sweeps/res/']); end
opts.pBoost.pTree.nThreads=1;

% setup experiments (N sets of params)
optsDefault=opts; N=100; lgd=cell(1,N); ss=lgd; lbl=''; O=ones(1,N);
pChns=opts.pPyramid.pChns(O); pPyramid=opts.pPyramid(O); opts=opts(O);
switch expNm
  case 'FtrsColorSpace'
    N=8; clrs={'Gray','rgb','hsv','luv'};
    for e=1:N, pChns(e).pColor.colorSpace=clrs{mod(e-1,4)+1}; end
    for e=5:N, pChns(e).pGradMag.enabled=0; end
    for e=5:N, pChns(e).pGradHist.enabled=0; end
    ss=[clrs clrs]; for e=1:4, ss{e}=[ss{e} '+G+H']; end
    ss=upper(ss); lgd=ss;
  case 'FtrsChnTypes'
    nms={'LUV+','G+','H+'}; N=7;
    for e=1:N
      en=false(1,3); for i=1:3, en(i)=bitget(uint8(e),i); end
      pChns(e).pColor.enabled=en(1); pChns(e).pGradMag.enabled=en(2);
      pChns(e).pGradHist.enabled=en(3);
      nm=[nms{en}]; nm=nm(1:end-1); lgd{e}=nm; ss{e}=nm;
    end
  case 'FtrsGradColorChn'
    lbl='gradient color channel';
    N=4; ss={'Max','L','U','V'}; lgd=ss;
    for e=1:N, pChns(e).pGradMag.colorChn=e-1; end
  case 'FtrsGradNormRad'
    lbl='norm radius';
    vs=[0 1 2 5 10]; N=length(vs);
    for e=1:N, pChns(e).pGradMag.normRad=vs(e); end
  case 'FtrsGradNormConst'
    lbl='norm constant x 10^3';
    vs=[1 2 5 10 20 50 100]; N=length(vs);
    for e=1:N, pChns(e).pGradMag.normConst=vs(e)/1000; end
  case 'FtrsGradOrients'
    lbl='# orientations';
    vs=[2 4 6 8 10 12]; N=length(vs);
    for e=1:N, pChns(e).pGradHist.nOrients=vs(e); end
  case 'FtrsGradSoftBins'
    lbl='use soft bins';
    vs=[0 1]; N=length(vs);
    for e=1:N, pChns(e).pGradHist.softBin=vs(e); end
  case 'FtrsSmoothIm'
    lbl='image smooth radius';
    vs=[0 50 100 200]; N=length(vs);
    for e=1:N, pChns(e).pColor.smooth=vs(e)/100; end
    for e=1:N, lgd{e}=num2str(vs(e)/100); end
  case 'FtrsSmoothChns'
    lbl='channel smooth radius';
    vs=[0 50 100 200]; N=length(vs);
    for e=1:N, pPyramid(e).smooth=vs(e)/100; end
    for e=1:N, lgd{e}=num2str(vs(e)/100); end
  case 'FtrsShrink'
    lbl='channel shrink';
    vs=2.^(1:4); N=length(vs);
    for e=1:N, pChns(e).shrink=vs(e); end
  case 'DetModelDs'
    lbl='model height';
    rs=1.1.^(-2:2); vs=round(100*rs); ws=round(41*rs); N=length(vs);
    for e=1:N, opts(e).modelDs=[vs(e) ws(e)]; end
    for e=1:N, opts(e).modelDsPad=opts(e).modelDs+[28 23]; end
  case 'DetModelDsPad'
    lbl='padded model height';
    rs=1.1.^(-2:2); vs=round(128*rs); ws=round(64*rs); N=length(vs);
    for e=1:N, opts(e).modelDsPad=[vs(e) ws(e)]; end
  case 'DetStride'
    lbl='detector stride';
    vs=4:4:16; N=length(vs);
    for e=1:N, opts(e).stride=vs(e); end
  case 'DetNumOctaves'
    lbl='# scales per octave';
    vs=2.^(0:5); N=length(vs);
    for e=1:N, pPyramid(e).nPerOct=vs(e); pPyramid(e).nApprox=vs(e)-1; end
  case 'DetNumApprox'
    lbl='# approx scales';
    vs=2.^(0:5)-1; N=length(vs);
    for e=1:N, pPyramid(e).nApprox=vs(e); end
  case 'DetLambda'
    lbl='lambda x 100';
    vs=-45:15:70; N=length(vs);
    for e=[1:4 6:N], pPyramid(e).lambdas=[0 vs(e) vs(e)]/100; end
    for e=1:N, lgd{e}=int2str(vs(e)); end; vs=vs+100;
  case 'DetCascThr'
    lbl='cascade threshold';
    vs=[-.5 -1 -2 -5 -10]; N=length(vs);
    for e=1:N, opts(e).cascThr=vs(e); end
    for e=1:N, lgd{e}=num2str(vs(e)); end; vs=vs*-10;
  case 'DetCascCal'
    lbl='cascade offset x 10^4';
    vs=[5 10 20 50 100 200 500]; N=length(vs);
    for e=1:N, opts(e).cascCal=vs(e)/1e4; end
  case 'DetNmsThr'
    lbl='nms overlap';
    vs=25:10:95; N=length(vs);
    for e=1:N, opts(e).pNms.overlap=vs(e)/1e2; end
    for e=1:N, lgd{e}=['.' num2str(vs(e))]; end
  case 'TrnNumWeak'
    lbl='# decision trees / x';
    vs=2.^(0:3); N=length(vs);
    for e=1:N, opts(e).nWeak=opts(e).nWeak/vs(e); end
  case 'TrnNumBoot'
    lbl='bootstrap schedule';
    vs={5:1:11,5:2:11,3:1:11,3:2:11}; N=length(vs);
    ss={'5-1-11','5-2-11','3-1-11','3-2-11'}; lgd=ss;
    for e=1:N, opts(e).nWeak=2.^vs{e}; end
  case 'TrnDepth'
    lbl='tree depth';
    vs=1:5; N=length(vs);
    for e=1:N, opts(e).pBoost.pTree.maxDepth=vs(e); end
  case 'TrnNumBins'
    lbl='# bins';
    vs=2.^(4:8); N=length(vs);
    for e=1:N, opts(e).pBoost.pTree.nBins=vs(e); end
  case 'TrnFracFtrs'
    lbl='fraction features';
    vs=2.^(1:8); N=length(vs);
    for e=1:N, opts(e).pBoost.pTree.fracFtrs=1/vs(e); end
  case 'DataNumPos'
    lbl='# pos examples';
    vs=[2.^(6:9) inf]; N=length(vs);
    for e=1:N-1, opts(e).nPos=vs(e); end
  case 'DataNumNeg'
    lbl='# neg examples';
    vs=[5 10 25 50 100 250]*100; N=length(vs);
    for e=1:N, opts(e).nNeg=vs(e); end
  case 'DataNumNegAcc'
    lbl='# neg examples total';
    vs=[25 50 100 250 500]*100; N=length(vs);
    for e=1:N, opts(e).nAccNeg=vs(e); end
  case 'DataNumNegPer'
    lbl='# neg example / image';
    vs=[5 10 25 50 100]; N=length(vs);
    for e=1:N, opts(e).nPerNeg=vs(e); end
  case 'DataNumPosStump'
    lbl='# pos examples (stumps)';
    vs=[2.^(6:9) 1237 1237]; N=length(vs); lgd{N}='1237*';
    for e=1:N-1, opts(e).nPos=vs(e); opts(e).pBoost.pTree.maxDepth=1; end
  case 'DataJitterTran'
    lbl='translational jitter';
    vs=[0 1 2 4]; N=length(vs); opts(1).pJitter=struct('flip',1);
    for e=2:N, opts(e).pJitter=struct('flip',1,'nTrn',3,'mTrn',vs(e)); end
    for e=1:N, lgd{e}=['+/-' int2str(vs(e))]; end
  case 'DataJitterRot'
    lbl='rotational jitter';
    vs=[0 2 4 8]; N=length(vs);
    for e=2:N, opts(e).pJitter=struct('flip',1,'nPhi',3,'mPhi',vs(e)); end
    for e=1:N, lgd{e}=['+/-' int2str(vs(e))]; end
  otherwise, error('invalid exp: %s',expNm);
end

% produce final set of opts and find default opts
for e=1:N, if(isempty(lgd{e})), lgd{e}=int2str(vs(e)); end; end
for e=1:N, if(isempty(ss{e})), ss{e}=int2str2(vs(e),5); end; end
O=1:N; opts=opts(O); lgd=lgd(O); ss=ss(O); d=0;
for e=1:N, pPyramid(e).pChns=pChns(e); opts(e).pPyramid=pPyramid(e); end
for e=1:N, if(isequal(optsDefault,opts(e))), d=e; break; end; end
if(d==0), disp(expNm); assert(false); end
for e=1:N, opts(e).name=[rtDir 'sweeps/res/' expNm ss{e}]; end
lgd{d}=[lgd{d} '*']; opts(d).name=[rtDir 'sweeps/res/Default'];
if(0), disp([ss' lgd']'); end

end
