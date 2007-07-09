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
% which have dimension nbins^nd.  So if nd==1 the output of his function is
% [nBins x nMasks], and for example if nd==2 the output is [nBins x nBins x
% nMasks].  If nd is large computing the histograms is time consuming.
%
% USAGE
%  hs = histcImLoc( I, edges, parMask, [wtMask], [multCh] )
%
% INPUTS
%  I           - M1xM2x...xMkxnd array, (nd channels each of M1xM2x...xMk)
%  edges       - parameter to histc2, either scalar, vector, or cell vec
%  parMask     - cell of parameters to maskGaussians
%  wtMask      - [] M1xM2x...xMk numeric array of weights
%  multCh      - [0] if 1 last dimension of I is number of channels
%
% OUTPUTS
%  hs          - nd-histograms [nBins^nd x nMasks]
%
% EXAMPLE - multCh==0
%  I = filterGauss([100 100],[],[],0);
%  hs = histcImLoc(I,10,{2,.6,.1,1},[],0); 
%  figure(3); im(hs)
%
% EXAMPLE - multCh==1
%  I = filterGauss([100 100],[],[],0);
%  hs1 = histcImLoc( cat(3,I,I), 10, {2,.6,.1,0},[],1);
%  hs2 = histcImLoc( cat(3,I,randn(size(I))),10,{2,.6,.1,0},[],1);
%  figure(1); montage2(hs1,1);  figure(2); montage2(hs2,1);
%
% See also HISTC2, HISTC_SIFT, MASKGAUSSIANS

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function hs = histcImLoc( I, edges, parMask, wtMask, multCh )

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
inds={':'};  indshs=inds(:,ones(1,nch));
for m=1:nMasks
  % remove locations not contributing to minimze work for histc
  keepLocsi = keepLocs(:,m);
  maski = masks(:,m); maski=maski(keepLocsi);
  Ii = reshape( I(repmat(keepLocsi,[1,nch])), [], nch );

  % create histograms
  h = histc2( Ii, edges, maski );

  % smooth [if nch==1 or 2 do locally for speed, if nch>3 too slow]
  if( nch==1 )
    h = conv2( h, fsmooth, 'same' );
  elseif( nch==2 )
    h = conv2( h, fsmooth', 'same' );
    h = conv2( h, fsmooth , 'same' );
  elseif( nch==3 )
    h = gaussSmooth( h, .5, 'same', 2.5 );
  end;
  if( nch<=3 ); h=h/sum(h(:));  end;

  % store results
  if( m==1 )
    hs=repmat(h, [ones(1,nch), nMasks] );
  else
    hs(indshs{:},m) = h;
  end
end
