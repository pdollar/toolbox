% [4D] Used to convert R sets of equal length videos into a single movie. 
%
% To display same data statically use montages.
% Works by calling montage2 once per frame.
%
% INPUTS
%   IS              - MxNxTxR or MxNx1xTxR or MxNx3xTxR array, or cell array where each
%                     element is an MxNxT or MxNx1xT or MxNx3xT array
%   montage2params  - [optional] params for montage2 -- ex: {showlines, extrainfo}
%
% OUTPUTS
%   M               - resulting movie
%
% EXAMPLE
%   load( 'images.mat' );
%   M = makemovies( videos );
%   movie( M );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MONTAGES, MONTAGE2, MAKEMOVIE, MAKEMOVIESETS, PLAYMOVIES

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function M = makemovies( IS, montage2params )
    if( nargin<2 ) montage2params = cell(1,5); end;

    %%% get/test image format info
    if( iscell(IS)) IS = cell2array(IS); end; %convert to array if is cell struct
    nd = ndims(IS);    
    if( nd==4) %MxNxTxR
        nframes = size(IS,3);    
    elseif( nd==5) %MxNx1xTxR or MxNx3xTxR
        nframes = size(IS,4);
        nch = size(IS,3);  legal = (nch==1 || nch==3);
        if( ~legal ) error('illegal image stack format'); end;        
    else
        error('unsupported dimension of IS');
    end;
    clim = [min(IS(:)) max(IS(:))];
    montage2params{3} = clim;
    
    %%% pad I so as to give small border in spatial direction
    padsiz = zeros( ndims(IS)-1,1 ); padsiz(1:2)=1;
    IS = padarray( IS, padsiz, min(IS(:)), 'both' );    

    
    %%% make the movie by calling montage2 and getframe repeatedly
    h=figureresized(.8); 
    for i=1:nframes
        if( nd==4) % MxNxTxR
            montage2( IS(:,:,i,:), montage2params{:} );
        else  % MxNx1xTxR or MxNx3xTxR
            montage2( squeeze(IS(:,:,:,i,:)), montage2params{:} );
        end
        M(i) = getframe; 
    end    
    close(h);
