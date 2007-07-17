% Used to display collections of images and videos.
%
% Improved version of montage, with more control over display.
% NOTE: Can convert between MxNxT and MxNx3xT image stack via:
%   I = repmat( I, [1,1,1,3] ); I = permute(I, [1,2,4,3] );
%
% USAGE
%  varargout = montage2( IS, [prm] )
%
% INPUTS
%  IS           - MxNxTxR or MxNxCxTxR, where C==1 or C==3, and R may be 1
%                 or cell vector of MxNxT or MxNxCxT matricies
%  prm
%   .showLines  - [1] whether to show lines separating the various frames
%   .extraInfo  - [0] if 1 then a colorbar is shown as well as impixelinfo
%   .cLim       - [] cLim = [clow chigh] optional scaling of data
%   .mm         - [] #images/col per montage
%   .nn         - [] #images/row per montage
%   .labels     - [] cell array of labels (strings) (T if R==1 else R)
%   .perRow     - [0] only if R>1 and not cell, alternative displays method
%   .padSize    - [4] only if perRow, amount to pad when in row mode
%   .hasChn     - [0] if true assumes IS is MxNxCxTxR else MxNxTxR
%
% OUTPUTS
%  h           - image handle
%  m           - #images/col
%  nn          - #images/row
%
% EXAMPLE - [2D] simply calls im
%  load( 'images.mat' );  clf; montage2( images(:,:,1) );
%
% EXAMPLE - [3D] show a montage of images
%  load( 'images.mat' );  clf; montage2( images );
%
% EXAMPLE - [3D] show a montage of images (with parameters specified)
%  load( 'images.mat' );
%  for i=1:50; labels{i}=['I-' int2str2(i,2)]; end
%  prm = struct('extraInfo',0,'perRow',0,'labels',{labels});
%  clf; montage2( images(:,:,1:50), prm );
%
% EXAMPLE - [4D] show a montage of several groups of pictures
%  for i=1:25; labels{i}=['V-' int2str2(i,2)]; end
%  prm = struct('labels',{labels});
%  load( 'images.mat' ); clf; montage2( videos(:,:,:,1:25), prm );
%
% EXAMPLE - [4D] show using 'row' format
%  load( 'images.mat' );
%  prm = struct('perRow',1,'padSize',10);
%  figure(1); clf; montage2( videos(:,:,:,1:10), prm );
%
% See also MONTAGE, PLAYMOVIE, FILMSTRIP

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function varargout = montage2( IS, prm )

if( nargin<2 ); prm=struct(); end
varargout = cell(1,nargout);

%%% get parameters (set defaults)
dfs = {'showLines',1, 'extraInfo',0, 'cLim',[], 'mm',[], 'nn',[],...
  'labels',[], 'perRow',false, 'padSize',4, 'hasChn',false };
prm = getPrmDflt( prm, dfs );
extraInfo=prm.extraInfo; labels=prm.labels;
perRow=prm.perRow; padSize=prm.padSize;  hasChn=prm.hasChn;

%%% If IS is not a cell convert to MxNxCxTxR array
if( iscell(IS) && numel(IS)==1 ); IS=IS{1}; end;
if( ~iscell(IS) && ndims(IS)>2 )
  siz=size(IS);
  if( ~hasChn );
    IS=reshape(IS,[siz(1:2),1,siz(3:end)]);
    prm.hasChn = true;
  end;
  if(ndims(IS)>5); error('montage2: input too large'); end;
end

%%% take care of special case where calling subMontage only once
if( ~iscell(IS) && size(IS,5)==1 );
  [varargout{:}] = subMontage(IS,prm);
  title(inputname(1));
  return;
end;

if( perRow ) %%% display each montage in row format
  [padSize,er] = checkNumArgs( padSize,[1 1], 0, 1 ); error(er);
  if(iscell(IS)); error('montage2: IS cannot be a cell if perRow'); end;

  % reshape IS so each 3D element is concatenated to a 2D image (and pad)
  padEl = max(IS(:)); siz = size(IS);
  IS=arrayToDims(IS, [siz(1)+padSize siz(2:end)], padEl );
  siz = size(IS);
  IS=reshape(permute(IS,[1 2 4 3 5]),siz(1),[],siz(3),siz(5));
  siz = size(IS);
  IS=arrayToDims(IS, [siz(1) siz(2)+padSize siz(3:end)], padEl);

  % show using subMontage
  if( nargout ); varargout{1}=IS; end
  prm.perRow = false;  prm.hasChn=true;
  [varargout{2:end}] = subMontage( IS, prm );
  title(inputname(1));

else %%% display each montage using subMontage

  % convert to cell array
  if( iscell(IS) )
    nMontages = numel(IS);
  else
    nMontages = size(IS,5);
    IS = squeeze(mat2cell2( IS, [1 1 1 1 nMontages] ));
  end

  % draw each montage
  clf;
  nn = ceil( sqrt(nMontages) ); mm = ceil(nMontages/nn);
  for i=1:nMontages
    subplot(mm,nn,i);
    prmSub=prm;  prmSub.extraInfo=0;  prmSub.labels=[];
    if( ~isempty(IS{i}) )
      subMontage( IS{i}, prmSub );
    else
      set(gca,'XTick',[]); set(gca,'YTick',[]);
    end
    if(~isempty(labels)); title(labels{i}); end
  end
  if( extraInfo ); impixelinfo; end;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this function is a generalized version of Matlab's montage.m
function varargout = subMontage( IS, prm )

% get parameters (set defaults)
dfs = {'showLines',1, 'extraInfo',0, 'cLim',[], 'mm',[], 'nn',[], ...
  'labels',[], 'perRow',false, 'hasChn',false };
prm = getPrmDflt( prm, dfs );
showLines=prm.showLines;   extraInfo=prm.extraInfo;  cLim=prm.cLim;
mm=prm.mm; nn=prm.nn;  labels=prm.labels;  hasChn=prm.hasChn;
if( prm.perRow ); mm=1; end;

% take care of single bw or color image (similar to im)
if( (size(IS,4)==1 && hasChn) || (size(IS,3)==1 && ~hasChn) )
  im( IS, cLim, extraInfo );
  if( length(labels)==1 ); title(labels{1}); else title(''); end
  return;
end

% get/test image format info and parameters
if( hasChn )
  if( ndims(IS)~=4 || ~any(size(IS,3)==[1 3]) )
    error('montage2: unsupported dimension of IS');end
else
  if( ndims(IS)~=3 );
    error('montage2: unsupported dimension of IS'); end
  IS = permute(IS, [1 2 4 3] );
end
siz = size(IS);  nCh=siz(3);  nIm = siz(4);
if( ~isempty(labels) && nIm~=length(labels) )
  error('montage2: incorrect number of labels');
end

% get layout of images (mm=#images/row, nn=#images/col)
if( isempty(mm) || isempty(nn))
  if( isempty(mm) && isempty(nn))
    nn = min( ceil(sqrt(siz(1)*nIm/siz(2))), nIm );
    mm = ceil( nIm/nn );
  elseif( isempty(mm) )
    nn = min( nn, nIm );
    mm = ceil(nIm/nn);
  else
    mm = min( mm, nIm );
    nn = ceil(nIm/mm);
  end
  % often can shrink dimension further
  while((mm-1)*nn>=nIm); mm=mm-1; end;
  while((nn-1)*mm>=nIm); nn=nn-1; end;
end

% Calculate I (M*mm x N*nn size image)
I = IS(1,1);
if(~isempty(cLim)); I(1,1)=cLim(1);  else  I(1,1)=min(IS(:)); end
I = repmat(I, [mm*siz(1), nn*siz(2), nCh]);
rows = 1:siz(1); cols = 1:siz(2);
for k=1:nIm
  I(rows+floor((k-1)/nn)*siz(1),cols+mod(k-1,nn)*siz(2),:) = IS(:,:,:,k);
end

% display I
if( ~isempty(cLim)); h=imagesc(I,cLim);  else  h=imagesc(I);  end
colormap(gray);  axis('image');
if( extraInfo )
  colorbar; impixelinfo;
else
  set(gca,'XTick',[]); set(gca,'YTick',[]);
end;

% draw lines separating frames
if( showLines )
  montageWd = nn * siz(2) + .5;  montageHt = mm * siz(1) + .5;
  for i=1:mm-1
    height = i*siz(1)+.5; line([.5,montageWd],[height,height]);
  end
  for i=1:nn-1
    width = i*siz(2)+.5; line([width,width],[.5,montageHt]);
  end
end

% plot text labels
textalign = { 'VerticalAlignment','bottom','HorizontalAlignment','left'};
if( ~isempty(labels) )
  count=1;
  for i=1:mm;
    for j=1:nn
      if( count<=nIm )
        rstart = i*siz(1); cstart =(j-1+.1)*siz(2);
        text(cstart,rstart,labels{count},'color','r',textalign{:});
        count = count+1;
      end
    end
  end
end

% cross out unused frames
[nns,mms] = ind2sub( [nn,mm], nIm+1 );
for i=mms-1:mm-1
  for j=nns-1:nn-1,
    rstart = (i+1)*siz(1)+.5; cstart =j*siz(2)+.5;
    cs = [cstart,cstart+siz(2)]; rs = [rstart,rstart-siz(1)];
    line( cs, rs );  line( fliplr(cs), rs );
  end
end

% optional output
if( nargout>0 ); varargout={h,mm,nn}; end
