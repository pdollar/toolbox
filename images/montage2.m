% [3D] Used to display a stack of T images.
%
% Improved version of montage, with more control over display.
% NOTE: Can convert between MxNxT and MxNx3xT image stack via:
%   I = repmat( I, [1,1,1,3] ); I = permute(I, [1,2,4,3] );
%
% USAGE
%  varargout = montage2( IS, showlines, extrainfo, clim, mm, nn, labels )
%
% INPUTS
%  IS          - MxNxT or MxNx1xT or MxNx3xT array (of bw or color images)
%  showlines   - [optional] whether to show lines separating the various
%                frames
%  extrainfo   - [optional] if 1 then a colorbar is shown as well as pixval
%                bar
%  clim        - [optional] clim = [clow chigh] optional scaling of data
%  m           - [optional] #images/col (if [] then calculated)
%  nn          - [optional] #images/row (if [] then calculated)
%  labels      - [optional] cell array of strings specifying labels for
%  each image
%
% OUTPUTS
%  h           - image handle
%  m           - #images/col
%  nn          - #images/row
%
% EXAMPLE
%  load( 'images.mat' );
%  montage2( images );
%
% See also MONTAGE, MAKEMOVIE

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function varargout = montage2( IS, showlines, extrainfo, clim, mm, nn, ...
  labels )

if (nargin<2 || isempty(showlines)); showlines = 0; end;
if (nargin<3 || isempty(extrainfo)); extrainfo = 0; end;
if (nargin<4 || isempty(clim)); clim = []; end;
if (nargin<5 || isempty(mm)); mm = []; end;
if (nargin<6 || isempty(nn)); nn = []; end;
if (nargin<7 || isempty(labels)); labels = {}; end;

% take care of single images
if( ndims(IS)==2)
  if(~isempty(clim)); h=imagesc(IS,clim); else h=imagesc(IS); end;
  title(inputname(1)); colormap(gray);  axis('image');
  if(extrainfo)
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
if( extrainfo)
  colorbar; impixelinfo;
else
  set(gca,'XTick',[]); set(gca,'YTick',[]);
end;

% draw lines seperating frames
if( showlines )
  montage_width = nn * siz(2) + .5;  montage_height = mm * siz(1) + .5;
  for i=1:mm-1
    height = i*siz(1)+.5; line([.5,montage_width],[height,height]); 
  end
  for i=1:nn-1
    width = i*siz(2)+.5; line([width,width],[.5,montage_height]);
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

