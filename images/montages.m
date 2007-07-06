% [4D] Used to display R sets of T images each.
%
% Displays one montage (see montage2) per subplot.
%
% USAGE
%  varargout = montages( IS, [montage2prms], [labels], [montage2lbls] )
%
% INPUTS
%   IS            - MxNxTxR or MxNx1xTxR or MxNx3xTxR array, or cell array 
%                   where each element is MxNxT or MxNx1xT or MxNx3xT
%   montage2prms  - [] params for montage2 EXCEPT labels; ex: {showLns}
%   labels        - [] cell array of titles for subplots
%   montage2lbls  - [] cell of cells of strngs: montage2 lbls for subplots
%
% OUTPUTS
%   mm            - #montages/row
%   nn            - #montages/col
%
% EXAMPLE
%  load( 'images.mat' );
%  imClusters = clustermontage( images, IDXi, 16, 1 );
%  montages( imClusters );
%
% See also MONTAGES2, MAKEMOVIES, MONTAGE2, CLUSTERMONTAGE

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function varargout = montages( IS, montage2prms, labels, montage2lbls )

if( nargin<2 ); montage2prms = {}; end;
if( nargin<3 ); labels = {}; end;
if( nargin<4 ); montage2lbls = {}; end;

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
  if( ~legal ); error('illegal image stack format'); end;
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
