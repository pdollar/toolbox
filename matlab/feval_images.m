% Used to apply the same operation to all images in given directory.
%
% For each image in  srcDir, loads the image, applies the function in
% fHandle and stores the result.  The result x=fHandle(I,prms{:}) on the
% ith image is stored in X(:,...:,i).  If the size of x depends on the size
% of I, then all images in the directory must have the same size.  Also I
% may have a different format depending on how it is stored on disk -
% example: MxN for grayscale, MxNx3 for RGB, MxNx4 for CMYK. This function
% is similar to feval_arrays, except instead of operating on images in
% memory it operates on images on disk.  For long operations shows progress
% info.
%
% The srcDir must contain nothing but images.  Either the images follow no
% naming convention, or they follow a very rigid naming convention that
% consists of a string followed by an nDigits number specifying the image
% number, followed by an extension.  The advantage of the more rigid naming
% convention is that it allows a certain range of images to be operated on,
% specified by [nStr,nEnd]. For example, to operate on images
% "rats0003.tif ... rats0113.tif" in directory '../rats/' use:
%  feval_images( fHandle, prms, '../rats/', 'rats' , 'tif', 3, 113, 4 );
% If the parameter name is specified ('rats' in the example above), the
% rigid naming convention is assumed.  All further input arguments are
% optional. imwrite2 writes images in the format described above.
%
% A limitation of feval_images is that it does not pass state information
% to fHandle.  For example, fHandle may want to know how many times it's
% been  called. This can be overcome by saving state information inside
% fHandle using 'persistent' variables.  For an example see imwrite2 (which
% uses persistent variables with feval_arrays).
%
% USAGE
%  X = feval_images( fHandle, prms, srcDir, [name], [ext],
%                    [nStr], [nEnd], [nDigits] )
%
% INPUTS
%  fHandle   - function to apply to each image [see above]
%  prms      - cell array of additional parameters to fHandle (may be {} )
%  srcDir    - directory containing images
%  name      - [] base name of images
%  ext       - [] extension of image
%  nStr      - [] image number on which to start
%  nEnd      - [] image number on which to end
%  nDigits   - [] number of digits for filename index
%
% OUTPUTS
%  X        - output array [see above]
%
% EXAMPLE
%  % reads in all images in directory (note that fHandle is identity):
%  X = feval_images( @(x) x, {}, srcDir );
%  % reads in different sized images into cell array:
%  X = feval_images( @(x) {x}, {}, srcDir );
%  % reads in all images converting to grayscale:
%  X = feval_images( @(x) rgb2gray(x), {}, srcDir );
%
% See also FEVAL_ARRAYS, IMWRITE2, PERSISTENT, TICSTATUS

% Piotr's Image&Video Toolbox      Version 1.03   PPD VR
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function X = feval_images( fHandle, prms, srcDir, name, ext, ...
  nStr, nEnd, nDigits )

error(nargchk( 3, 8, nargin ));

%%% Check if srcDir is valid and add '/' at end if needed
if( ~isempty(srcDir) )
  if(~exist(srcDir,'dir'))
    error( ['feval_images: directory ' srcDir ' not found' ] ); end;
  if( srcDir(end)~='\' && srcDir(end)~='/' ); srcDir(end+1) = '/'; end;
end

%%% get appropriate filenames
if( nargin<=3 ) % no convention followed
  dirCont = dir(srcDir); dirCont = dirCont(3:end);
  filenames = {dirCont.name}; n = length(dirCont);
else % strict convention followed
  if( nargin<8 || isempty(nDigits) )
    dirCont = dir([srcDir name '*.' ext]);
  else
    dirCont = dir([srcDir name repmat('?',[1 nDigits]) '.' ext '*' ]);
  end;
  filenames = {dirCont.name};
  n = length(dirCont);
  if( n==0 ); error( ['No images found in ' srcDir] ); end;
  if( nargin<5 || isempty(ext));
    ext=dirCont(1).name; ext=ext(end-2:end);
  end;
  if( nargin<6 || isempty(nStr)); nStr = 0; end;
  if( nargin<7 || isempty(nEnd)); nEnd = n-1+nStr; end;
  if( nargin<8 || isempty(nDigits))
    nDigits = length(dirCont(1).name)-length(ext)-1-length(name); end;
  n = nEnd-nStr+1;
end;
if( n==0 ); X=[]; return; end;

%%% load each image and apply func
ticstatusid = ticstatus('feval_images',[],40);
for i=1:n
  % load image
  if( nargin==3 )
    I = imread( [srcDir filenames{i}] );
  else
    nstr = int2str2( i+nStr-1, nDigits );
    try
      I = imread([srcDir name nstr '.' ext ] );
    catch
      error( ['Unable to read image: ' srcDir name nstr '.' ext] );
    end;
  end

  % apply fHandle to I
  x = feval( fHandle, I, prms{:} );
  if (i==1)
    ndx = ndims(x);
    if(ndx==2 && size(x,2)==1); ndx=1; end;
    ones_ndx = ones(1,ndx);
    X = repmat( x, [ones_ndx,n] );
    indsX = {':'}; indsX = indsX(ones_ndx);
  else
    X(indsX{:},i) = x;
  end;
  tocstatus( ticstatusid, i/n );
end;
