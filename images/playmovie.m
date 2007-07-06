% [3D] shows the image sequence I as a movie.
%
% To play a matlab movie file, as an alternative to movie, use:
%   playmovie(movie2images(M));
% The images to display are stacked in a higher dimensional array.
% MxNx(number of colors, nothing, 1 or 3)x(T=number of frames)x(R=number of
% cases)
%
% USAGE
%  playmovie( I, [fps], [loop] )
%
% INPUTS
%  I       - MxNxT or MxNx1xT or MxNx3xT or
%            MxNxTxR or MxNx1xTxR or MxNx3xTxR array (of images)
%  fps     - [100] maximum number of frames to display per second
%            use fps==0 to introduce no pause and have the movie play as
%            fast as possible
%  loop    - [0] number of time to loop video (may be inf),
%            if neg plays video forward then backward then forward etc.
%
% OUTPUTS
%
% EXAMPLE - 1
%  load( 'images.mat' );
%  playmovie( videos(:,:,:,1) );
%  playmovie( video(:,:,1:3), [], -50 );
%
% EXAMPLE - 2
%  load( 'images.mat' );
%  playmovie( videos );
%
% See also MONTAGE2, MAKEMOVIE, MOVIE2IMAGES, MOVIE, MONTAGES, MAKEMOVIES

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function playmovie( I, fps, loop )

if( nargin<2 || isempty(fps)); fps = 100; end
if( nargin<3 || isempty(loop)); loop = 1; end

nd=ndims(I); siz=size(I);
if( iscell(I) ); error('cell arrays not supported.'); end
if ~any(ismember(nd, 3:5)); error('unsupported dimension of I'); end

nframes=siz(3); inds={':',':'};
switch nd
  case 4
    if any(siz(3)==[1 3]); nframes=siz(4); inds={':',':',':'}; end
  case 5
    nframes=siz(4); inds={':',':',':'};
end

clim = [min(I(:)) max(I(:))];
h=gcf; colormap gray; figure(h); % bring to focus
order = 1:nframes;
for nplayed = 1 : abs(loop)
  for i=order
    tic; try disc=get(h); catch return; end %#ok<NASGU>
    montage2(squeeze(I(inds{:},i,:)),1,[],clim);
    title(sprintf('frame %d of %d',i,nframes));
    if(fps>0); pause(1/fps - toc); end
    drawnow;
  end
  if loop<0; order = order(end:-1:1); end
end
