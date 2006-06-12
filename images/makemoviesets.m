% [5D] Used to convert S sets of R videos into a movie.
%
% Each group of videos is shown in a subplot. 
% Works by calling montages once per frame.
%
% INPUTS
%   IS              - MxNxTxRxS or MxNx1xTxRxS or MxNx3xTxRxS array, or cell array where
%                     each element is an MxNxTxR or MxNx1xTxR or MxNx3xTxR array
%   montagesparams  - [optional] cell array of params for montages
%
% OUTPUTS
%   M               - resulting movie
%
% EXAMPLE
%   load( 'images.mat' );
%   videoclusters = clustermontage( videos, IDXv, 9, 1 );
%   M = makemoviesets( videoclusters );
%   movie( M );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MAKEMOVIE, MAKEMOVIESETS2, CLUSTERMONTAGE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function M = makemoviesets( IS, montagesparams )
    if( nargin<2 ) montagesparams = {}; end;
    if( isempty(montagesparams) || isempty(montagesparams{1}))
        params2 = cell(1,6);
    else
        params2 = [montagesparams{1} cell(1,5-length(montagesparams{1}))];
    end
        
    %%% get/test image format info
    if( iscell(IS))
        nclusters = prod( size(IS) );
        nd = ndims(IS{1}); for i=1:nclusters nd=max(nd,ndims(IS{i})); end;
        for i=2:nclusters if(~any(ndims(IS{i})==[nd nd-1]))
                error('All elements of IS must have same dims'); end; end;
        if( nd==4 ) % MxNxTxRxcS
            nframes = size(IS{1},3); 
        elseif( nd==5 ) % MxNx1xTxRxcS or MxNx3xTxRxcS
            nframes = size(IS,4); 
        else 
            error('unsupported dimension of IS');
        end;
        clim=[inf -inf]; for i=1:nclusters 
            A=IS{i}(:); if(isempty(A)) continue; end;
            clim(1)=min(clim(1),min(A)); 
            clim(2)=max(clim(2),max(A)); 
        end;
    else
        nd = ndims(IS);    
        if( nd==5 ) % MxNxTxRxS
            nframes = size(IS,3); nclusters = size(IS,5);
        elseif( nd==6 ) % MxNx1xTxRxS or MxNx3xTxRxS
            nframes = size(IS,4); nclusters = size(IS,6);
        else 
            error('unsupported dimension of IS');
        end;        
        A=IS(:); clim=[min(A) max(A)];
    end;    
    params2{3} = clim;  montagesparams{1}=params2;
    
    %%% make the movie by calling montages and getframe repeatedly
    h=figureresized(.8);  axis off;
    for f=1:nframes
        if( iscell( IS ) )
            ISf = cell(1,nclusters);
            for c=1:nclusters
                if( nd==4 ) 
                    ISf{c} = squeeze( IS{c}(:,:,f,:) );
                else 
                    ISf{c} = squeeze( IS{c}(:,:,:,f,:) ); 
                end
            end
            montages( ISf, montagesparams{:} );
        elseif( ndims(IS)==5 )
            montages( squeeze(IS(:,:,f,:,:)), montagesparams{:} );
        else 
            montages( squeeze(IS(:,:,:,f,:,:)), montagesparams{:} );
        end;
        
        M(f) = getframe(h);
    end
    close(h);
    
