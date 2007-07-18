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
% EXAMPLE - [MxNx3xT] 1 video
%  load( 'images.mat' );
%  video3=repmat(permute(video,[1 2 4 3]),[1 1 3 1]);
%  playMovie( video3, [], -50, struct('hasChn',true));
%
% EXAMPLE - [MxNxTxR] many videos at same time
%  load( 'images.mat' );
%  playMovie( videos, [], 5 );
%
% EXAMPLE - [MxNxTxRxS] show groups of videos in 2 ways
%  load( 'images.mat' );
%  IC = clusterMontage( videos, IDXv, 9, 1 );
%  clf; M = playMovie( IC );
%  prm = struct('perRow',1,'padAmt',4,'showLines',0,'nn',1);
%  clf; M = playMovie( IC, [], 5, prm );
%
% EXAMPLE - {S}[MxNxTxR] show groups of videos given in a cell
%  ICcell = squeeze(mat2cell2( IC, [1 1 1 1 9] ));
%  clf; M = playMovie( ICcell, [], 5, struct('showLines',0) );
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
  if( ~any(ismember(nd, 3:6))); error('unsupported dimension of I'); end
  if( ~any(size(I,3)==[1 3])); % should be controlled by flag hasChn?
    I=reshape(I,[siz(1),siz(2),1,siz(3:end)]);
    prm.hasChn=1;
  end
  nframes=size(I,4); nd=ndims(I);
  if( nd<3 || nd>6 )
    error(['Invalid input, I has to be MxNxTxRxS or MxNx1xTxRxS or ' ...
      'or MxNx3xTxRxS, with R and S possibly equal to 1']);
  end
  cLim = [min(I(:)) max(I(:))];
else
  cLim=[Inf -Inf]; nframes=0;
  for i=1:length(I)
    siz=size(I{i});
    if ~any(size(I{i},3)==[1 3])
      I{i}=reshape(I{i},[siz(1),siz(2),1,siz(3:end)]);
      prm.hasChn=1;
    end
    nframes=max(nframes,size(I{i},4));
    cLim = [min(min(I{i}(:)),cLim(1)) max(max(I{i}(:)),cLim(2))];
  end
end
prm.cLim=cLim;

h=gcf; colormap gray; figure(h); % bring to focus
if nargout>0; M=repmat(getframe,[1 nframes]); end
order = 1:nframes;  j=1; siz=size(I);
for nplayed = 1 : abs(loop)
  for i=order
    tic; try disc=get(h); catch return; end %#ok<NASGU>
    if ~iscell(I)
       montage2(reshape(I(:,:,:,i,:,:),[siz(1:3) siz(5:end)]),prm);
    else
      I2=cell(1,length(I));
      for j=1:length(I)
        siz=size(I{j}); siz(end+1:5)=1;
        try I2{j}=reshape(I{j}(:,:,:,i,:),[siz(1:3) siz(5)]);
        catch I2{j}=[]; 
        end
      end
      montage2(I2,prm);
    end
    title(sprintf('frame %d of %d',i,nframes));
    if (fps>0); pause(1/fps - toc); end
    if nargout>0; M(j) = getframe; j=j+1; else drawnow; end
  end
  if loop<0; order = order(end:-1:1); end
end
if nargout>0; close(h); end
