% Shows/makes an/several movie(s) from an image sequence.
%
% To play a matlab movie file, as an alternative to movie, use:
%  playMovie(movieToImages(M));
% The images to display are stacked in a higher dimensional array.
% MxNxCxTxRxS, where:
%  M - height
%  N - width
%  C - number of channels, nothing, 1 or 3
%  T - number of videos
%  R - number of cases
%  S - number of sets
%
% USAGE
%  playMovie( I, [fps], [loop], [prm] )
%
% INPUTS
%  I       - MxNxTxRxS or MxNx1xTxRxS or MxNx3xTxRxS or cell
%            array where each element is a MxNxTxR or MxNx1xTxR or
%            MxNx3xTxR (R ans S can equal 1)
%  fps     - [100] maximum number of frames to display per second
%            use fps==0 to introduce no pause and have the movie play as
%            fast as possible
%  loop    - [0] number of time to loop video (may be inf),
%            if neg plays video forward then backward then forward etc.
%  prm     - [] parameters to use calling montage2
%
% OUTPUTS
%
% EXAMPLE - [MxNxT] 1 video
%  load( 'images.mat' );
%  playMovie( video, [], -50 );
%
% EXAMPLE - [MxNxTxR] many videos at same time
%  load( 'images.mat' );
%  playMovie( videos, [], 5 );
%
% EXAMPLE - [MxNxTxRxS] show groups of videos in 2 ways
%  load( 'images.mat' );
%  IC = clusterMontage( videos, IDXv, 9, 1 );
%  clf; M = playMovie( IC );
%  clf; M = playMovie( IC, [], 5, struct('perRow',1,'showLines',0) );
%
% See also MONTAGE2, MOVIETOIMAGES, MOVIE

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function M = playMovie( I, fps, loop, prm )

if( nargin<2 || isempty(fps)); fps = 100; end
if( nargin<3 || isempty(loop)); loop = 1; end
if( nargin<4 || isempty(prm)); prm=struct(); end

nd=ndims(I); siz=size(I);
if ~iscell(I);
  if ~any(ismember(nd, 3:6)); error('unsupported dimension of I'); end
  if ~any(size(I,3)==[1 3]); % should be controlled by flag hasChn
    I=reshape(I,[siz(1),siz(2),1,siz(3:end)]);
  else
    error(['Invalid input, I has to be MxNxTxRxS or MxNx1xTxRxS or ' ...
      'or MxNx3xTxRxS, with R and S possibly equal to 1']);
  end
  nframes=size(I,4);
  nd=ndims(I);
  cLim = [min(I(:)) max(I(:))];
else
  cLim=[Inf -Inf];
  for i=1:length(I)
    if ~any(size(I,3)==[1 3]);
      siz=size(I{i}); I{i}=reshape(I{i},[siz(1),siz(2),1,siz(3:end)]);
    end
    nframes=max(nframes,siz(3));
    cLim = [min(I(:),cLim(1)) max(I(:),cLim(2))];
  end
  nd=ndims(I{1});
  cLim = [min(I(:)) max(I(:))];
end
prm.cLim=cLim;

h=gcf; colormap gray; figure(h); % bring to focus
if nargout>0; M=repmat(getframe,[1 nframes]); end
order = 1:nframes;
j=1;
for nplayed = 1 : abs(loop)
  for i=order
    tic; try disc=get(h); catch return; end %#ok<NASGU>
    if ~iscell(I)
      if nd==5
        montage2(squeeze(I(:,:,:,i,:)),prm);
      else
        montage2(squeeze(I(:,:,:,i,:,:)),prm);
      end
    else
      I2=cell(1,length(I));
      for j=1:length(I); try I2{j}=I{j}(:,:,:,i,:); catch I2{j}=[]; end;end
      montage2(I2,prm);
    end
    title(sprintf('frame %d of %d',i,nframes));
    if (fps>0); pause(1/fps - toc); end
    if nargout>0; M(j) = getframe; j=j+1; else drawnow; end
  end
  if loop<0; order = order(end:-1:1); end
end
if nargout>0; close(h); end
