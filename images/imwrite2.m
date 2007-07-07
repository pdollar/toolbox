% Similar to imwrite, except follows a strict naming convention.
%
% Wrapper for imwrite that writes file to the filename:
%  imagename = [path name int2str2(i,nDigits) '.' ext];
% Using imwrite:
%  imwrite( I, imagename, writePrms )
% If I represents a stack of images, the ith image is written to:
%  imagenamei = [path name int2str2(i+imagei-1,nDigits) '.' ext];
% If I=[], then imwrite2 will attempt to read images from disk instead.
% If dir spec. by 'path' does not exist, imwrite2 attempts to create it.
%
% mulFlag controls how I is interpreted.  If mulFlag==0, then I is
% intrepreted as a single image, otherwise I is interpreted as a stack of
% images, where I(:,:,...,j) represents the jth image (see fevalArrays for
% more info).
%
% USAGE
%  I = imwrite2( I, mulFlag, imagei, path, name, ext, nDigits, varargin )
%
% INPUTS
%  I           - image or array or cell of images (if [] reads else writes)
%  mulFlag     - set to 1 if I represents a stack of images
%  imagei      - first image number
%  path        - directory where images are
%  name        - base name of images
%  ext         - extension of image
%  nDigits     - number of digits for filename index
%  writePrms   - [varargin] additional parameters to imwrite
%
% OUTPUTS
%  I           - image or images (read from disk if input I=[])
%
% EXAMPLE
%  load images; clear IDXi IDXv t video videos;
%  imwrite2( images(:,:,1), 0, 0, 'rats/', 'rats', 'png', 5 );
%  imwrite2( images(:,:,1:5), 1, 0, 'rats/', 'rats', 'png', 5 );
%  images2 = imwrite2( [], 1, 0, 'rats/', 'rats', 'png', 5 );
%  images2 = fevalImages(@(x) x,{},'rats/','rats','png',0,4,5);
%
% See also FEVALIMAGES, FEVALARRAYS

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function I=imwrite2(I, mulFlag, imagei, path, name, ext, nDigits, varargin)

% if I is empty read from disk
if( isempty(I) )
  I = fevalImages( @(x) x, {}, path, name, ext, imagei, [], nDigits );
  return;
end

% Check if path exists (create if not) and add '/' at end if needed
if( ~isempty(path) )
  if(~exist(path,'dir'))
    warning( ['creating directory: ' path] ); %#ok<WNTAG>
    mkdir( path );
  end;
  if( path(end)~='\' && path(end)~='/' ); path(end+1) = '/'; end
end

% Write images using one of the two subfunctions
params = varargin;
if( mulFlag )
  imwrite2m( [], 'init', imagei, path, name, ext, nDigits, params );
  if( ~iscell(I) )
    fevalArrays( I, @imwrite2m, 'write' );
  else
    fevalArrays( I, @(x) imwrite2m(x{1},'write') );
  end
else
  if( ~iscell(I) )
    imwrite2s( I, imagei, path, name, ext, nDigits, params );
  else
    imwrite2s( I{1}, imagei, path, name, ext, nDigits, params );
  end;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper for writing multiple images (passed to fevalArrays)
function varargout = imwrite2m( I, type, varargin  )

persistent imagei path name ext nDigits params
switch type
  case 'init'
    error(nargchk(8,8,nargin));
    [nstart, path, name, ext, nDigits, params] = deal(varargin{:});
    if(isempty(nstart)); imagei=0; else imagei=nstart; end
    varargout = {[]};

  case 'write'
    error(nargchk(2,2,nargin));
    imwrite2s( I, imagei, path, name, ext, nDigits, params );
    imagei = imagei+1;
    varargout = {[]};
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper for writing a single image
function imwrite2s( I, imagei, path, name, ext, nDigits, params )

fullname = [path name int2str2(imagei,nDigits) '.' ext];
imwrite( I, fullname, params{:} );
