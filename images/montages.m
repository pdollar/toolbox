% [4D] Used to display R sets of T images each.
%
% Displays one montage (see montage2) per subplot. 
%
% INPUTS
%   IS               - MxNxTxR or MxNx1xTxR or MxNx3xTxR array, or cell array where each
%                      element is an MxNxT or MxNx1xT or MxNx3xT array
%   montage2params   - [optional] params for montage2 EXCEPT labels; ex: {showlines}
%   lables           - [optional] cell array of strings - titles for subplots
%   montage2labels   - [optional] cell of cells of strings: montage2 lables for subplots
%
% OUTPUTS
%   mm          - #montages/row 
%   nn          - #montages/col
%
% EXAMPLE
%   load( 'images.mat' );
%   imageclusters = clustermontage( images, IDXi, 16, 1 );
%   montages( imageclusters );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MONTAGES2, MAKEMOVIES, MONTAGE2, CLUSTERMONTAGE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function varargout = montages( IS, montage2params, labels, montage2labels )
    if( nargin<2 ) montage2params = {}; end;
    if( nargin<3 ) labels = {}; end;
    if( nargin<4 ) montage2labels = {}; end;    
    
    %%% set up parameters for montage2
    nparams = length(montage2params);
    if( nparams>5 ) 
        % montage2labels must be particular to each montage2
        montage2params=montage2params(1:5);  
        extrainfo = [];
    else
        % pad montage2params appropriately
        montage2params=[montage2params cell(1,5-nparams)]; 
        % no extrainfo per subplot
        extrainfo = montage2params{2}; montage2params{2} = 0; 
    end
    
    %%% get/set clim
    if( isempty(montage2params{3}) ) 
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
        montage2params{3} = clim; 
    end;
    
    
    %%% get/test image format info
    nd = ndims(IS);
    if( iscell(IS)) %testing for dims done in montage2
        nmontages = prod(size(IS));
    elseif( nd==4)  %MxNxTxR
        nmontages = size(IS,4);
    elseif( nd==5)  %MxNx1xTxR or MxNx3xTxR
        nmontages = size(IS,5);
        nch = size(IS,3);  legal = (nch==1 || nch==3);
        if( ~legal ) error('illegal image stack format'); end;        
    else
        error('unsupported dimension of IS');
    end;
    if( isempty(montage2labels)) montage2labels=cell(1,nmontages); end;

    
    %%% get layout of images (mm=#montages/row, nn=#montages/col)
    nn = ceil( sqrt(nmontages) );
    mm = ceil( nmontages/nn );

    %%% draw each montage
    for i=1:nmontages
        subplot(mm,nn,i);  
        if( iscell(IS) )
            if( ~isempty(IS{i}) ) 
                montage2( IS{i}, montage2params{:}, montage2labels{i} ); 
            else
                set(gca,'XTick',[]); set(gca,'YTick',[]);  %extrainfo off
            end;
        elseif( nd==4)  
            montage2( IS(:,:,:,i), montage2params{:}, montage2labels{i}  );
        else
            montage2( IS(:,:,:,:,i), montage2params{:}, montage2labels{i}  );
        end
        if(~isempty(labels)) title(labels{i}); end;        
    end
    if( ~isempty(extrainfo) && extrainfo) pixval on; end;
    
    %%% optional output
    if( nargout>0 ) varargout={mm,nn}; end    
