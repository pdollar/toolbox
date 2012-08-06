function chns = chnsCompute( I, varargin )
% Compute channel features at a single scale given an input image.
%
% Compute the channel features as described in:
%  P. Dollár, Z. Tu, P. Perona and S. Belongie
%  "Integral Channel Features", BMVC 2009.
% Channel features have proven very effective in sliding window object
% detection, both in terms of *accuracy* and *speed*. Numerous feature
% types including histogram of gradients (hog) can be converted into
% channel features, and overall, channels are general and powerful.
%
% Given an input image I, a corresponding channel is a registered map of I,
% where the output pixels are computed from corresponding patches of input
% pixels (thus preserving overall image layout). A trivial channel is
% simply the input grayscale image, likewise for a color image each color
% channel can serve as a channel. Other channels can be computed using
% linear or non-linear transformations of I, various choices implemented
% here are described below. The only constraint is that channels must be
% translationally invariant (i.e. translating the input image or the
% resulting channels gives the same result). This allows for fast object
% detection, as the channels can be computed once on the entire image
% rather than separately for each overlapping detection window.
%
% Currently, three channel types are available by default (to date, these
% have proven the most effective for sliding window object detection):
%  (1) color channels (computed using rgbConvert.m)
%  (2) gradient magnitude (computed using gradientMag.m)
%  (3) quantized gradient channels (computed using gradientHist.m)
% For more information about each channel type, including the exact input
% parameters and their meanings, see the respective m-files which perform
% the actual computatons (chnsCompute is essentially a wrapper function).
%
% Additionally, custom channels can be specified via an optional struct
% array "pCustom" which may have 0 or more custom channel definitions. Each
% custom channel is generated via a call to "chns=feval(hFunc,I,pFunc{:})".
% The color space of I is determined by pColor.colorSpace, use the setting
% colorSpace='orig' if the input image is not an 'rgb' image and should be
% left unchaned (e.g. if I has multiple channels). The input I will have
% type single and the output of hFunc should also have type single.
%
% As mentioned, the params for each channel type are described in detail in
% the respective function. In addition, each channel type has a parameter
% "enabled" that determines if the channel is computed. If chnsCompute() is
% called with no inputs or empty I, the output is the complete default
% parameters (pChns). Otherwise the outputs are the computed channels and
% additional meta-data (see below). The channels are computed at a single
% scale, for (fast) multi-scale channel computation see chnsPyramid.m.
%
% An emphasis has been placed on speed, with the code undergoing heavy
% optimization. Computing the full set of channels used in the BMVC09 paper
% referenced above on a 480x640 image runs over *100 fps* on a single core
% of a machine from 2011 (although runtime depends on input parameters).
%
% USAGE
%  chns = chnsCompute( I, pChns )
%
% INPUTS
%  I           - [hxwx3] input image (uint8 or single/double in [0,1])
%  pChns       - parameters (struct or name/value pairs)
%   .pColor       - parameters for color space:
%     .enabled      - [1] if true enable color channels
%     .colorSpace   - ['luv'] choices are: 'gray', 'rgb', 'hsv', 'orig'
%   .pGradMag     - parameters for gradient magnitude:
%     .enabled      - [1] if true enable gradient magnitude channel
%     .colorChn     - [0] if>0 color channel to use for grad computation
%     .normRad      - [5] normalization radius for gradient
%     .normConst    - [.005] normalization constant for gradient
%   .pGradHist    - parameters for gradient histograms:
%     .enabled      - [1] if true enable gradient histogram channels
%     .binSize      - [1] spatial bin size (if > 1 chns will be smaller)
%     .nOrients     - [6] number of orientation channels
%     .softBin      - [0] if true use "soft" bilinear spatial binning
%     .useHog       - [0] if true perform 4-way hog normalization/clipping
%     .clipHog      - [.2] value at which to clip hog histogram bins
%   .pCustom      - parameters for custom channels (optional struct array):
%     .enabled      - [1] if true enable custom channel type
%     .name         - ['REQ'] custom channel type name
%     .hFunc        - ['REQ'] function handle for computing custom channels
%     .pFunc        - [{}] additional params for chns=hFunc(I,pFunc{:})
%     .padWith      - [0] how channel should be padded (e.g. 0,'replicate')
%   .complete     - [] if true does not check/set default vals in pChns
%
% OUTPUTS
%  chns       - output struct
%   .pChns      - exact input parameters used
%   .nTypes     - number of channel types
%   .data       - [nTypes x 1] cell array of channels (each is [hxwxnChns])
%   .info       - [nTypes x 1] struct array
%     .name       - channel type name
%     .pChn       - exact input parameters for given channel type
%     .nChns      - number of channels for given channel type
%     .padWith    - how channel should be padded (0,'replicate')
%
% EXAMPLE
%  I = imResample(imread('peppers.png'),[480 640]);
%  pChns = chnsCompute(); pChns.pGradHist.binSize=4;
%  tic, for i=1:100, chns = chnsCompute(I,pChns); end; toc
%  figure(1); montage2(chns.data{3});
%
% See also rgbConvert, gradientMag, gradientHist, chnsPyramid
%
% Piotr's Image&Video Toolbox      Version 3.00
% Copyright 2012 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get default parameters pChns
if(nargin==2), pChns=varargin{1}; else pChns=[]; end
if( ~isfield(pChns,'complete') || pChns.complete~=1 )
  p=struct('enabled',{},'name',{},'hFunc',{},'pFunc',{},'padWith',{});
  pChns = getPrmDflt(varargin,{'pColor',{},'pGradMag',{},...
    'pGradHist',{},'pCustom',p,'complete',1},1);
  pChns.pColor = getPrmDflt( pChns.pColor, {'enabled',1,...
    'colorSpace','luv'}, 1 );
  pChns.pGradMag = getPrmDflt( pChns.pGradMag, {'enabled',1,...
    'colorChn',0,'normRad',5,'normConst',.005}, 1 );
  pChns.pGradHist = getPrmDflt( pChns.pGradHist, {'enabled',1,...
    'binSize',1,'nOrients',6,'softBin',0,'useHog',0,'clipHog',.2}, 1 );
  nc=length(pChns.pCustom); pc=cell(1,nc);
  for i=1:nc, pc{i} = getPrmDflt( pChns.pCustom(i), {'enabled',1,...
      'name','REQ','hFunc','REQ','pFunc',{},'padWith',0}, 1 ); end
  if( nc>0 ), pChns.pCustom=[pc{:}]; end
end
if(nargin==0 || isempty(I)), chns=pChns; return; end

% extract parameters from pChns
p=pChns.pColor; enableColor=p.enabled; colorSpace=p.colorSpace;
p=pChns.pGradMag; enableGradMag=p.enabled;
colorChn=p.colorChn; normRad=p.normRad; normConst=p.normConst;
p=pChns.pGradHist; enableGradHist=p.enabled; binSize=p.binSize;
nOrients=p.nOrients; softBin=p.softBin; useHog=p.useHog; clipHog=p.clipHog;
p=pChns.pCustom; enableCustom=[p.enabled];

% compute color channels
I = rgbConvert(I,colorSpace); M=[]; H=[];

% compute gradient magnitude channel
if( enableGradMag || enableGradHist )
  if( ~enableGradHist ), M=gradientMag(I,colorChn,normRad,normConst);
  else [M,O]=gradientMag(I,colorChn,normRad,normConst); end
end

% compute gradient histgoram channels
if( enableGradHist )
  H=gradientHist(M,O,binSize,nOrients,softBin,useHog,clipHog); end

% compute custom channels
nc=length(enableCustom); C=cell(1,nc); pc=pChns.pCustom;
for i=find(enableCustom), C{i}=feval(pc(i).hFunc,I,pc(i).pFunc{:}); end

% constrcut extra info for output struct
info = {'color channels','gradient magnitude','gradient histogram'};
info = struct( 'name',info, 'pChn',{pChns.pColor,pChns.pGradMag, ...
  pChns.pGradHist}, 'nChns',{size(I,3),size(M,3),size(H,3)}, ...
  'padWith', {'replicate',0,0} );
for i=1:nc, info(i+3)=struct( 'name',pc(i).name, 'pChn',pc(i), ...
    'nChns',size(C{i},3), 'padWith',pc(i).padWith ); end

% create output struct
en = [enableColor enableGradMag enableGradHist enableCustom]>0;
data={I M H C{:}}; data=data(en); info=info(en); nTypes=nnz(en); %#ok<CCAT>
chns = struct('pChns',pChns,'nTypes',nTypes,'data',{data},'info',info);

end
