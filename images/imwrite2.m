% Similar to imwrite, except follows a strict naming convention.
%
% Wrapper for imwrite that writes file to the filename:
%   imagename = [path name int2str2(i,ndigits) '.' ext];
% Using imwrite: 
%   imwrite( I, imagename, writeparams )
%
% If I represents a stack of images, the ith image is written to:
%   imagenamei = [path name int2str2(i+imagei-1,ndigits) '.' ext];
%   
% If I=[], then imwrite2 will attempt to read images from disk instead.
%
% multflag controls how I is interpreted.  If multflag==0, then I is intrepreted as a
% single image, otherwise I is interpreted as a stack of images, where I(:,:,...,j)
% represents the jth image (see feval_arrays for more info).
%
% If the directory specified by 'path' does not exist, imwrite2 attempts to create it.
% 
% INPUTS
%   I           - image or array or cell of images (if [] reads else writes)
%   multflag    - set to 1 if I represents a stack of images
%   imagei      - first image number
%   path        - directory where images are
%   name        - base name of images
%   ext         - extension of image 
%   ndigits     - number of digits for filename index
%   writeparams - [varargin] additional parameters to imwrite
%
% OUTPUTS
%   I           - image or images (read from disk if input I=[])
%
% EXAMPLE
%   load images; clear IDXi IDXv t video videos;
%   imwrite2( images(:,:,1), 0, 0, 'rats/', 'rats', 'png', 5 );    % writes first frame
%   imwrite2( images(:,:,1:5), 1, 0, 'rats/', 'rats', 'png', 5 );  % writes first 5 frames
%   images2 = imwrite2( [], 1, 0, 'rats/', 'rats', 'png', 5 );     % reads first 5 frames
%   images2 = feval_images(@(x) x,{},'rats/','rats','png',0,4,5);  % reads first 5 frames
%
% DATESTAMP
%   26-Jan-2005  2:00pm
%
% See also FEVAL_IMAGES, FEVAL_ARRAYS

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = imwrite2( I, multflag, imagei, path, name, ext, ndigits, varargin )

    %%% if I is empty read from disk
    if( isempty(I) ) 
        I = feval_images( @(x) x, {}, path, name, ext, imagei, [], ndigits ); 
        return;
    end;

    %%% Check if path exists (create if not) and add '/' at end if needed
    if( ~isempty(path) )
        if(~exist(path,'dir')) 
            warning( ['creating directory: ' path] ); 
            mkdir( path ); 
        end;
        if( path(end)~='\' && path(end)~='/' ) path(end+1) = '/'; end;
    end
    
    %%% Write images using one of the two subfunctions
    params = varargin;
    if( multflag )
        imwrite2m( [], 'init', imagei, path, name, ext, ndigits, params );
        if( ~iscell(I) )
            feval_arrays( I, @imwrite2m, 'write' );
        else
            feval_arrays( I, @(x) imwrite2m(x{1},'write') );
        end
    else
        if( ~iscell(I) )
            imwrite2s( I, imagei, path, name, ext, ndigits, params );
        else
            imwrite2s( I{1}, imagei, path, name, ext, ndigits, params );
        end;
    end
    

% helper for writing multiple images (passed to feval_arrays)
function varargout = imwrite2m( I, type, varargin  )    
    persistent imagei path name ext ndigits params
    switch type
        case 'init'
            error(nargchk(8,8,nargin));
            [nstart, path, name, ext, ndigits, params] = deal(varargin{:});
            if(isempty(nstart)) imagei=0; else imagei=nstart; end;
            varargout = {[]};
            
        case 'write'
            error(nargchk(2,2,nargin));
            imwrite2s( I, imagei, path, name, ext, ndigits, params );
            imagei = imagei+1;
            varargout = {[]};
    end
    
    
% helper for writing a single image 
function imwrite2s( I, imagei, path, name, ext, ndigits, params )
    fullname = [path name int2str2(imagei,ndigits) '.' ext];
    imwrite( I, fullname, params{:} );
    
    
    
