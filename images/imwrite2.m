function I = imwrite2( I, mulFlag, imagei, path, ...
  name, ext, nDigits, nSplits, spliti, varargin )
% Similar to imwrite, except follows a strict naming convention.
%
% Wrapper for imwrite that writes file to the filename:
%  fName = [path name int2str2(i,nDigits) '.' ext];
% Using imwrite:
%  imwrite( I, fName, writePrms )
% If I represents a stack of images, the ith image is written to:
%  fNamei = [path name int2str2(i+imagei-1,nDigits) '.' ext];
% If I=[], then imwrite2 will attempt to read images from disk instead.
% If dir spec. by 'path' does not exist, imwrite2 attempts to create it.
%
% mulFlag controls how I is interpreted.  If mulFlag==0, then I is
% intrepreted as a single image, otherwise I is interpreted as a stack of
% images, where I(:,:,...,j) represents the jth image (see fevalArrays for
% more info).
%
% If nSplits>1, writes/reads images into/from multiple directories. This is
% useful since certain OS handle very large directories (of say >20K
% images) rather poorly (I'm talking to you Bill).  Thus, can take 100K
% images, and write into 5 separate dirs, then read them back in.
%
% USAGE
%   I = imwrite2( I, mulFlag, imagei, path, ...
%     [name], [ext], [nDigits], [nSplits], [spliti], [varargin] )
%
% INPUTS
%  I           - image or array or cell of images (if [] reads else writes)
%  mulFlag     - set to 1 if I represents a stack of images
%  imagei      - first image number
%  path        - directory where images are
%  name        - ['I'] base name of images
%  ext         - ['png'] extension of image
%  nDigits     - [5] number of digits for filename index
%  nSplits     - [1] number of dirs to break data into
%  spliti      - [0] first split (dir) number
%  writePrms   - [varargin] parameters to imwrite
%
% OUTPUTS
%  I           - image or images (read from disk if input I=[])
%
% EXAMPLE
%  load images; I=images(:,:,1:10); clear IDXi IDXv t video videos images;
%  imwrite2( I(:,:,1), 0, 0, 'rats/', 'rats', 'png', 5 );   % write 1
%  imwrite2( I, 1, 0, 'rats/', 'rats', 'png', 5 );          % write 5
%  I2 = imwrite2( [], 1, 0, 'rats/', 'rats', 'png', 5 );    % read 5
%  I3 = fevalImages(@(x) x,{},'rats/','rats','png',0,4,5);  % read 5
%
% EXAMPLE - multiple splits
%  load images; I=images(:,:,1:10); clear IDXi IDXv t video videos images;
%  imwrite2( I, 1, 0, 'rats', 'rats', 'png', 5, 2, 0 );      % write 10
%  I2=imwrite2( [], 1, 0, 'rats', 'rats', 'png', 5, 2, 0 );  % read 10
%
% See also FEVALIMAGES, FEVALARRAYS
%
% Piotr's Image&Video Toolbox      Version 2.30
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<5 || isempty(name) );    name='I'; end;
if( nargin<6 || isempty(ext) );     ext='png'; end;
if( nargin<7 || isempty(nDigits) ); nDigits=5; end;
if( nargin<8 || isempty(nSplits) ); nSplits=1; end;
if( nargin<9 || isempty(spliti) );  spliti=0; end;
n = size(I,3);  if(isempty(I)); n=0; end

% multiple splits -- call imwrite2 recursively
if( nSplits>1 )
  write2inp = [ {name, ext, nDigits, 1, 0} varargin ];
  if(n>0); nSplits=min(n,nSplits); end;
  for s=1:nSplits
    pathS = [path int2str2(s-1+spliti,2)];
    if( n>0 ) % write
      nPerDir = ceil( n / nSplits );
      ISplit = I(:,:,1:min(end,nPerDir));
      imwrite2( ISplit, nPerDir>1, 0, pathS, write2inp{:} );
      if( s~=nSplits ); I = I(:,:,(nPerDir+1):end); end
    else % read
      ISplit = imwrite2( [], 1, 0, pathS, write2inp{:} );
      I = cat(3,I,ISplit);
    end
  end
  return;
end

% if I is empty read from disk
if( n==0 )
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

function varargout = imwrite2m( I, type, varargin )
% helper for writing multiple images (passed to fevalArrays)

persistent imagei path name ext nDigits params
switch type
  case 'init'
    narginchk(8,8);
    [nstart, path, name, ext, nDigits, params] = deal(varargin{:});
    if(isempty(nstart)); imagei=0; else imagei=nstart; end
    varargout = {[]};

  case 'write'
    narginchk(2,2);
    imwrite2s( I, imagei, path, name, ext, nDigits, params );
    imagei = imagei+1;
    varargout = {[]};
end

function imwrite2s( I, imagei, path, name, ext, nDigits, params )
% helper for writing a single image

fullname = [path name int2str2(imagei,nDigits) '.' ext];
imwrite( I, fullname, params{:} );
