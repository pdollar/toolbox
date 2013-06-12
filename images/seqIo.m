function out = seqIo( fName, action, varargin )
% Utilities for reading and writing seq files.
%
% A seq file is a series of concatentated image frames with a fixed size
% header. It is essentially the same as merging a directory of images into
% a single file. seq files are convenient for storing videos because: (1)
% no video codec is required, (2) seek is instant and exact, (3) seq files
% can be read on any operating system. The main drawback is that each frame
% is encoded independently, resulting in increased file size. The advantage
% over storing as a directory of images is that a single large file is
% created. Currently, either uncompressed, jpg or png compressed frames
% are supported. The seq file format is modeled after the Norpix seq format
% (in fact this reader can be used to read some Norpix seq files). The
% actual work of reading/writing seq files is done by seqReaderPlugin and
% seqWriterPlugin (there is no need to call those functions directly).
%
% seqIo contains a number of utility functions for working with seq files.
% The format for accessing the various utility functions is:
%  out = seqIo( fName, 'action', inputs );
% The list of functions and help for each is given below. Also, help on
% individual subfunctions can be accessed by: "help seqIo>action".
%
% Create interface sr for reading seq files.
%   sr = seqIo( fName, 'reader', [cache] )
% Create interface sw for writing seq files.
%   sw = seqIo( fName, 'writer', info )
% Get info about seq file.
%   info = seqIo( fName, 'getInfo' )
% Crop sub-sequence from seq file.
%   seqIo( fName, 'crop', tName, frames )
% Extract images from seq file to target directory or array.
%   Is = seqIo( fName, 'toImgs', [tDir], [skip], [f0], [f1], [ext] )
% Create seq file from an array or directory of images or from an AVI file.
%   seqIo( fName, 'frImgs', info, varargin )
% Convert seq file by applying imgFun(I) to each frame I.
%   seqIo( fName, 'convert', tName, imgFun, varargin )
% Replace header of seq file with provided info.
%   seqIo( fName, 'newHeader', info )
% Create interface sr for reading dual seq files.
%   sr = seqIo( fNames, 'readerDual', [cache] )
%
% USAGE
%  out = seqIo( fName, action, varargin )
%
% INPUTS
%  fName      - seq file to open
%  action     - controls action (see above)
%  varargin   - additional inputs (see above)
%
% OUTPUTS
%  out       - depends on action (see above)
%
% EXAMPLE
%
% See also seqIo>reader, seqIo>writer, seqIo>getInfo, seqIo>crop,
% seqIo>toImgs, seqIo>frImgs, seqIo>convert, seqIo>newHeader,
% seqIo>readerDual, seqPlayer, seqReaderPlugin, seqWriterPlugin
%
% Piotr's Image&Video Toolbox      Version 2.61
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

switch lower(action)
  case {'reader','r'}, out = reader( fName, varargin{:} );
  case {'writer','w'}, out = writer( fName, varargin{:} );
  case 'getinfo', out = getInfo( fName );
  case 'crop', crop( fName, varargin{:} ); out=1;
  case 'toimgs', out = toImgs( fName, varargin{:} );
  case 'frimgs', frImgs( fName, varargin{:} ); out=1;
  case 'convert', convert( fName, varargin{:} ); out=1;
  case 'newheader', newHeader( fName, varargin{:} ); out=1;
  case {'readerdual','rdual'}, out=readerDual(fName,varargin{:});
  otherwise, error('seqIo unknown action: ''%s''',action);
end
end

function sr = reader( fName, cache )
% Create interface sr for reading seq files.
%
% Create interface sr to seq file with the following commands:
%  sr.close();            % Close seq file (sr is useless after).
%  [I,ts]=sr.getframe();  % Get current frame (returns [] if invalid).
%  [I,ts]=sr.getframeb(); % Get current frame with no decoding.
%  ts = sr.getts();       % Return timestamps for all frames.
%  info = sr.getinfo();   % Return struct with info about video.
%  [I,ts]=sr.getnext();   % Shortcut for next() followed by getframe().
%  out = sr.next();       % Go to next frame (out=0 on fail).
%  out = sr.seek(frame);  % Go to specified frame (out=0 on fail).
%  out = sr.step(delta);  % Go to current frame+delta (out=0 on fail).
%
% If cache>0, reader() will cache frames in memory, so that calls to
% getframe() can avoid disk IO for cached frames (note that only frames
% returned by getframe() are cached). This is useful if the same frames are
% accessed repeatedly. When the cache is full, the frame in the cache
% accessed least recently is discarded. Memory requirements are
% proportional to cache size.
%
% USAGE
%  sr = seqIo( fName, 'reader', [cache] )
%
% INPUTS
%  fName  - seq file name
%  cache  - [0] size of cache
%
% OUTPUTS
%  sr     - interface for reading seq file
%
% EXAMPLE
%
% See also seqIo, seqReaderPlugin
if(nargin<2 || isempty(cache)), cache=0; end
if( cache>0 ), [as, fs, Is, ts, inds]=deal([]); end
r=@seqReaderPlugin; s=r('open',int32(-1),fName);
sr = struct( 'close',@() r('close',s), 'getframe',@getframe, ...
  'getframeb',@() r('getframeb',s), 'getts',@() r('getts',s), ...
  'getinfo',@() r('getinfo',s), 'getnext',@() r('getnext',s), ...
  'next',@() r('next',s), 'seek',@(f) r('seek',s,f), ...
  'step',@(d) r('step',s,d));

  function [I,t] = getframe()
    % if not using cache simply call 'getframe' and done
    if(cache<=0), [I,t]=r('getframe',s); return; end
    % if cache initialized and frame in cache perform lookup
    f=r('getinfo',s); f=f.curFrame; i=find(f==fs,1);
    if(i), as=as+1; as(i)=0; t=ts(i); I=Is(inds{:},i); return; end
    % if image not in cache add (and possibly initialize)
    [I,t]=r('getframe',s); if(0), fprintf('reading frame %i\n',f); end
    if(isempty(Is)), Is=zeros([size(I) cache],class(I));
      as=ones(1,cache); fs=-as; ts=as; inds=repmat({':'},1,ndims(I)); end
    [~,i]=max(as); as(i)=0; fs(i)=f; ts(i)=t; Is(inds{:},i)=I;
  end
end

function sw = writer( fName, info )
% Create interface sw for writing seq files.
%
% Create interface sw to seq file with the following commands:
%  sw.close();              % Close seq file (sw is useless after).
%  sw.addframe(I,[ts]);     % Writes video frame (and timestamp)
%  sw.addframeb(bytes);     % Writes video frame with no encoding.
%  info = sw.getinfo();     % Return struct with info about video.
%
% The following params must be specified in struct 'info' upon opening:
%  width          - frame width
%  height         - frame height
%  fps            - frames per second
%  quality        - [80] compression quality (0 to 100)
%  codec          - string representing codec, options include:
%   'monoraw'/'imageFormat100'      - black/white uncompressed
%   'raw'/'imageFormat200'          - color (BGR) uncompressed
%   'monojpg'/'imageFormat102'      - black/white jpg compressed
%   'jpg'/'imageFormat201'          - color jpg compressed
%   'monopng'/'imageFormat001'      - black/white png compressed
%   'png'/'imageFormat002'          - color png compressed
%
% USAGE
%  sw = seqIo( fName, 'writer', info )
%
% INPUTS
%  fName  - seq file name
%  info   - see above
%
% OUTPUTS
%  sw     - interface for writing seq file
%
% EXAMPLE
%
% See also seqIo, seqWriterPlugin
w=@seqWriterPlugin; s=w('open',int32(-1),fName,info);
sw = struct( 'close',@() w('close',s), 'getinfo',@() w('getinfo',s), ...
  'addframe',@(varargin) w('addframe',s,varargin{:}), ...
  'addframeb',@(varargin) w('addframeb',s,varargin{:}) );
end

function info = getInfo( fName )
% Get info about seq file.
%
% USAGE
%  info = seqIo( fName, 'getInfo' )
%
% INPUTS
%  fName  - seq file name
%
% OUTPUTS
%  info   - information struct
%
% EXAMPLE
%
% See also seqIo
sr=reader(fName); info=sr.getinfo(); sr.close();
end

function crop( fName, tName, frames )
% Crop sub-sequence from seq file.
%
% Frame indices are 0 indexed. frames need not be consecutive and can
% contain duplicates. An index of -1 indicates a blank (all 0) frame. If
% contiguous subset of frames is cropped timestamps are preserved.
%
% USAGE
%  seqIo( fName, 'crop', tName, frames )
%
% INPUTS
%  fName      - seq file name
%  tName      - cropped seq file name
%  frames     - frame indices (0 indexed)
%
% OUTPUTS
%
% EXAMPLE
%
% See also seqIo
sr=reader(fName); info=sr.getinfo(); sw=writer(tName,info);
frames=frames(:)'; pad=sr.getnext(); pad(:)=0;
kp=frames>=0 & frames<info.numFrames; if(~all(kp)), frames=frames(kp);
  warning('piotr:seqIo:crop','%i out of bounds frames',sum(~kp)); end
ordered=all(frames(2:end)==frames(1:end-1)+1);
n=length(frames); k=0; tid=ticStatus;
for f=frames
  if(f<0), sw.addframe(pad); continue; end
  sr.seek(f); [I,ts]=sr.getframeb(); k=k+1; tocStatus(tid,k/n);
  if(ordered), sw.addframeb(I,ts); else sw.addframeb(I); end
end; sw.close(); sr.close();
end

function Is = toImgs( fName, tDir, skip, f0, f1, ext )
% Extract images from seq file to target directory or array.
%
% USAGE
%  Is = seqIo( fName, 'toImgs', [tDir], [skip], [f0], [f1], [ext] )
%
% INPUTS
%  fName      - seq file name
%  tDir       - [] target directory (if empty extract images to array)
%  skip       - [1] skip between written frames
%  f0         - [0] first frame to write
%  f1         - [numFrames-1] last frame to write
%  ext        - [] optionally save as given type (slow, reconverts)
%
% OUTPUTS
%  Is         - if isempty(tDir) outputs image array (else Is=[])
%
% EXAMPLE
%
% See also seqIo
if(nargin<2 || isempty(tDir)), tDir=[]; end
if(nargin<3 || isempty(skip)), skip=1; end
if(nargin<4 || isempty(f0)), f0=0; end
if(nargin<5 || isempty(f1)), f1=inf; end
if(nargin<6 || isempty(ext)), ext=''; end
sr=reader(fName); info=sr.getinfo(); f1=min(f1,info.numFrames-1);
frames=f0:skip:f1; n=length(frames); tid=ticStatus; k=0;
% output images to array
if(isempty(tDir))
  I=sr.getnext(); d=ndims(I); assert(d==2 || d==3);
  try Is=zeros([size(I) n],class(I)); catch e; sr.close(); throw(e); end
  for k=1:n, sr.seek(frames(k)); I=sr.getframe(); tocStatus(tid,k/n);
    if(d==2), Is(:,:,k)=I; else Is(:,:,:,k)=I; end; end
  sr.close(); return;
end
% output images to directory
if(~exist(tDir,'dir')), mkdir(tDir); end; Is=[];
for frame=frames
  f=[tDir '/I' int2str2(frame,5) '.']; sr.seek(frame);
  if(~isempty(ext)), I=sr.getframe(); imwrite(I,[f ext]); else
    I=sr.getframeb(); f=fopen([f  info.ext],'w');
    if(f<=0), sr.close(); assert(false); end
    fwrite(f,I); fclose(f);
  end; k=k+1; tocStatus(tid,k/n);
end; sr.close();
end

function frImgs( fName, info, varargin )
% Create seq file from an array or directory of images or from an AVI file.
%
% For info, if converting from array, only codec (e.g., 'jpg') and fps must
% be specified while width and height and determined automatically. If
% converting from AVI, fps is also determined automatically.
%
% USAGE
%  seqIo( fName, 'frImgs', info, varargin )
%
% INPUTS
%  fName      - seq file name
%  info       - defines codec, etc, see seqIo>writer
%  varargin   - additional params (struct or name/value pairs)
%   .aviName    - [] if specified create seq from avi file
%   .Is         - [] if specified create seq from image array
%   .sDir       - [] source directory
%   .skip       - [1] skip between frames
%   .name       - ['I'] base name of images
%   .nDigits    - [5] number of digits for filename index
%   .f0         - [0] first frame to read
%   .f1         - [10^6] last frame to read
%
% OUTPUTS
%
% EXAMPLE
%
% See also seqIo, seqIo>writer
dfs={'aviName','','Is',[],'sDir',[],'skip',1,'name','I',...
  'nDigits',5,'f0',0,'f1',10^6};
[aviName,Is,sDir,skip,name,nDigits,f0,f1] ...
  = getPrmDflt(varargin,dfs,1);
if(~isempty(aviName))
  if(exist('mmread.m','file')==2) % use external mmread function
    %  mmread requires full pathname, which is obtained via 'which'. But,
    % 'which' can fail (maltab bug), so best to just pass in full pathname
    t=which(aviName); if(~isempty(t)), aviName=t; end
    V=mmread(aviName); n=V.nrFramesTotal;
    info.height=V.height; info.width=V.width; info.fps=V.rate;
    sw=writer(fName,info); tid=ticStatus('creating seq from avi');
    for f=1:n, sw.addframe(V.frames(f).cdata); tocStatus(tid,f/n); end
    sw.close();
  else % use matlab mmreader function
    emsg=['mmreader.m failed to load video. In general mmreader.m is ' ...
      'known to have many issues, especially on Linux. I suggest ' ...
      'installing the similarly named mmread toolbox from Micah ' ...
      'Richert, available at Matlab Central. If mmread is installed, ' ...
      'seqIo will automatically use mmread instead of mmreader.'];
    try V=mmreader(aviName); catch %#ok<DMMR,CTCH>
      error('piotr:seqIo:frImgs',emsg); end; n=V.NumberOfFrames;
    info.height=V.Height; info.width=V.Width; info.fps=V.FrameRate;
    sw=writer(fName,info); tid=ticStatus('creating seq from avi');
    for f=1:n, sw.addframe(read(V,f)); tocStatus(tid,f/n); end
    sw.close();
  end
elseif( isempty(Is) )
  assert(exist(sDir,'dir')==7); sw=writer(fName,info); info=sw.getinfo();
  frmStr=sprintf('%s/%s%%0%ii.%s',sDir,name,nDigits,info.ext);
  for frame = f0:skip:f1
    f=sprintf(frmStr,frame); if(~exist(f,'file')), break; end
    f=fopen(f,'r');  if(f<=0), sw.close(); assert(false); end
    I=fread(f); fclose(f); sw.addframeb(I);
  end; sw.close();
  if(frame==f0), warning('No images found.'); end %#ok<WNTAG>
else
  nd=ndims(Is); if(nd==2), nd=3; end; assert(nd<=4); nFrm=size(Is,nd);
  info.height=size(Is,1); info.width=size(Is,2); sw=writer(fName,info);
  if(nd==3), for f=1:nFrm, sw.addframe(Is(:,:,f)); end; end
  if(nd==4), for f=1:nFrm, sw.addframe(Is(:,:,:,f)); end; end
  sw.close();
end
end

function convert( fName, tName, imgFun, varargin )
% Convert seq file by applying imgFun(I) to each frame I.
%
% USAGE
%  seqIo( fName, 'convert', tName, imgFun, varargin )
%
% INPUTS
%  fName      - seq file name
%  tName      - converted seq file name
%  imgFun     - function to apply to each image
%  varargin   - additional params (struct or name/value pairs)
%   .info       - [] info for target seq file
%   .skip       - [1] skip between frames
%   .f0         - [0] first frame to read
%   .f1         - [inf] last frame to read
%
% OUTPUTS
%
% EXAMPLE
%
% See also seqIo
dfs={'info',[],'skip',1,'f0',0,'f1',inf};
[info,skip,f0,f1]=getPrmDflt(varargin,dfs,1);
assert(~strcmp(tName,fName)); sr=reader(fName); infor=sr.getinfo();
if(isempty(info)), info=infor; end; n=infor.numFrames; f1=min(f1,n-1);
I=sr.getnext(); I=imgFun(I); info.width=size(I,2); info.height=size(I,1);
sw=writer(tName,info); tid=ticStatus('converting seq');
frames=f0:skip:f1; n=length(frames); k=0;
for f=frames, sr.seek(f); [I,ts]=sr.getframe(); I=imgFun(I);
  if(skip==1), sw.addframe(I,ts); else sw.addframe(I); end
  k=k+1; tocStatus(tid,k/n);
end; sw.close(); sr.close();
end

function newHeader( fName, info )
% Replace header of seq file with provided info.
%
% Can be used if the file fName has a corrupt header. Automatically tries
% to compute number of frames in fName. No guarantees that it will work.
%
% USAGE
%  seqIo( fName, 'newHeader', info )
%
% INPUTS
%  fName      - seq file name
%  info       - info for target seq file
%
% OUTPUTS
%
% EXAMPLE
%
% See also seqIo
[d,n]=fileparts(fName); if(isempty(d)), d='.'; end
fName=[d '/' n]; tName=[fName '-new' datestr(now,30)];
if(exist([fName '-seek.mat'],'file')); delete([fName '-seek.mat']); end
srp=@seqReaderPlugin; hr=srp('open',int32(-1),fName,info); tid=ticStatus;
info=srp('getinfo',hr); sw=writer(tName,info); n=info.numFrames;
for f=1:n, srp('next',hr); [I,ts]=srp('getframeb',hr);
  sw.addframeb(I,ts); tocStatus(tid,f/n); end
srp('close',hr); sw.close();
end

function sr = readerDual( fNames, cache )
% Create interface sr for reading dual seq files.
%
% Wrapper for two seq files of the same image dims and roughly the same
% frame counts that are treated as a single reader object. getframe()
% returns the concatentation of the two frames. For videos of different
% frame counts, the first video serves as the "dominant" video and the
% frame count of the second video is adjusted accordingly. Same general
% usage as in reader, but the only supported operations are: close(),
% getframe(), getinfo(), and seek().
%
% USAGE
%  sr = seqIo( fNames, 'readerDual', [cache] )
%
% INPUTS
%  fNames - two seq file names
%  cache  - [0] size of cache (see seqIo>reader)
%
% OUTPUTS
%  sr     - interface for reading seq file
%
% EXAMPLE
%
% See also seqIo, seqIo>reader
if(nargin<2 || isempty(cache)), cache=0; end
s1=reader(fNames{1}, cache); i1=s1.getinfo();
s2=reader(fNames{2}, cache); i2=s2.getinfo();
info=i1; info.width=i1.width+i2.width;
if( i1.width~=i2.width || i1.height~=i2.height )
  s1.close(); s2.close(); error('Mismatched videos'); end
if( i1.numFrames~=i2.numFrames )
  warning('seq files of different lengths'); end %#ok<WNTAG>
frame2=@(f) round(f/(i1.numFrames-1)*(i2.numFrames-1));

sr=struct('close',@() min(s1.close(),s2.close()), ...
  'getframe',@getframe, 'getinfo',@() info, ...
  'seek',@(f) s1.seek(f) & s2.seek(frame2(f)) );

  function [I,t] = getframe()
    [I1,t]=s1.getframe(); I2=s2.getframe(); I=[I1 I2]; end
end
