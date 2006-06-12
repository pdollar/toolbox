% [3D] Used to convert a stack of T images into a movie.  
%
% To display same data statically use montage.
%
% INPUTS
%   IS              - MxNxT or MxNx1xT or MxNx3xT array of movies.
%
% OUTPUTS
%   M               - resulting movie
%
% EXAMPLE
%   load( 'images.mat' );
%   M = makemovie( videos(:,:,:,1) );
%   movie( M );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MONTAGE2, MAKEMOVIES, PLAYMOVIE, CELL2ARRAY, FEVAL_ARRAYS, IMMOVIE, MOVIE2AVI

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function M = makemovie( IS )

    % get images format (if image stack is MxNxT convert to MxNx1xT - see bug.m)
    if (ndims(IS)==3) IS = permute(IS, [1,2,4,3] ); end;
    siz = size(IS);  nch = siz(3);  nd = ndims(IS);  
    if ( nd~=4 ) error('unsupported dimension of IS'); end;
    if( nch~=1 && nch~=3 ) error('illegal image stack format'); end;

    % normalize for maximum contrast
    if( isa(IS,'double') ) IS = IS - min(IS(:)); IS = IS / max(IS(:)); end;
    
    % make movie
    for i=1:siz(4)
        Ii=IS(:,:,:,i);         
        if( nch==1 ) [Ii,Mi] = gray2ind( Ii ); else Mi=[]; end;
        M(i) = im2frame( Ii, Mi );
    end;
    
