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
%   sr = seqIo( fName, 'reader' )
% Create interface sw for writing seq files.
%   sw = seqIo( fName, 'writer', info )
% Get info about seq file.
%   info = seqIo( fName, 'getInfo' )
% Crop sub-sequence from seq file.
%   seqIo( fName, 'crop', tName, frames )
% Extract images from seq file to target directory.
%   seqIo( fName, 'toImgs', tDir, [skip], [f0], [f1] )
% Convert seq file by applying imgFun(I) to each frame I.
%   seqIo( fName, 'convert', tName, imgFun, [info] )
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
% seqIo>toImgs, seqIo>convert, seqPlayer, seqReaderPlugin, seqWriterPlugin
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

switch lower(action)
  case {'reader','r'}, out = reader( fName, varargin{:} );
  case {'writer','w'}, out = writer( fName, varargin{:} );
  case 'getinfo', out = getInfo( fName );
  case 'crop', crop( fName, varargin{:} );
  case 'toimgs', toImgs( fName, varargin{:} );
  case 'frimgs', frImgs( fName, varargin{:} );
  case 'convert', convert( fName, varargin{:} );
  case 'header', header( fName, varargin{:} );
  case 'rdual', out = readerDual( fName, varargin{:} );
  otherwise, error('seqIo unknown action: ''%s''',action);
end
end

function sr = reader( fName )
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
% USAGE
%  sr = seqIo( fName, 'reader' )
%
% INPUTS
%  fName  - seq file name
%
% OUTPUTS
%  sr     - interface for reading seq file
%
% EXAMPLE
%
% See also seqIo, seqReaderPlugin
r=@seqReaderPlugin; s=r('open',int32(-1),fName);
sr = struct( 'close',@() r('close',s), 'getframe',@() r('getframe',s),...
  'getframeb',@() r('getframeb',s), 'getts',@() r('getts',s), ...
  'getinfo',@() r('getinfo',s), 'getnext',@() r('getnext',s), ...
  'next',@() r('next',s), 'seek',@(f) r('seek',s,f), ...
  'step',@(d) r('step',s,d));
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
sr=seqIo(fName,'r'); info=sr.getinfo(); sr.close();
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
ordered=all(frames(2:end)==frames(1:end-1)+1);
for f=frames
  if(f<0), sw.addframe(pad); continue; end
  sr.seek(f); [I,ts]=sr.getframeb();
  if(ordered), sw.addframeb(I,ts); else sw.addframeb(I); end
end; sw.close(); sr.close();
end

function toImgs( fName, tDir, skip, f0, f1 )
% Extract images from seq file to target directory.
%
% USAGE
%  seqIo( fName, 'toImgs', tDir, [skip], [f0], [f1] )
%
% INPUTS
%  fName      - seq file name
%  tDir       - target directory
%  skip       - [1] skip between written frames
%  f0         - [0] first frame to write
%  f1         - [numFrames-1] last frame to write
%
% OUTPUTS
%
% EXAMPLE
%
% See also seqIo
if(nargin<3 || isempty(skip)), skip=1; end
if(nargin<4 || isempty(f0)), f0=0; end
if(nargin<5 || isempty(f1)), f1=inf; end
if(~exist(tDir,'dir')), mkdir(tDir); end
sr=seqIo(fName,'r'); info=sr.getinfo();
for frame = f0:skip:min(f1,info.numFrames-1)
  f=[tDir '/I' int2str2(frame,5) '.' info.ext];
  sr.seek(frame); I=sr.getframeb(); f=fopen(f,'w');
  if(f<=0), sr.close(); assert(false); end
  fwrite(f,I); fclose(f);
end; sr.close();
end

function frImgs( fName, varargin )
% action=='frimgs': Make seq file from images in dir/I[frame,5].ext:
%  seqIo( fName, 'frimgs', dir, info, [skip] )
% action=='frimgs': Make seq file from images in array IS:
%  seqIo( fName, 'frimgs', IS, info )
if( ischar(varargin{1}) )
  % seqIo( fName, 'frimgs', dir, info, [skip] )
  d=varargin{1}; info=varargin{2}; assert(exist(d,'dir')==7);
  if(nargin==5), skip=varargin{3}; else skip=1; end
  sw=seqIo(fName,'w',info); info=sw.getinfo(); ext=['.' info.ext];
  for frame = skip-1:skip:1e5
    f=[d '/I' int2str2(frame,5) ext]; if(~exist(f,'file')), break; end
    f=fopen(f,'r'); assert(f>0); I=fread(f); fclose(f); sw.addframeb(I);
  end
  sw.close();
  if(frame==skip-1), warning('No images found.'); end %#ok<WNTAG>
else
  % seqIo( fName, 'frimgs', IS, info )
  IS=varargin{1}; info=varargin{2};
  nd=ndims(IS); if(nd==2), nd=3; end; assert(nd<=4); nFrm=size(IS,nd);
  info.height=size(IS,1); info.width=size(IS,2); sw=seqIo(fName,'w',info);
  if(nd==3), for f=1:nFrm, sw.addframe(IS(:,:,f)); end; end
  if(nd==4), for f=1:nFrm, sw.addframe(IS(:,:,:,f)); end; end
  sw.close();
end
end

function convert( fName, tName, imgFun, info )
% Convert seq file by applying imgFun(I) to each frame I.
%
% USAGE
%  seqIo( fName, 'convert', tName, imgFun, [info] )
%
% INPUTS
%  fName      - seq file name
%  tName      - converted seq file name
%  imgFun     - function to apply to each image
%  info       - info for target seq file
%
% OUTPUTS
%
% EXAMPLE
%
% See also seqIo
assert(~strcmp(tName,fName)); sr=reader(fName); infor=sr.getinfo();
if(nargin<4 || isempty(info)), info=infor; end
info.width=infor.width; info.height=infor.height;
sw=seqIo(tName,'w',info); n=infor.numFrames;
for f=1:n, [I,ts]=sr.getnext(); I=imgFun(I); sw.addframe(I,ts); end
sw.close(); sr.close();
end

function header( fName, info )
% action='header': Replace header of seq file w provided info.
%  seqIo(fName,'header',info)
srp=@seqReaderPlugin; swp=@seqWriterPlugin;
[d,n]=fileparts(fName); if(isempty(d)), d='.'; end
fName=[d '/' n]; oName=[fName '-' datestr(now,30)];
if(exist([fName '-seek.mat'],'file')); delete([fName '-seek.mat']); end
movefile([fName '.seq'],[oName '.seq'],'f');
hr = srp( 'open', int32(-1), oName, info );
info = seqReaderPlugin('getinfo',hr);
hw = swp( 'open', int32(-1), fName, info );
for frame = 0:info.numFrames-1, srp('next',hr);
  [I,ts]=srp('getframeb',hr); swp('addframeb',hw,I,ts); end
srp('close',hr); swp('close',hw);
end

function sobj = readerDual( fName1, fName2 )
% action=='rdual': Wrapper for two videos of the same image dims and roughly
% the same frame counts that are treated as a single IO object. getframe()
% returns the concatentation of the two frames. For videos of different
% frame counts, the first video serves as the "dominant" video and the
% frame count of the second video is adjusted accordingly. Same general
% usage as in action=='r', but the only supported operations are: close(),
% getframe(), getinfo(), and seek(). Open with:
%  sr = seqIo( {fName1,fName2}, 'rdual' )
srp=@seqReaderPlugin;
s1=srp('open',int32(-1),fName1); s2=srp('open',int32(-1),fName2);
i1=srp('getinfo',s1); i2=srp('getinfo',s2);
if( i1.width~=i2.width || i1.height~=i2.height )
  close(); error('Mismatched videos');
end
sobj=struct('close',@close, 'getframe',@getframe, ...
  'getinfo',@getinfo, 'seek',@seek );

  function out=close(), out=srp('close',s1); srp('close',s2); end

  function [I,t]=getframe()
    [I1,t1]=srp('getframe',s1); [I2,t2]=srp('getframe',s2);
    I=[I1 I2]; t=(t1+t2)/2;
  end

  function info=getinfo(), info=i1; info.width=i1.width+i2.width; end

  function out=seek(f)
    f2 = round( f/(i1.numFrames-1)*(i2.numFrames-1) );
    out = srp('seek',s1,f) & srp('seek',s2,f2);
  end
end
