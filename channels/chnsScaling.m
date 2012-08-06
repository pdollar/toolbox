function [lambdas,as,scales,fs] = chnsScaling( pPyramid, Is, show )
% Compute lambdas for channel power law scaling.
%
% For a broad family of features, including gradient histograms and all
% channel types tested, the feature responses computed at a single scale
% can be used to approximate feature responses at nearby scales. The
% approximation is accurate at least within an entire scale octave. For
% details and to understand why this unexpected result holds, please see:
%   P. Dollár, S. Belongie and P. Perona
%   "The Fastest Pedestrian Detector in the West," BMVC 2010.
%
% This function computes channels at multiple image scales and plots the
% resulting power law scaling. The purpose of this function is two-fold:
% (1) compute lambdas for fast approximate channel computation for use in
% chnsPyramid() and (2) provide a visualization of the power law channel
% scaling described in the BMVC2010 paper.
%
% chnsScaling() takes two main inputs: the parameters for computing an
% image pyramid (pPyramid), which also include parameters for individual
% channel computation, and an image or set of images (Is). The images are
% downsampled to the dimension of the smallest image for simplicity of
% computing the lambdas (and fairly high resolution images are best). The
% computed lambdas will depend on the channel parameters (e.g. how much
% smoothing is performed), but given enough images (>1000) the computed
% lambdas should not depend on the exact images used.
%
% USAGE
%  [lambdas,as,scales,fs] = chnsScaling( pPyramid, Is, [show] )
%
% INPUTS
%  pPyramid       - parameters for creating pyramid (see chnsPyramid.m)
%  Is             - [nImages x 1] cell array of images (nImages may be 1)
%  show           - [1] figure in which to display results
%
% OUTPUTS
%  lambdas        - [nTypes x 1] computed lambdas
%  as             - [nTypes x 1] computed y-intercepts
%  scales         - [nScales x 1] vector of actual scales used
%  fs             - [nImages x nScales x nTypes] array of feature means
%
% EXAMPLE
%  sDir='../demoPeds/data/train/negBig';
%  Is = fevalImages( @(x) {x}, {}, sDir, 'I', 'png', 0, 200 );
%  pPyramid = chnsPyramid([],'shrink',4,'nPerOct',12);
%  lambdas = chnsScaling( pPyramid, Is, 1 );
%
% See also chnsCompute, chnsPyramid, fevalImages
%
% Piotr's Image&Video Toolbox      Version 3.00
% Copyright 2012 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get additional input arguments
if(nargin<3 || isempty(show)), show=1; end

% fix some parameters in pPyramid (don't pad, concat or appoximate)
pPyramid=chnsPyramid([],pPyramid); pPyramid.pad=[0 0];
pPyramid.concat=0; pPyramid.nApprox=0; pPyramid.nOctUp=0;
shrink=pPyramid.shrink; pPyramid.minDs(:)=max(8,shrink*4);
pPyramid.smoothChns=0;

% resize all images to smallest image size
ds=[inf inf]; nImages=numel(Is);
for i=1:nImages, ds=min(ds,[size(Is{i},1) size(Is{i},2)]); end
ds=floor(ds/shrink)*shrink;
for i=1:nImages, Is{i}=imResample(Is{i},ds); end

% compute fs [nImages x nScales x nTypes] array of feature means
P=chnsPyramid(Is{1},pPyramid); scales=P.scales'; info=P.info;
nScales=P.nScales; nTypes=P.nTypes; fs=zeros(nImages,nScales,nTypes);
parfor i=1:nImages, P=chnsPyramid(Is{i},pPyramid); for j=1:nScales
    for k=1:nTypes, fs(i,j,k)=mean(P.data{j,k}(:)); end; end; end

% compute ratios, intercepts and lambdas using least squares
scales1=scales(2:end); nScales=nScales-1; O=ones(nScales,1);
rs=fs(:,2:end,:)./fs(:,O,:); mus=permute(mean(rs,1),[2 3 1]);
out=[O -log2(scales1)]\log2(mus); as=2.^out(1,:); lambdas=out(2,:);
if(0), lambdas=-log2(scales1)\log2(mus); as(:)=1; end
if(show==0), return; end

% compute predicted means and errors for display purposes
musp=as(O,:).*scales1(:,ones(1,nTypes)).^-lambdas(O,:);
errsFit=mean((musp-mus).^2,1); stds=permute(std(rs,0,1),[2 3 1]);

% plot results
if(show<0), show=-show; clear=0; else clear=1; end
figureResized(.75,show); if(clear), clf; end
lp={'LineWidth',2}; tp={'FontSize',12};
for k=1:nTypes
  % plot ratios
  subplot(2,nTypes,k); set(gca,tp{:});
  h0=loglog(1./scales1,mus(:,k),'go',lp{:}); hold on;
  h1=loglog(1./scales1,musp(:,k),'b-',lp{:});
  title(sprintf('%s\n\\lambda = %.03f,  error = %.2e',...
    info(k).name,lambdas(k),errsFit(k)));
  legend([h0 h1],{'real','fit'},'location','ne');
  xlabel('log2(scale)'); ylabel('\mu (ratio)'); axis tight;
  ax=axis; ax(1)=1; ax(3)=min(.9,ax(3)); ax(4)=max(2,ax(4)); axis(ax);
  set(gca,'ytick',[.5 1 1.4 2 3 4],'YMinorTick','off');
  set(gca,'xtick',2.^(-10:.5:10),'XTickLabel',10:-.5:-10);
  % plot variances
  subplot(2,nTypes,k+nTypes); set(gca,tp{:});
  semilogx(1./scales1,stds(:,k),'go',lp{:}); hold on;
  xlabel('log2(scale)'); ylabel('\sigma (ratio)'); axis tight;
  ax=axis; ax(1)=1; ax(3)=0; ax(4)=max(.5,ax(4)); axis(ax);
  set(gca,'xtick',2.^(-10:.5:10),'XTickLabel',10:-.5:-10);
end

end
