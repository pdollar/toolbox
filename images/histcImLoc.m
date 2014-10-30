function h = histcImLoc( I, edges, parMask, wtMask, multCh )
% Creates a series of locally position dependent histograms.
%
% Inspired by David Lowe's SIFT descriptor.  Takes I, divides it into a
% number of regions, and creates a histogram for each region. I is divided
% into approximately equally sized hyper-rectangular regions so that
% together these hyper-rectangles cover I.  The hyper-rectangles are
% actually 'soft', in that each region is actually defined by a gaussian
% mask, for details see maskGaussians. parMask, parameters to
% maskGaussians, controls details about how the masks are created.
% Optionally, each value in I may have associated weight given by wtMask,
% which should have the same exact dimensions as each channel of I.
%
% If multCh is set to true, then:
%  I is an [M1xM2x...xMkxnd] array of nd channels
% otherwise
%  I is an [M1xM2x...xMk] array of 1 channel
% If nd==1, histcImLoc creates a 1D histogram using histc2.  More
% generally, histcImLoc creates an nd dimensional histogram (again using
% hist2c).  histcImLoc creates nMasks (number of masks) histgorams, each
% which have dimension nBins^nd.  So if nd==1 the output of this function
% is [nBins x nMasks], and for example if nd==2 the output is [nBins x
% nBins x nMasks].  If nd is large computing the histograms is time
% consuming.
%
% USAGE
%  h = histcImLoc( I, edges, parMask, [wtMask], [multCh] )
%
% INPUTS
%  I           - M1xM2x...xMkxnd array, (nd channels each of M1xM2x...xMk)
%  edges       - quantization bounds, see histc2
%  parMask     - cell of parameters to maskGaussians
%  wtMask      - [] M1xM2x...xMk numeric array of weights
%  multCh      - [0] if 1 last dimension of I is number of channels
%
% OUTPUTS
%  h           - nd-histograms [nBins^nd x nMasks]
%
% EXAMPLE - multCh==0
%  I = filterGauss([100 100],[],[],0);
%  h = histcImLoc(I,10,{2,.6,.1,1},[],0);
%  figure(1); im(h)
%
% EXAMPLE - multCh==1
%  I = filterGauss([100 100],[],[],0);
%  h1 = histcImLoc( cat(3,I,I), 10, {2,.6,.1,0},[],1);
%  h2 = histcImLoc( cat(3,I,randn(size(I))),10,{2,.6,.1,0},[],1);
%  figure(1); montage2(h1); figure(2); montage2(h2);
%
% See also HISTC2, MASKGAUSSIANS, ASSIGNTOBINS, HISTCIMWIN
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 ); wtMask=[]; end;
if( nargin<5 ); multCh=0; end;

% set up for either multiple channels or 1 channel
siz = size(I); nd=ndims(I);
if( multCh )
  nch=siz(end); siz=siz(1:end-1); nd=nd-1;
else
  nch=1;
end;

% create masks [slow but cached]
[masks,keepLocs] = maskGaussians( siz, parMask{:} );
nMasks = size(masks,nd+1);
if( ~isempty(wtMask) )
  masks = masks .* repmat(wtMask,[ones(1,nd) nMasks]);
end;

% flatten
I = reshape( I, [], nch );
masks = reshape( masks, [], nMasks );
keepLocs = reshape( keepLocs, [], nMasks );

% amount to smoothe each histogram by [help alleviate quantization errors]
fsmooth = [0.0003 0.1065 0.7866 0.1065 0.0003]; %$P: gauss w std==.5

% create all the histograms
inds={':'};  indsh=inds(:,ones(1,nch));
for m=1:nMasks
  % remove locations not contributing to minimze work for histc
  keepLocsi = keepLocs(:,m);
  maski = masks(:,m); maski=maski(keepLocsi);
  Ii = reshape( I(repmat(keepLocsi,[1,nch])), [], nch );

  % create histograms
  hi = histc2( Ii, edges, maski );

  % smooth [if nch==1 or 2 do locally for speed, if nch>3 too slow]
  if( nch==1 )
    hi = conv2( hi, fsmooth, 'same' );
  elseif( nch==2 )
    hi = conv2( hi, fsmooth', 'same' );
    hi = conv2( hi, fsmooth , 'same' );
  elseif( nch==3 )
    hi = gaussSmooth( hi, .5, 'same', 2.5 );
  end;
  if( nch<=3 ); hi=hi/sum(hi(:));  end;

  % store results
  if( m==1 )
    h=repmat(hi, [ones(1,nch), nMasks] );
  else
    h(indsh{:},m) = hi;
  end
end
