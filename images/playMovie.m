function M = playMovie( I, fps, loop, prm )
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
%  load( 'images.mat' );
%  IC = clusterMontage( videos, IDXv, 9, 1 );
%  ICcell = squeeze(mat2cell2( IC, [1 1 1 1 9] ));
%  clf; M = playMovie( ICcell, [], 5, struct('showLines',0) );
%
% See also MONTAGE2, MOVIETOIMAGES, MOVIE
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 || isempty(fps)); fps = 100; end
if( nargin<3 || isempty(loop)); loop = 1; end
if( nargin<4 || isempty(prm)); prm=struct(); end
dfs = {'hasChn',false }; prm = getPrmDflt( prm, dfs );

nd=ndims(I);
if ~iscell(I);
  if( ~any(ismember(nd, 3:6))); error('unsupported dimension of I'); end
  if( prm.hasChn ); nframes=size(I,4); else nframes=size(I,3); end
  nd=ndims(I);
  if( nd<3 || nd>6 )
    error(['Invalid input, I has to be MxNxTxRxS or MxNx1xTxRxS or ' ...
      'or MxNx3xTxRxS, with R and S possibly equal to 1']);
  end
  cLim = [min(I(:)) max(I(:))];
else
  cLim=[Inf -Inf]; nframes=0;
  for i=1:length(I)
    Ii = I{i};
    if( prm.hasChn ); nframesi=size(Ii,4); else nframesi=size(Ii,3); end
    nframes=max(nframes,nframesi);
    cLim = [min(min(Ii(:)),cLim(1)) max(max(Ii(:)),cLim(2))];
  end
end
prm.cLim=cLim;

inds={':' ':'}; if( prm.hasChn ); inds{3}=inds{1}; end

h=gcf; colormap gray; figure(h); % bring to focus
if nargout>0; M=repmat(getframe,[1 nframes]); end
order = 1:nframes;  j=1;
for nplayed = 1 : abs(loop)
  for i=order
    tic; try disc=get(h); catch, return; end %#ok<*CTCH,NASGU>
    if ~iscell(I)
      montage2(reshape(I(inds{:},i,:,:),sizeWithouti(I)),prm);
    else
      I2=cell(1,length(I));
      for k=1:length(I)
        try I2{k}=reshape(I{k}(inds{:},i,:),sizeWithouti(I{k})); catch, end
      end
      montage2(I2,prm);
    end
    title(sprintf('frame %d of %d',i,nframes));
    if fps>0; pause(1/fps - toc); end
    if nargout>0; try M(j)=getframe; catch, end; j=j+1; else drawnow; end
  end
  if loop<0; order = order(end:-1:1); end
end
if nargout>0; close(h); end

  function siz=sizeWithouti(I)
    siz=size(I); if( prm.hasChn ); siz(4)=[]; else siz(3)=[];end
  end
end
