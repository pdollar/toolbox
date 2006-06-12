% [4D] shows R videos simultaneously as a movie.
%
% INPUTS
%   I       - MxNxTxR or MxNx1xTxR or MxNx3xTxR array (if MxNxT calls playmovie)
%   fps     - [optional] maximum number of frames to display per second
%             use fps==0 to introduce no pause and have the movie play as fast as possible
%   loop    - [optional] number of time to loop video (may be inf)
%             if neg plays video forward then backward then forward etc.
%
% EXAMPLE
%   load( 'images.mat' );
%   playmovies( videos );
%
% DATESTAMP
%   22-May-2006  5:00pm
%
% See also MONTAGES, PLAYMOVIE, MAKEMOVIES

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function playmovies( I, fps, loop )
    if( nargin<2 || isempty(fps)) fps = 100; end;
    if( nargin<3 || isempty(loop)) loop = 1; end;

    nd=ndims(I); siz=size(I); nframes=siz(end-1);
    if( nd==3 ) playmovie( I, fps, loop ); return; end;
    if( iscell(I) ) error('cell arrays not supported.'); end;
    if( ~(nd==4 || (nd==5 && any(size(I,3)==[1 3]))) )
        error('unsupported dimension of I'); end;
    inds={':'}; inds=inds(:,ones(1,nd-2));   
    clim = [min(I(:)),max(I(:))];

    h=gcf; colormap gray; figure(h); % bring to focus    
    nplayed=0; 
    while( nplayed < abs(loop) )
        if( loop<0 && mod(nplayed,2)==1 )
            order = nframes:-1:1;
        else
            order = 1:nframes;
        end;
        for i=order
            geth=get(h); %figure was closed, cannot continue display
            montage2(squeeze(I(inds{:},i,:)),1,[],clim); 
            title(sprintf('frame %d of %d',i,nframes));
            if(fps>0) pause(1/fps); else pause(eps); end;
        end;
        nplayed=nplayed+1;
    end;
