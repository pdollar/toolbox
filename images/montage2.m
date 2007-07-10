% [5D] Used to display a stack of T images.
%
% Improved version of montage, with more control over display.
% NOTE: Can convert between MxNxT and MxNx3xT image stack via:
%   I = repmat( I, [1,1,1,3] ); I = permute(I, [1,2,4,3] );
%
% USAGE
%  varargout = montage2(IS,[showLns],[extraInf],[clim],[mm],[nn],[labels])
%
% INPUTS
%  IS          - MxNxTxR or MxNx1xTxR or MxNx3xTxR array 
%                (of bw or color images). R can equal 1
%  prm
%   .showLns    - [0] whether to show lines separating the various frames
%   .extraInf   - [0] if 1 then a colorbar is shown as well as pixval bar
%   .clim       - [] clim = [clow chigh] optional scaling of data
%   .mm         - [] #images/col (if [] then calculated)
%   .nn         - [] #images/row (if [] then calculated)
%   .label      - [] cell array of strings specifying labels for each image
%   .perRow     - [0] displays several movies in rows
%   .padSize    - [4] used to pad when in row mode
%   .montageLabel- list of labels for groups of movies
%
% OUTPUTS
%  h           - image handle
%  m           - #images/col
%  nn          - #images/row
%
% EXAMPLE - 1
%
%  load( 'images.mat' );
%  imClusters = clustermontage( images, IDXi, 16, 1 );
%  figure(1); montage2( imClusters, struct('perRow',1,'padSize',1) );
%  figure(2); montage2( videos, struct('perRow',1));
%
% EXAMPLE - 2
%
%  load( 'images.mat' ); montage2( videos );
%
% EXAMPLE - 3
%
%  load( 'images.mat' ); montage2( images );
%
% See also MONTAGE, PLAYMOVIE

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function varargout = montage2( IS, prm )

if nargin<2; prm=struct(); end

%%% get parameters (set defaults)
dfs = {'showLine',0,'extraInf',0,'clim',[],'mm',[],'nn',[],...
  'label',[],'perRow',false,'padSize',4,'montageLabel',[]};
prm = getPrmDflt( prm, dfs );
extraInf=prm.extraInf;
label=prm.label; perRow=prm.perRow; padSize=prm.padSize;
montageLabel=prm.montageLabel;

%%% Deal with the special way of doing a montage
if perRow
  [padSize,er] = checkNumArgs( padSize,[1 1], 0, 1 ); error(er);

  if iscell(IS)
    error('Invalid input, IS cannot be a cell');
  end
  if ~any(size(IS,3)==[1 3]);
    siz=size(IS); IS=reshape(IS,[siz(1),siz(2),1,siz(3:end)]);
  else
    error('Invalid input, IS has to be MxNxT or MxNx1xT or MxNx3xTxR');
  end
  % reshape IS so that each 3D element is concatenated to a 2D image,
  % adding padding
  padEl = max(IS(:));
  siz=size(IS); nd=ndims(IS);
  IS=arrayCrop(IS, ones(1,nd), [siz(1)+padSize siz(2:end)], padEl );%UD pad
  siz=size(IS);
  switch nd
    case 4
      IS=squeeze( reshape( IS, siz(1), [], siz(4) ) );
    case 5
      IS=squeeze(reshape(permute(IS,[1 2 4 3 5]),size(IS,1),[],...
        size(IS,3),size(IS,5)));
  end
  siz=size(IS); nd=ndims(IS);
  IS=arrayCrop(IS, [(1-padSize)*[1 1], ones(1,nd-2)], ...
    [siz(1) siz(2)+padSize siz(3:end)], padEl);

  % show using subMontage
  varargout = cell(1,nargout);
  if( nargout); varargout{1}=IS; end
  prm.perRow=false;
  [varargout{2:end}] = subMontage( IS, prm );
  title(inputname(1));
  return
end


%%% Otherwise, display each montage
siz=size(IS);
if ~iscell(IS)
  if ~any(size(IS,3)==[1 3]); IS=reshape(IS,[siz(1:2),1,siz(3:end)]); end
  IS2=cell(1,size(IS,5));
  for i=1:size(IS,5); IS2{i}=IS(:,:,:,:,i); end
  IS=IS2; clear IS2;
end

nmontages = numel(IS);

if numel(IS)>1; 
  nn2 = ceil( sqrt(nmontages) ); mm2 = ceil(nmontages/nn2); 
else
  mm2=1; nn2=1;
end

% draw each montage
for i=1:nmontages
  subplot(mm2,nn2,i);

  prm2=prm;
  if ~isempty(montageLabel); prm2.label=prm.montageLabel{i}; end
  if( ~isempty(IS{i}) )
    subMontage( IS{i}, prm2 );
  else
    set(gca,'XTick',[]); set(gca,'YTick',[]);  %extraInf off
  end
  if(~isempty(label)); title(label{i}); end
end
if extraInf; pixval on; end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout=subMontage( IS, prm )

dfs = {'showLine',0,'extraInf',0,'clim',[],'mm',[],'nn',[],...
  'labels',[],'perRow',false,'padSize',0};

prm = getPrmDflt( prm, dfs );  showLine=prm.showLine;
extraInf=prm.extraInf;  clim=prm.clim; mm=prm.mm; nn=prm.nn;
labels=prm.labels;

% take care of single images
if( ndims(IS)==2)
  if(~isempty(clim)); h=imagesc(IS,clim); else h=imagesc(IS); end;
  title(inputname(1)); colormap(gray);  axis('image');
  if(extraInf)
    colorbar; pixval on;
  else
    set(gca,'XTick',[]); set(gca,'YTick',[]);
  end
  if( nargout>0 ); varargout={h,1,1}; end;
  return;
end

% get/test image format info
if( ndims(IS)==3); IS = permute(IS, [1 2 4 3] ); end
if( ndims(IS)~=4 ); error('unsupported dimension of IS'); end
siz = size(IS);  nch = siz(3);
if( nch~=1 && nch~=3 ); error('illegal image stack format'); end
if( ~isempty(labels) && siz(4)~=length(labels) )
  error('incorrect number of labels');
end

% get layout of images (mm=#images/row, nn=#images/col) (bit hacky!!!)
if( isempty(mm) || isempty(nn))
  if( isempty(mm) && isempty(nn))
    nn = ceil(sqrt(siz(1)*siz(2)*siz(4)) / siz(2));
    mm = ceil(siz(4)/nn);
  elseif( isempty(mm))
    mm = ceil(siz(4)/nn);
  else
    nn = ceil(siz(4)/mm);
  end
end

% Calculate I (M*mm x N*nn size image)
I = IS(1,1);
if(~isempty(clim)); I(1,1) = clim(1);  else  I(1,1) = min(IS(:)); end
I = repmat(I, [mm*siz(1), nn*siz(2), nch]);
rows = 1:siz(1); cols = 1:siz(2);
for k=1:siz(4)
  I(rows+floor((k-1)/nn)*siz(1),cols+mod(k-1,nn)*siz(2),:) = IS(:,:,:,k);
end

% display I
if( ~isempty(clim)); h=imagesc(I,clim);  else  h=imagesc(I);  end
colormap(gray);  title(inputname(1));  axis('image');
if( extraInf)
  colorbar; impixelinfo;
else
  set(gca,'XTick',[]); set(gca,'YTick',[]);
end;

% draw lines separating frames
if( showLine )
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
  for i=1:mm
    for j=1:nn
      if( count<=siz(4))
        rstart = i*siz(1); cstart =(j-1+.1)*siz(2);
        text(cstart,rstart,labels{count},'color','r',textalign{:});
        count = count+1;
      end
    end
  end
end

% cross out unused frames
[nns,mms] = ind2sub( [nn,mm], siz(4)+1 );
for i=mms-1:mm-1
  for j=nns-1:nn-1,
    rstart = (i+1)*siz(1)+.5; cstart =j*siz(2)+.5;
    cs = [cstart,cstart+siz(2)]; rs = [rstart,rstart-siz(1)];
    line( cs, rs );  line( fliplr(cs), rs );
  end
end

% optional output
if( nargout>0 ); varargout={h,mm,nn}; end
