% [4D] Used to display R sets of T images each.
%
% Displays one montage (see montage2) per subplot.
% Displays one montage (see montage2) per row.  Each of the R image sets is
% flattened to a single long image by concatenating the T images in the
% set
%
% USAGE
%  varargout = montages( IS, [montage2prms], [labels], [montage2lbls] )
%
% INPUTS - 1 Displays one montage (see montage2) per subplot.
%  IS            - MxNxTxR or MxNx1xTxR or MxNx3xTxR array, or cell array
%                  where each element is MxNxT or MxNx1xT or MxNx3xT
%  montage2prms  - [] params for montage2 EXCEPT labels; ex: {showLns}
%  labels        - [] cell array of titles for subplots
%  montage2lbls  - [] cell of cells of strngs: montage2 lbls for subplots
%
% INPUTS - 2 Displays one montage (see montage2) per row
%  IS             - MxNxTxR or MxNx1xTxR or MxNx3xTxR array
%  montage2prms   - [] params for montage2; ex: {showLns,extraInf}
%  labels         - [] total amount of vertical or horizontal padding
%
% OUTPUTS - 1
%  mm             - #montages/row
%  nn             - #montages/col
%
% OUTPUTS - 2
%  I              - 3D or 4D array of flattened images, disp with montage2
%  mm             - #montages/row
%  nn             - #montages/col
%
% EXAMPLE
%  load( 'images.mat' );
%  imClusters = clustermontage( images, IDXi, 16, 1 );
%  montages( imClusters );
%
% See also MAKEMOVIES, MONTAGE2, CLUSTERMONTAGE

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function varargout = montages( IS, montage2prms, labels, montage2lbls )

if( nargin<2 || isempty(montage2prms)); montage2prms = {}; end
if( nargin<3 || isempty(labels) )
  labels = {};
else
  if isnumeric(labels)
    padSiz=labels;
    [padSiz,er] = checknumericargs( padSiz,[1 1], 0, 1 ); error(er);

    % get/test image format info
    nd = ndims(IS); siz = size(IS);
    if( nd==5 )  %MxNx1xTxR or MxNx3xTxR
      nch = size(IS,3);
      if( nch~=1 && nch~=3 ); error('illegal image stack format'); end
      if( nch==1 ); IS = squeeze(IS); nd=4; siz=size(IS); end
    end
    if ~any(nd==3:5)
      error('unsupported dimension of IS');
    end

    % reshape IS so that each 3D element is concatenated to a 2D image, 
    % adding padding
    padEl = max(IS(:));
    IS=arraycrop2dims(IS, [siz(1)+padSiz siz(2:end)], padEl ); %UD pad
    siz=size(IS);
    if(nd==3) % reshape bw single
      IS=squeeze( reshape( IS, siz(1), [] ) );
    elseif(nd==4) % reshape bw
      IS=squeeze( reshape( IS, siz(1), [], siz(4) ) );
    else % reshape color
      IS=squeeze(reshape(permute(IS,[1 2 4 3 5]),siz(1),[],siz(3),siz(5)));
    end; siz = size(IS);
    IS=arraycrop2dims(IS, [siz(1) siz(2)+padSiz siz(3:end)], padEl);

    % show using montage2
    varargout = cell(1,nargout);
    if( nargout); varargout{1}=IS; end
    [varargout{2:end}] = montage2( IS, montage2prms{:} );
    title(inputname(1));
    return;
  end
end

if( nargin<4 ); montage2lbls = {}; end

% set up parameters for montage2
nparams = length(montage2prms);
if( nparams>5 )
  % montage2lbls must be particular to each montage2
  montage2prms=montage2prms(1:5);
  extraInf = [];
else
  % pad montage2prms appropriately
  montage2prms=[montage2prms cell(1,5-nparams)];
  % no extraInf per subplot
  extraInf = montage2prms{2}; montage2prms{2} = 0;
end

% get/set clim
if( isempty(montage2prms{3}) )
  if( iscell(IS) )
    clim = [inf -inf];
    for i=1:length(IS)
      I = IS{i}(:);
      clim(1)=min(clim(1),min(I));
      clim(2)=max(clim(2),max(I));
    end
  else
    clim = [min(IS(:)),max(IS(:))];
  end
  montage2prms{3} = clim;
end


% get/test image format info
nd = ndims(IS);
if( iscell(IS)) %testing for dims done in montage2
  nmontages = numelem(IS);
elseif( nd==4)  %MxNxTxR
  nmontages = size(IS,4);
elseif( nd==5)  %MxNx1xTxR or MxNx3xTxR
  nmontages = size(IS,5);
  nch = size(IS,3);  legal = (nch==1 || nch==3);
  if( ~legal ); error('illegal image stack format'); end
else
  error('unsupported dimension of IS');
end
if( isempty(montage2lbls)); montage2lbls=cell(1,nmontages); end

% get layout of images (mm=#montages/row, nn=#montages/col)
nn = ceil( sqrt(nmontages) );
mm = ceil( nmontages/nn );

% draw each montage
for i=1:nmontages
  subplot(mm,nn,i);
  if( iscell(IS) )
    if( ~isempty(IS{i}) )
      montage2( IS{i}, montage2prms{:}, montage2lbls{i} );
    else
      set(gca,'XTick',[]); set(gca,'YTick',[]);  %extraInf off
    end;
  elseif( nd==4)
    montage2( IS(:,:,:,i), montage2prms{:}, montage2lbls{i}  );
  else
    montage2( IS(:,:,:,:,i), montage2prms{:}, montage2lbls{i}  );
  end
  if(~isempty(labels)); title(labels{i}); end
end
if( ~isempty(extraInf) && extraInf); pixval on; end

% optional output
if( nargout>0 ); varargout={mm,nn}; end
