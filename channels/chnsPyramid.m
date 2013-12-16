function pyramid = chnsPyramid( I, varargin )
% Compute channel feature pyramid given an input image.
%
% While chnsCompute() computes channel features at a single scale,
% chnsPyramid() calls chnsCompute() multiple times on different scale
% images to create a scale-space pyramid of channel features.
%
% In its simplest form, chnsPyramid() first creates an image pyramid, then
% calls chnsCompute() with the specified "pChns" on each scale of the image
% pyramid. The parameter "nPerOct" determines the number of scales per
% octave in the image pyramid (an octave is the set of scales up to half of
% the initial scale), a typical value is nPerOct=8 in which case each scale
% in the pyramid is 2^(-1/8)~=.917 times the size of the previous. The
% smallest scale of the pyramid is determined by "minDs", once either image
% dimension in the resized image falls below minDs, pyramid creation stops.
% The largest scale in the pyramid is determined by "nOctUp" which
% determines the number of octaves to compute above the original scale.
%
% While calling chnsCompute() on each image scale works, it is unnecessary.
% For a broad family of features, including gradient histograms and all
% channel types tested, the feature responses computed at a single scale
% can be used to approximate feature responses at nearby scales. The
% approximation is accurate at least within an entire scale octave. For
% details and to understand why this unexpected result holds, please see:
%   P. Dollár, R. Appel, S. Belongie and P. Perona
%   "Fast Feature Pyramids for Object Detection", PAMI 2014.
%
% The parameter "nApprox" determines how many intermediate scales are
% approximated using the techniques described in the above paper. Roughly
% speaking, channels at approximated scales are computed by taking the
% corresponding channel at the nearest true scale (computed w chnsCompute)
% and resampling and re-normalizing it appropriately. For example, if
% nPerOct=8 and nApprox=7, then the 7 intermediate scales are approximated
% and only power of two scales are actually computed (using chnsCompute).
% The parameter "lambdas" determines how the channels are normalized (see
% the above paper). lambdas for a given set of channels can be computed
% using chnsScaling.m, alternatively, if no lambdas are specified, the
% lambdas are automatically approximated using two true image scales.
%
% Typically approximating all scales within an octave (by setting
% nApprox=nPerOct-1 or nApprox=-1) works well, and results in large speed
% gains (~4x). See example below for a visualization of the pyramid
% computed with and without the approximation. While there is a slight
% difference in the channels, during detection the approximated channels
% have been shown to be essentially as effective as the original channels.
%
% While every effort is made to space the image scales evenly, this is not
% always possible. For example, given a 101x100 image, it is impossible to
% downsample it by exactly 1/2 along the first dimension, moreover, the
% exact scaling along the two dimensions will differ. Instead, the scales
% are tweaked slightly (e.g. for a 101x101 image the scale would go from
% 1/2 to something like 50/101), and the output contains the exact scaling
% factors used for both the heights and the widths ("scaleshw") and also
% the approximate scale for both dimensions ("scales"). If "shrink">1 the
% scales are further tweaked so that the resized image has dimensions that
% are exactly divisible by shrink (for details please see the code).
%
% If chnsPyramid() is called with no inputs, the output is the complete
% default parameters (pPyramid). Finally, we describe the remaining
% parameters: "pad" controls the amount the channels are padded after being
% created (useful for detecting objects near boundaries); "smooth" controls
% the amount of smoothing after the channels are created (and controls the
% integration scale of the channels); finally "concat" determines whether
% all channels at a single scale are concatenated in the output.
%
% An emphasis has been placed on speed, with the code undergoing heavy
% optimization. Computing the full set of (approximated) *multi-scale*
% channels on a 480x640 image runs over *30 fps* on a single core of a
% machine from 2011 (although runtime depends on input parameters).
%
% USAGE
%  pPyramid = chnsPyramid()
%  pyramid = chnsPyramid( I, pPyramid )
%
% INPUTS
%  I            - [hxwx3] input image (uint8 or single/double in [0,1])
%  pPyramid     - parameters (struct or name/value pairs)
%   .pChns        - parameters for creating channels (see chnsCompute.m)
%   .nPerOct      - [8] number of scales per octave
%   .nOctUp       - [0] number of upsampled octaves to compute
%   .nApprox      - [-1] number of approx. scales (if -1 nApprox=nPerOct-1)
%   .lambdas      - [] coefficients for power law scaling (see BMVC10)
%   .pad          - [0 0] amount to pad channels (along T/B and L/R)
%   .minDs        - [16 16] minimum image size for channel computation
%   .smooth       - [1] radius for channel smoothing (using convTri)
%   .concat       - [1] if true concatenate channels
%   .complete     - [] if true does not check/set default vals in pPyramid
%
% OUTPUTS
%  pyramid      - output struct
%   .pPyramid     - exact input parameters used (may change from input)
%   .nTypes       - number of channel types
%   .nScales      - number of scales computed
%   .data         - [nScales x nTypes] cell array of computed channels
%   .info         - [nTypes x 1] struct array (mirrored from chnsCompute)
%   .lambdas      - [nTypes x 1] scaling coefficients actually used
%   .scales       - [nScales x 1] relative scales (approximate)
%   .scaleshw     - [nScales x 2] exact scales for resampling h and w
%
% EXAMPLE
%  I=imResample(imread('peppers.png'),[480 640]);
%  pPyramid=chnsPyramid(); pPyramid.minDs=[128 128];
%  pPyramid.nApprox=0; tic, P1=chnsPyramid(I,pPyramid); toc
%  pPyramid.nApprox=7; tic, P2=chnsPyramid(I,pPyramid); toc
%  figure(1); montage2(P1.data{2}); figure(2); montage2(P2.data{2});
%  figure(3); montage2(abs(P1.data{2}-P2.data{2})); colorbar;
%
% See also chnsCompute, chnsScaling, convTri, imPad
%
% Piotr's Image&Video Toolbox      Version 3.25
% Copyright 2013 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get default parameters pPyramid
if(nargin==2), p=varargin{1}; else p=[]; end
if( ~isfield(p,'complete') || p.complete~=1 || isempty(I) )
  dfs={ 'pChns',{}, 'nPerOct',8, 'nOctUp',0, 'nApprox',-1, ...
    'lambdas',[], 'pad',[0 0], 'minDs',[16 16], ...
    'smooth',1, 'concat',1, 'complete',1 };
  p=getPrmDflt(varargin,dfs,1); chns=chnsCompute([],p.pChns);
  p.pChns=chns.pChns; p.pChns.complete=1; shrink=p.pChns.shrink;
  p.pad=round(p.pad/shrink)*shrink; p.minDs=max(p.minDs,shrink*4);
  if(p.nApprox<0), p.nApprox=p.nPerOct-1; end
end
if(nargin==0), pyramid=p; return; end; pPyramid=p;
vs=struct2cell(p); [pChns,nPerOct,nOctUp,nApprox,lambdas,...
  pad,minDs,smooth,concat,~]=deal(vs{:}); shrink=pChns.shrink;

% convert I to appropriate color space (or simply normalize)
cs=pChns.pColor.colorSpace; sz=[size(I,1) size(I,2)];
if(~all(sz==0) && size(I,3)==1 && ~any(strcmpi(cs,{'gray','orig'}))),
  I=I(:,:,[1 1 1]); warning('Converting image to color'); end %#ok<WNTAG>
I=rgbConvert(I,cs); pChns.pColor.colorSpace='orig';

% get scales at which to compute features and list of real/approx scales
[scales,scaleshw]=getScales(nPerOct,nOctUp,minDs,shrink,sz);
nScales=length(scales); if(1), isR=1; else isR=1+nOctUp*nPerOct; end
isR=isR:nApprox+1:nScales; isA=1:nScales; isA(isR)=[];
j=[0 floor((isR(1:end-1)+isR(2:end))/2) nScales];
isN=1:nScales; for i=1:length(isR), isN(j(i)+1:j(i+1))=isR(i); end
nTypes=0; data=cell(nScales,nTypes); info=struct([]);

% compute image pyramid [real scales]
for i=isR
  s=scales(i); sz1=round(sz*s/shrink)*shrink;
  if(all(sz==sz1)), I1=I; else I1=imResampleMex(I,sz1(1),sz1(2),1); end
  if(s==.5 && (nApprox>0 || nPerOct==1)), I=I1; end
  chns=chnsCompute(I1,pChns); info=chns.info;
  if(i==isR(1)), nTypes=chns.nTypes; data=cell(nScales,nTypes); end
  data(i,:) = chns.data;
end

% if lambdas not specified compute image specific lambdas
if( nScales>0 && nApprox>0 && isempty(lambdas) )
  is=1+nOctUp*nPerOct:nApprox+1:nScales;
  assert(length(is)>=2); if(length(is)>2), is=is(2:3); end
  f0=zeros(1,nTypes); f1=f0; d0=data(is(1),:); d1=data(is(2),:);
  for j=1:nTypes, d=d0{j}; f0(j)=sum(d(:))/numel(d); end
  for j=1:nTypes, d=d1{j}; f1(j)=sum(d(:))/numel(d); end
  lambdas = - log2(f0./f1) / log2(scales(is(1))/scales(is(2)));
end

% compute image pyramid [approximated scales]
for i=isA
  iR=isN(i); sz1=round(sz*scales(i)/shrink);
  for j=1:nTypes, ratio=(scales(i)/scales(iR)).^-lambdas(j);
    data{i,j}=imResampleMex(data{iR,j},sz1(1),sz1(2),ratio); end
end

% smooth channels, optionally pad and concatenate channels
for i=1:nScales*nTypes, data{i}=convTri(data{i},smooth); end
if(any(pad)), for i=1:nScales, for j=1:nTypes
      data{i,j}=imPad(data{i,j},pad/shrink,info(j).padWith); end; end; end
if(concat && nTypes), data0=data; data=cell(nScales,1); end
if(concat && nTypes), for i=1:nScales, data{i}=cat(3,data0{i,:}); end; end

% create output struct
j=info; if(~isempty(j)), j=find(strcmp('color channels',{j.name})); end
if(~isempty(j)), info(j).pChn.colorSpace=cs; end
pyramid = struct( 'pPyramid',pPyramid, 'nTypes',nTypes, ...
  'nScales',nScales, 'data',{data}, 'info',info, 'lambdas',lambdas, ...
  'scales',scales, 'scaleshw',scaleshw );

end

function [scales,scaleshw] = getScales(nPerOct,nOctUp,minDs,shrink,sz)
% set each scale s such that max(abs(round(sz*s/shrink)*shrink-sz*s)) is
% minimized without changing the smaller dim of sz (tricky algebra)
if(any(sz==0)), scales=[]; scaleshw=[]; return; end
nScales = floor(nPerOct*(nOctUp+log2(min(sz./minDs)))+1);
scales = 2.^(-(0:nScales-1)/nPerOct+nOctUp);
if(sz(1)<sz(2)), d0=sz(1); d1=sz(2); else d0=sz(2); d1=sz(1); end
for i=1:nScales, s=scales(i);
  s0=(round(d0*s/shrink)*shrink-.25*shrink)./d0;
  s1=(round(d0*s/shrink)*shrink+.25*shrink)./d0;
  ss=(0:.01:1-eps)*(s1-s0)+s0;
  es0=d0*ss; es0=abs(es0-round(es0/shrink)*shrink);
  es1=d1*ss; es1=abs(es1-round(es1/shrink)*shrink);
  [~,x]=min(max(es0,es1)); scales(i)=ss(x);
end
kp=[scales(1:end-1)~=scales(2:end) true]; scales=scales(kp);
scaleshw = [round(sz(1)*scales/shrink)*shrink/sz(1);
  round(sz(2)*scales/shrink)*shrink/sz(2)]';
end
