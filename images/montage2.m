function varargout = montage2( IS, prm )
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
%                 or cell vector of MxNxT or MxNxCxT matrices
%  prm
%   .showLines  - [1] whether to show lines separating the various frames
%   .extraInfo  - [0] if 1 then a colorbar is shown as well as impixelinfo
%   .cLim       - [] cLim = [clow chigh] optional scaling of data
%   .mm         - [] #images/col per montage
%   .nn         - [] #images/row per montage
%   .labels     - [] cell array of labels (strings) (T if R==1 else R)
%   .perRow     - [0] only if R>1 and not cell, alternative displays method
%   .hasChn     - [0] if true assumes IS is MxNxCxTxR else MxNxTxR
%   .padAmt     - [0] only if perRow, amount to pad when in row mode
%   .padEl      - [] pad element, defaults to min value in IS
%
% OUTPUTS
%  h           - image handle
%  m           - #images/col
%  nn          - #images/row
%
% EXAMPLE - [3D] show a montage of images
%  load( 'images.mat' ); clf; montage2( images );
%
% EXAMPLE - [3D] show a montage of images with labels
%  load( 'images.mat' );
%  for i=1:50; labels{i}=['I-' int2str2(i,2)]; end
%  prm = struct('extraInfo',1,'perRow',0,'labels',{labels});
%  clf; montage2( images(:,:,1:50), prm );
%
% EXAMPLE - [3D] show a montage of images with color boundaries
%  load( 'images.mat' );
%  I3 = repmat(permute(images,[1 2 4 3]),[1,1,3,1]); % add color chnls
%  prm = struct('padAmt',4,'padEl',[50 180 50],'hasChn',1,'showLines',0);
%  clf; montage2( I3(:,:,:,1:48), prm )
%
% EXAMPLE - [4D] show a montage of several groups of images
%  for i=1:25; labels{i}=['V-' int2str2(i,2)]; end
%  prm = struct('labels',{labels});
%  load( 'images.mat' ); clf; montage2( videos(:,:,:,1:25), prm );
%
% EXAMPLE - [4D] show using 'row' format
%  load( 'images.mat' );
%  prm = struct('perRow',1, 'padAmt',6, 'padEl',255 );
%  figure(1); clf; montage2( videos(:,:,:,1:10), prm );
%
% See also MONTAGE, PLAYMOVIE, FILMSTRIP
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 ); prm=struct(); end
varargout = cell(1,nargout);

%%% get parameters (set defaults)
dfs = {'showLines',1, 'extraInfo',0, 'cLim',[], 'mm',[], 'nn',[],...
  'labels',[], 'perRow',false, 'padAmt',0, 'padEl',[], 'hasChn',false };
prm = getPrmDflt( prm, dfs );
extraInfo=prm.extraInfo; labels=prm.labels;  perRow=prm.perRow;
hasChn=prm.hasChn;

%%% If IS is not a cell convert to MxNxCxTxR array
if( iscell(IS) && numel(IS)==1 ); IS=IS{1}; end;
if( ~iscell(IS) && ~ismatrix(IS) )
  siz=size(IS);
  if( ~hasChn );
    IS=reshape(IS,[siz(1:2),1,siz(3:end)]);
    prm.hasChn = true;
  end;
  if(ndims(IS)>5); error('montage2: input too large'); end;
end


if( ~iscell(IS) && size(IS,5)==1 ) %%% special case call subMontage once
  [varargout{:}] = subMontage(IS,prm);
  title(inputname(1));

elseif( perRow ) %%% display each montage in row format
  if(iscell(IS)); error('montage2: IS cannot be a cell if perRow'); end;
  siz = size(IS);
  IS=reshape(permute(IS,[1 2 4 3 5]),siz(1),[],siz(3),siz(5));
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

function varargout = subMontage( IS, prm )
% this function is a generalized version of Matlab's montage.m

% get parameters (set defaults)
dfs = {'showLines',1, 'extraInfo',0, 'cLim',[], 'mm',[], 'nn',[], ...
  'labels',[], 'perRow',false, 'hasChn',false, 'padAmt',0, 'padEl',[] };
prm = getPrmDflt( prm, dfs );
showLines=prm.showLines;   extraInfo=prm.extraInfo;  cLim=prm.cLim;
mm=prm.mm; nn=prm.nn;  labels=prm.labels;  hasChn=prm.hasChn;
padAmt=prm.padAmt;  padEl=prm.padEl;
if( prm.perRow ); mm=1; end;

% get/test image format info and parameters
if( hasChn )
  if( ndims(IS)>4 || ~any(size(IS,3)==[1 3]) )
    error('montage2: unsupported dimension of IS'); end
else
  if( ndims(IS)>3 );
    error('montage2: unsupported dimension of IS'); end
  IS = permute(IS, [1 2 4 3] );
end
siz = size(IS);  nCh=size(IS,3);  nIm = size(IS,4);  sizPad=siz+padAmt;
if( ~isempty(labels) && nIm~=length(labels) )
  error('montage2: incorrect number of labels');
end

% set up the padEl correctly (must have same type / nCh as IS)
if(isempty(padEl))
  if(isempty(cLim)); padEl=min(IS(:)); else padEl=cLim(1); end; end
if(length(padEl)==1); padEl=repmat(padEl,[1 nCh]); end;
if(length(padEl)~=nCh); error( 'invalid padEl' ); end;
padEl = feval( class(IS), padEl );
padEl = reshape( padEl, 1, 1, [] );
padAmt = floor(padAmt/2 + .5)*2;

% get layout of images (mm=#images/row, nn=#images/col)
if( isempty(mm) || isempty(nn))
  if( isempty(mm) && isempty(nn))
    nn = min( ceil(sqrt(sizPad(1)*nIm/sizPad(2))), nIm );
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
I = repmat(padEl, [mm*sizPad(1), nn*sizPad(2), 1]);
rows = 1:siz(1); cols = 1:siz(2);
for k=1:nIm
  rowsK = rows + floor((k-1)/nn)*sizPad(1)+padAmt/2;
  colsK = cols + mod(k-1,nn)*sizPad(2)+padAmt/2;
  I(rowsK,colsK,:) = IS(:,:,:,k);
end

% display I
if( ~isempty(cLim)); h=imagesc(I,cLim);  else  h=imagesc(I);  end
colormap(gray);  axis('image');
if( extraInfo )
  colorbar; impixelinfo;
else
  set(gca,'Visible','off')
end

% draw lines separating frames
if( showLines )
  montageWd = nn * sizPad(2) + .5;
  montageHt = mm * sizPad(1) + .5;
  for i=1:mm-1
    ht = i*sizPad(1) +.5; line([.5,montageWd],[ht,ht]);
  end
  for i=1:nn-1
    wd = i*sizPad(2) +.5; line([wd,wd],[.5,montageHt]);
  end
end

% plot text labels
textalign = { 'VerticalAlignment','bottom','HorizontalAlignment','left'};
if( ~isempty(labels) )
  count=1;
  for i=1:mm;
    for j=1:nn
      if( count<=nIm )
        rStr = i*sizPad(1)-padAmt/2;
        cStr =(j-1+.1)*sizPad(2)+padAmt/2;
        text(cStr,rStr,labels{count},'color','r',textalign{:});
        count = count+1;
      end
    end
  end
end

% cross out unused frames
[nns,mms] = ind2sub( [nn,mm], nIm+1 );
for i=mms-1:mm-1
  for j=nns-1:nn-1,
    rStr = i*sizPad(1)+.5+padAmt/2; rs = [rStr,rStr+siz(1)];
    cStr = j*sizPad(2)+.5+padAmt/2; cs = [cStr,cStr+siz(2)];
    line( cs, rs );  line( fliplr(cs), rs );
  end
end

% optional output
if( nargout>0 ); varargout={h,mm,nn}; end
