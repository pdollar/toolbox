% [5D] Used to convert S sets of R videos into a movie.
%
% Displays one set per row.  Each of the S sets is flattened to a single
% long image by concatenating the T images in the set. Alternative to
% makemoviesets. Works by calling montages once per frame.
%
% USAGE
%  M = makemoviesets2( IS, [montagesparams] )
%
% INPUTS
%  IS              - MxNxTxRxS or MxNx1xTxRxS or MxNx3xTxRxS array
%  montagesparams  - [] cell array of params for montages
%
% OUTPUTS
%  M               - resulting movie
%
% EXAMPLE
%  load( 'images.mat' );
%  videoclusters = clustermontage( videos, IDXv, 9, 1 );
%  M = makemoviesets2( videoclusters );
%  movie( M );
%
% See also MAKEMOVIE, MAKEMOVIESETS, CLUSTERMONTAGE

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function M = makemoviesets2( IS, montagesparams )

if( nargin<2 ); montagesparams = {}; end;
if( isempty(montagesparams) || isempty(montagesparams{1}))
  params2 = cell(1,6);
else
  params2 = [montagesparams{1} cell(1,5-length(montagesparams{1}))];
end

% get/test image format info
nd = ndims(IS);
if( nd==5 ) % MxNxTxRxS
  nframes = size(IS,3);
elseif( nd==6 ) % MxNx1xTxRxS or MxNx3xTxRxS
  nframes = size(IS,4);
else
  error('unsupported dimension of IS');
end;
A=IS(:); clim=[min(A) max(A)];
params2{3} = clim;  montagesparams{1}=params2;

% make the movie by calling montages and getframe repeatedly
h=figureResized(.8); axis off; M=repmat(getframe(h),[1,nframes]);
for f=1:nframes
  if( ndims(IS)==5 )
    montages( squeeze(IS(:,:,f,:,:)), montagesparams{:},4 );
  else
    montages( squeeze(IS(:,:,:,f,:,:)), montagesparams{:},4 );
  end;
  M(f) = getframe(h);
end
close(h);
