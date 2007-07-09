% Creates a series of locally position dependent histograms.
%
% Creates a series of locally position dependent histograms of the values
% in the mutiple channel multidimensional array I (this is a generalized
% version of histc_sift that allows for multiple channels).
%
% I is an M1xM2x...xMkxnd array, it consists of nd channels each of
% dimension (M1xM2x...xMk).  histc_sift_nD works by dividing a
% (M1xM2x...xMk) array into seperate regions and creating a 1D histogram
% for each using histc2.  histc_sift_nD does the same thing except each
% region now has multiple channels, and an nd-dimensional histogram is
% created for each using histc2.
%
% USAGE
%  hs = histc_sift_nD( I, edges, parGmask, [weightMask], [multCh] )
%
% INPUTS
%  I           - M1xM2x...xMkxnd array, (nd channels each of M1xM2x...xMk)
%  edges       - parameter to histc2, either scalar, vector, or cell vec
%  parGmask    - cell of parameters to maskGaussians
%  weightMask  - [] M1xM2x...xMk numeric array of weights
%  multCh      - [1] if 0 this becomes same as histc_sift.m (nd==1)
%
% OUTPUTS
%  hs          - histograms (array of size nmasks x nbins)
%
% EXAMPLE
%  G = filterGauss([100 100],[],[],0);
%  hs1 = histc_sift_nD( cat(3,G,G), 5, {2,.6,.1,0} );
%  hs2 = histc_sift_nD( cat(3,G,randn(size(G))),5,{2,.6,.1,0});
%  figure(1); montage2(hs1,1);  figure(2); montage2(hs2,1);
%
% See also HISTC2, HISTC_SIFT, MASKGAUSSIANS

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function hs = histc_sift_nD( I, edges, parGmask, weightMask, multCh )

if( nargin<4 ); weightMask=[]; end;
if( nargin<5 ); multCh=1; end;

% set up for either multiple channels or 1 channel
siz = size(I); nd=ndims(I);
if( multCh )
  nch=siz(end); siz=siz(1:end-1); nd=nd-1;
else
  nch=1;
end;

% create masks [slow but cached]
[masks,keeplocs] = maskGaussians( siz, parGmask{:} );
nmasks = size(masks,nd+1);
if( ~isempty(weightMask) )
  masks = masks .* repmat(weightMask,[ones(1,nd) nmasks]); end;

% flatten
I = reshape( I, [], nch );
masks = reshape( masks, [], nmasks );
keeplocs = reshape( keeplocs, [], nmasks );

% amount to smoothe each histogram by [help alleviate quantization errors]
fsmooth = [0.0003 0.1065 0.7866 0.1065 0.0003]; %$P: gauss w std==.5

% create all the histograms
inds={':'};  indshs=inds(:,ones(1,nch));
for m=1:nmasks
  % remove locations not contributing to minimze work for histc
  % [[wierd code, because optimized]]
  keeplocsi = keeplocs(:,m);
  maski = masks(:,m); maski=maski(keeplocsi);
  Ii = reshape( I(repmat(keeplocsi,[1,nch])), [], nch );

  % create histograms
  if( nch==1 )
    h = squeeze(histc2( Ii(:), edges, maski(:) ));
  else
    h = histc2( Ii, edges, maski );
  end;

  % smooth [if nch==1 or 2 do locally for speed]
  if( nch==1 )
    h = conv2( h, fsmooth, 'same' );
  elseif( nch==2 )
    h = conv2( h, fsmooth', 'same' );
    h = conv2( h, fsmooth , 'same' );
  elseif( nch==3 )
    h = gaussSmooth( h, .5, 'same', 2.5 );
  else
    % no smoothing, too slow
    %h = gaussSmooth( h, .5, 'same', 2.5 );
  end;

  % store results
  if( m==1 )
    hs=repmat(h, [ones(1,nch), nmasks] );
  else
    hs(indshs{:},m) = h;
  end
end
