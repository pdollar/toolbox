function detector = acfModify( detector, varargin )
% Modify aggregate channel features object detector.
%
% Takes an object detector trained by acfTrain() and modifies it. Only
% certain modifications are allowed to the detector and the detector should
% never be modified directly (this may cause the detector to be invalid and
% cause segmentation faults). Any valid modification to a detector after it
% is trained should be performed using acfModify().
%
% The parameters 'nPerOct', 'nOctUp', 'nApprox', 'lambdas', 'pad', 'minDs'
% modify the channel feature pyramid created (see help of chnsPyramid.m for
% more details) and primarily control the scales used. The parameters
% 'pNms', 'stride', 'cascThr' and 'cascCal' modify the detector behavior
% (see help of acfTrain.m for more details). Finally, 'rescale' can be
% used to rescale the trained detector (this change is irreversible).
%
% USAGE
%  detector = acfModify( detector, pModify )
%
% INPUTS
%  detector   - detector trained via acfTrain
%  pModify    - parameters (struct or name/value pairs)
%   .nPerOct    - [] number of scales per octave
%   .nOctUp     - [] number of upsampled octaves to compute
%   .nApprox    - [] number of approx. scales to use
%   .lambdas    - [] coefficients for power law scaling (see BMVC10)
%   .pad        - [] amount to pad channels (along T/B and L/R)
%   .minDs      - [] minimum image size for channel computation
%   .pNms       - [] params for non-maximal suppression (see bbNms.m)
%   .stride     - [] spatial stride between detection windows
%   .cascThr    - [] constant cascade threshold (affects speed/accuracy)
%   .cascCal    - [] cascade calibration (affects speed/accuracy)
%   .rescale    - [] rescale entire detector by given ratio
%
% OUTPUTS
%  detector   - modified object detector
%
% EXAMPLE
%
% See also chnsPyramid, bbNms, acfTrain, acfDetect
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.20
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get parameters (and copy to detector and pPyramid structs)
opts=detector.opts; p=opts.pPyramid;
dfs={ 'nPerOct',p.nPerOct, 'nOctUp',p.nOctUp, 'nApprox',p.nApprox, ...
  'lambdas',p.lambdas, 'pad',p.pad, 'minDs',p.minDs, 'pNms',opts.pNms, ...
  'stride',opts.stride,'cascThr',opts.cascThr,'cascCal',0,'rescale',1 };
[p.nPerOct,p.nOctUp,p.nApprox,p.lambdas,p.pad,p.minDs,opts.pNms,...
  opts.stride,opts.cascThr,cascCal,rescale] = getPrmDflt(varargin,dfs,1);

% finalize pPyramid and opts
p.complete=0; p.pChns.complete=0; p=chnsPyramid([],p); p=p.pPyramid;
p.complete=1; p.pChns.complete=1; shrink=p.pChns.shrink;
opts.stride=max(1,round(opts.stride/shrink))*shrink;
opts.pPyramid=p; detector.opts=opts;

% calibrate and rescale detector
detector.clf.hs = detector.clf.hs+cascCal;
if(rescale~=1), detector=detectorRescale(detector,rescale); end

end

function detector = detectorRescale( detector, rescale )
% Rescale detector by ratio rescale.
opts=detector.opts; shrink=opts.pPyramid.pChns.shrink;
bh=opts.modelDsPad(1)/shrink; bw=opts.modelDsPad(2)/shrink;
opts.stride=max(1,round(opts.stride*rescale/shrink))*shrink;
modelDsPad=round(opts.modelDsPad*rescale/shrink)*shrink;
rescale=modelDsPad./opts.modelDsPad; opts.modelDsPad=modelDsPad;
opts.modelDs=round(opts.modelDs.*rescale); detector.opts=opts;
bh1=opts.modelDsPad(1)/shrink; bw1=opts.modelDsPad(2)/shrink;
% move 0-indexed (x,y) location of each lookup feature
clf=detector.clf; fids=clf.fids; is=find(clf.child>0);
fids=double(fids(is)); n=length(fids); loc=zeros(n,3);
loc(:,3)=floor(fids/bh/bw); fids=fids-loc(:,3)*bh*bw;
loc(:,2)=floor(fids/bh); fids=fids-loc(:,2)*bh; loc(:,1)=fids;
loc(:,1)=min(bh1-1,round(loc(:,1)*rescale(1)));
loc(:,2)=min(bw1-1,round(loc(:,2)*rescale(2)));
fids = loc(:,3)*bh1*bw1 + loc(:,2)*bh1 + loc(:,1);
clf.fids(is)=int32(fids);
% rescale thrs for all features (fpdw trick)
nChns=[detector.info.nChns]; assert(max(loc(:,3))<sum(nChns));
k=[]; for i=1:length(nChns), k=[k ones(1,nChns(i))*i]; end %#ok<AGROW>
lambdas=opts.pPyramid.lambdas; lambdas=sqrt(prod(rescale)).^-lambdas(k);
clf.thrs(is)=clf.thrs(is).*lambdas(loc(:,3)+1)'; detector.clf=clf;
end
