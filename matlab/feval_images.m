% Used to apply the same operation to all images in given directory.
%
% For each image in  srcdir, loads the image, applies the function in fhandle and stores
% the result.  The result x=fhandle(I,params{:}) on the ith image is stored in
% X(:,...:,i).  If the size of x depends on the size of I, then all images in the
% directory must have the same size.  Also I may have a different format depending on how
% it is stored on disk - example: MxN for grayscale, MxNx3 for RGB, MxNx4 for CMYK. This
% function is very similar to feval_arrays, except instead of operating on images in
% memory it operates on images on disk.  For long operations shows progress information.
% 
% The srcdir must contain nothing but images.  Either the images follow no naming
% convention, or they follow a very rigid naming convention that consists of a string
% followed by ndigits-number specifying the image number, followed by an extension.  The
% advantage of the more rigid naming convention is that it allows a certain range of
% images to be operated on, specified by [nstart,nend]. For example, to operate on images
% "rats0003.tif ... rats0113.tif" in directory '../rats/' use:   
%    feval_images( fhandle, params, '../rats/', 'rats' , 'tif', 3, 113, 4 );
% If the parameter name is specified ('rats' in the example above), the rigid naming
% convention is assumed.  All further input arguments are optional.
%
% imwrite2 writes images in the format described above.  
%
% If the function in fhandle is identity (f=@(x) x), the result is to read in all images
% in the directory.  
%
% A limitation of feval_images is that it does not pass state information to fhandle.  For
% example, fhandle may want to know how many times it's been  called. This can be overcome
% by saving state information inside fhandle using 'persistent' variables.  For an example
% see imwrite2 (which uses persistent variables with feval_arrays). 
%
% INPUTS
%   fhandle   - function to apply to each image [see above]
%   params    - cell array of additional parameters to fhandle (may be {} )
%   srcdir    - directory containing images 
%   name      - [optional] base name of images
%   ext       - [optional] extension of image 
%   nstart    - [optional] image number on which to start
%   nend      - [optional] image number on which to end
%   ndigits   - [optional] number of digits for filename index
%
% OUTPUTS
%   X        - output array [see above]
%
% EXAMPLE
% % reads in all images in directory (note that fhandle is identity!):
%   X = feval_images( @(x) x, {}, srcdir );  
% % reads in all images converting to grayscale:
%   X = feval_images( @(x) rgb2gray(x), {}, srcdir ); 
%
% DATESTAMP
%   30-Apr-2006 12:00pm
%
% See also FEVAL_ARRAYS, IMWRITE2, PERSISTENT, TICSTATUS

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function X = feval_images( fhandle, params, srcdir, name, ext, nstart, nend, ndigits )
    error(nargchk( 3, 8, nargin ));
    
    %%% Check if srcdir is valid and add '/' at end if needed
    if( ~isempty(srcdir) )
        if(~exist(srcdir,'dir')) 
            error( ['feval_images: directory ' srcdir ' not found' ] ); end;
        if( srcdir(end)~='\' && srcdir(end)~='/' ) srcdir(end+1) = '/'; end;
    end

    %%% get appropriate filenames
    if( nargin<=3 ) % no convention followed
        dircontent = dir(srcdir); dircontent = dircontent(3:end);  
        filenames = {dircontent.name}; n = length(dircontent);
    else % strict convention followed
        if( nargin<8 || isempty(ndigits) )
            dircontent = dir([srcdir name '*.' ext]);
        else
            dircontent = dir([srcdir name repmat('?',[1 ndigits]) '.' ext '*' ]);
        end;
        filenames = {dircontent.name};
        n = length(dircontent);
        if( n==0 ) error( ['No images found in ' srcdir] ); end;
        if( nargin<5 || isempty(ext)) ext = dircontent(1).name; ext = ext(end-2:end); end;
        if( nargin<6 || isempty(nstart)) nstart = 0; end;
        if( nargin<7 || isempty(nend)) nend = n-1+nstart; end;
        if( nargin<8 || isempty(ndigits)) 
            ndigits = length(dircontent(1).name)-length(ext)-1-length(name); end;
        n = nend-nstart+1;
    end;
    if( n==0 ) X=[]; return; end;
    
    %%% load each image and apply func
    ticstatusid = ticstatus('feval_images',[],40);
    for i=1:n
        % load image
        if( nargin==3 )
            I = imread( [srcdir filenames{i}] );
        else
            nstr = int2str2( i+nstart-1, ndigits );
            try
                I = imread([srcdir name nstr '.' ext ] );
            catch
               error( ['Unable to read image: ' srcdir name nstr '.' ext] );
            end;
        end
        
        % apply fhandle to I
        x = feval( fhandle, I, params{:} );
        if (i==1) 
            ndx = ndims(x); 
            if(ndx==2 && size(x,2)==1) ndx=1; end;
            ones_ndx = ones(1,ndx);
            X = repmat( x, [ones_ndx,n] ); 
            indsX = {':'}; indsX = indsX(ones_ndx);
        else 
            X(indsX{:},i) = x;
        end;
        tocstatus( ticstatusid, i/n );
    end;

    
    
    
%     %%% GET directory content, discarding all non-image files -- TOO SLOW
%     % should do by looking at just extension.
%     count = 1;  for i=1:n 
%         [info,msg] = imfinfo([srcdir dircontent(i).name]);
%         if(isempty(msg)) imdircontent(count) = dircontent(i);  count = count+1; end;
%     end; n = count - 1; imdircontent = dircontent;
