% [5D] Used to convert S sets of R videos into a movie.
%
% Displays one set per row.  Each of the S sets is flattened to a single long image by
% concatenating the T images in the set.
%
% Alternative to makemoviesets.
% Works by calling montages2 once per frame.
%
% INPUTS
%   IS              - MxNxTxRxS or MxNx1xTxRxS or MxNx3xTxRxS array
%   montagesparams  - [optional] cell array of params for montages2
%
% OUTPUTS
%   M               - resulting movie
%
% EXAMPLE
%   load( 'images.mat' );
%   videoclusters = clustermontage( videos, IDXv, 9, 1 );
%   M = makemoviesets2( videoclusters );
%   movie( M );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MAKEMOVIE, MAKEMOVIESETS, CLUSTERMONTAGE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function M = makemoviesets2( IS, montagesparams )
    if( nargin<2 ) montagesparams = {}; end;
    if( isempty(montagesparams) || isempty(montagesparams{1}))
        params2 = cell(1,6);
    else
        params2 = [montagesparams{1} cell(1,5-length(montagesparams{1}))];
    end
        
    %%% get/test image format info
    nd = ndims(IS);    
    if( nd==5 ) % MxNxTxRxS
        nframes = size(IS,3); nclusters = size(IS,5);
    elseif( nd==6 ) % MxNx1xTxRxS or MxNx3xTxRxS
        nframes = size(IS,4); nclusters = size(IS,6);
    else 
        error('unsupported dimension of IS');
    end;        
    A=IS(:); clim=[min(A) max(A)];
    params2{3} = clim;  montagesparams{1}=params2;
    
    %%% make the movie by calling montages and getframe repeatedly
    h=figureresized(.8);  axis off;
    for f=1:nframes
        if( ndims(IS)==5 )
            montages2( squeeze(IS(:,:,f,:,:)), montagesparams{:} );
        else 
            montages2( squeeze(IS(:,:,:,f,:,:)), montagesparams{:} );
        end;
        M(f) = getframe(h);
    end
    close(h);
    
