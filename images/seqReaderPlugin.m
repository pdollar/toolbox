function [out,out2] = seqReaderPlugin( cmd, handle, varargin )
% Plugin to allow reading of seq files.
%
% A seq file is a series of concatentated image frames with a fixed size
% header. It is essentially the same as merging a directory of images into
% a single file. seq files are convenient for storing videos because: (1)
% no video codec is required, (2) seek is instant and exact, (3) seq files
% can be read on any operating system. The main drawback is that each frame
% is encoded independently, resulting in increased file size. The advantage
% over storing as a directory of images is that a single large file is
% created. Currently, either uncompressed or jpg compressed frames are
% supported. Should not be called directly, rather use with seqIo or
% videoIO. The seq file format is very similar to the Norpix seq format (in
% fact this reader can be used to read some Norpix seq files).
%
% The plugin is intended for use with the videoIO Toolbox for Matlab
% written by Gerald Daley: http://sourceforge.net/projects/videoio/. It
% follows the conventions and format of videoIO.  However, it can also be
% used with the wrapper seqIo instead. Note, that this has actually NOT
% been tested as a plugin for VideoIO yet.
%
% Seq files are manipulated using a unique handle created upon opening the
% file. The string cmd is used to dictate available operations. The
% following is a list of commands available (modeled after videoIO):
%  'open': Open a seq file for reading (input handle ignored).
%    handle = seqReaderPlugin( 'open', handle, fName )
%  'close': Close seq file (output handle is -1).
%    handle = seqReaderPlugin( 'close', handle )
%  'getframe': Get current frame (returns [] if invalid frame).
%    [I,ts] = seqReaderPlugin( 'getframe', handle )
%  'getframeb': Get current frame with no decoding (raw bytes).
%    [I,ts] = seqReaderPlugin( 'getframeb', handle )
%  'getinfo': Return struct with info about video.
%    info = seqReaderPlugin( 'getinfo', handle )
%  'getnext': Shortcut for 'next' followed by 'getframe'.
%    [I,ts] = seqReaderPlugin( 'getnext', handle )
%  'next': Go to next frame (out=-1 on fail).
%    out = seqReaderPlugin( 'next', handle )
%  'seek': Go to specified frame (out=-1 on fail).
%    out = seqReaderPlugin( 'seek', handle, frame )
%  'step': Go to current frame + delta (out=-1 on fail).
%    out = seqReaderPlugin( 'step', handle, delta )
%
% USAGE
%  out = seqReaderPlugin( cmd, handle, varargin )
%
% INPUTS
%  cmd        - string indicating operation to perform
%  handle     - unique identifier for open seq file
%  varargin   - additional options (vary according to cmd)
%
% OUTPUTS
%  out        - output (varies according to cmd)
%  out2       - output (varies according to cmd)
%
% EXAMPLE
%
% See also SEQIO, SEQWRITERPLUGIN
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% persistent variables to keep track of all loaded .seq files
persistent nextHandle handles cFrms fids infos tNms;
if( isempty(nextHandle) )
  nextHandle = int32(now);          % handle to use for the next open cmd
  handles    = zeros(0,0,'int32');  % list of currently-active handles
  cFrms      = [];                  % current frame num for each handle
  fids       = [];                  % handle to .seq file for each handle
  infos      = {};                  % info for each handle
  tNms       = {};                  % names for temporary files
end
nIn=nargin-2; in=varargin;

if(strcmp(cmd,'open')) % open seq file
  chk(nIn,1); fName=in{1}; h=length(handles)+1;
  handles(h)=nextHandle; out=nextHandle; nextHandle=int32(nextHandle+1);
  [pth name]=fileparts(fName); if(isempty(pth)), pth='.'; end
  fName=[pth filesep name '.seq']; cFrms(h)=-1;
  [infos{h},fids(h),tNms{h}] = open(fName); return;
end

% Get the handle for this instance
[v,h] = ismember(handle,handles); out2=[];
if(~v), error('Invalid load plugin handle'); end
cFrm=cFrms(h); fid=fids(h); info=infos{h}; tNm=tNms{h};

if(strcmp(cmd,'close')) % close seq file
  chk(nIn,0); fclose(fids(h)); kp=[1:h-1 h+1:length(handles)];
  handles=handles(kp); cFrms=cFrms(kp); fids=fids(kp); infos=infos(kp);
  tNms=tNms(kp); if(exist(tNm,'file')), delete(tNm); end; out=nan; return;
end

% perform appropriate operation
switch( cmd )
  case 'getframe',  chk(nIn,0); [out,out2]=getFrame(cFrm,fid,info,tNm);
  case 'getframeb', chk(nIn,0); [out,out2]=getFrameb(cFrm,fid,info);
  case 'getinfo',   chk(nIn,0); out=info;
  case 'getnext',   chk(nIn,0); cFrm=valid(cFrm+1,info);
    [out,out2]=getFrame(cFrm,fid,info,tNm);
  case 'next',      chk(nIn,0); [cFrm,out]=valid(cFrm+1,info);
  case 'seek',      chk(nIn,1); [cFrm,out]=valid(in{1},info);
  case 'step',      chk(nIn,1); [cFrm,out]=valid(cFrm+in{1},info);
  otherwise,        error(['Unrecognized command: "' cmd '"']);
end
cFrms(h)=cFrm;

end

function chk(nIn,nMin,nMax)
if(nargin<3), nMax=nMin; end
if(nIn>0 && nMin==0 && nMax==0), error(['"' cmd '" takes no args.']); end
if(nIn<nMin||nIn>nMax), error(['Incorrect num args for "' cmd '".']); end
end

function getImgFile( fName )
% create local copy of fName which is in a imagesci/private
fName = [fName '.' mexext]; s = filesep;
sName = [fileparts(which('imread.m')) s 'private' s fName];
tName = [fileparts(mfilename('fullpath')) s 'private' s fName];
if(~exist(tName,'file')), copyfile(sName,tName); end
end

function [info, fid, tNm] = open( fName )
% open video for reading, get header
assert(exist(fName,'file')==2); fid=fopen(fName,'r','l');
info=readHeader( fid ); n=info.numFrames; tNm=[];
% compute seek info for jpg encoded images
if(any(info.imageFormat==[102 201]))
  [pth name]=fileparts(fName); oName=[pth '/' name '-seek.mat'];
  if(exist(oName,'file')==2), load(oName); info.seek=seek; else %#ok<NODEF>
    disp('loading seek info...'); seek=zeros(n,1,'uint32'); seek(1)=1024;
    for i=2:n
      seek(i)=seek(i-1)+fread(fid,1,'uint32')+16; fseek(fid,seek(i),'bof');
    end
    try save(oName,'seek'); catch; end; info.seek=seek; %#ok<CTCH>
  end
  tNm=['tmp' int2str(fid) '.jpg']; getImgFile( 'rjpg8c' );
end
% compute frame rate from timestamps as stored fps may be incorrect
n=min(100,n); if(n==1), return; end; ts=zeros(1,n);
for f=1:n, ts(f)=getTimeStamp(f-1,fid,info); end
dels=ts(2:end)-ts(1:end-1); info.fps=1/median(dels);
end

function [frame,v] = valid( frame, info )
v=int32(frame>=0 && frame<info.numFrames);
end

function [I,ts] = getFrame( frame, fid, info, tNm )
% get frame image (I) and timestamp (ts) at which frame was recorded
imageFormat=info.imageFormat;
if(frame<0 || frame>=info.numFrames), I=[]; ts=[]; return; end
switch imageFormat
  case {100,200}
    % read in an uncompressed image (assume imageBitDepthReal==8)
    fseek(fid,1024+frame*info.trueImageSize,'bof');
    siz = [info.height info.width info.imageBitDepth/8];
    I = uint8(fread(fid,info.imageSizeBytes,'uint8'));
    % reshape appropriately for mxn or mxnx3 RGB image
    if( siz(3)==1 ), I=reshape(I,siz(2),siz(1))'; else
      I = permute(reshape(I,siz(3),siz(2),siz(1)),[3,2,1]);
    end
    if(imageFormat==200), t=I(:,:,3); I(:,:,3)=I(:,:,1); I(:,:,1)=t; end
  case {102,201}
    % write/read to/from temporary .jpg (not that much overhead)
    fseek(fid,info.seek(frame+1),'bof');
    nBytes=fread(fid,1,'uint32'); J=fread(fid,nBytes-4,'uint8');
    assert(J(1)==255 && J(2)==216 && J(end-1)==255 && J(end)==217); % JPG
    fw=fopen(tNm,'w'); assert(fw~=-1); fwrite(fw,J); fclose(fw);
    I=rjpg8c(tNm);
  otherwise, assert(false);
end
if(nargout==2), ts=fread(fid,1,'uint32')+fread(fid,1,'uint16')/1000; end
end

function [I,ts] = getFrameb( frame, fid, info )
% get frame I with no decoding
if(frame<0 || frame>=info.numFrames), I=[]; ts=[]; return; end
switch info.imageFormat;
  case {100,200}
    fseek(fid,1024+frame*info.trueImageSize,'bof');
    I = fread(fid,info.imageSizeBytes);
  case {102,201}
    fseek(fid,info.seek(frame+1),'bof');
    nBytes = fread(fid,1,'uint32'); fseek(fid,-4,'cof');
    I = fread(fid,nBytes,'uint8');
  otherwise, assert(false);
end
if(nargout==2), ts=fread(fid,1,'uint32')+fread(fid,1,'uint16')/1000; end
end

function ts = getTimeStamp( frame, fid, info )
% get timestamp (ts) at which frame was recorded
if(frame<0 || frame>=info.numFrames), ts=[]; return; end
switch info.imageFormat
  case {100,200} % uncompressed
    fseek(fid,1024+frame*info.trueImageSize+info.imageSizeBytes,'bof');
  case {102,201} % JPG compressed
    fseek(fid,info.seek(frame+1),'bof');
    fseek(fid,fread(fid,1,'uint32')-4,'cof');
  otherwise, assert(false);
end
ts=fread(fid,1,'uint32')+fread(fid,1,'uint16')/1000;
end

function info = readHeader( fid )
% see streampix manual for info on header
fseek(fid,0,'bof');
% first 4 bytes store OxFEED, next 24 store 'Norpix seq  '
assert(strcmp(sprintf('%X',fread(fid,1,'uint32')),'FEED'));
assert(strcmp(char(fread(fid,10,'uint16'))','Norpix seq')); %#ok<FREAD>
fseek(fid,4,'cof');
% next 8 bytes for version and header size (1024), then 512 for descr
version=fread(fid,1,'int32'); assert(fread(fid,1,'uint32')==1024);
descr=char(fread(fid,256,'uint16'))'; %#ok<FREAD>
% read in more info
tmp=fread(fid,9,'uint32'); assert(tmp(8)==0);
fps = fread(fid,1,'float64'); codec=['imageFormat' int2str(tmp(6))];
% store information in info struct
info=struct( 'width',tmp(1), 'height',tmp(2), 'imageBitDepth',tmp(3), ...
  'imageBitDepthReal',tmp(4), 'imageSizeBytes',tmp(5), ...
  'imageFormat',tmp(6), 'numFrames',tmp(7), 'trueImageSize', tmp(9),...
  'fps',fps, 'seqVersion',version, 'codec',codec, 'descr',descr, ...
  'nHiddenFinalFrames',0 );
assert(info.imageBitDepthReal==8);
% seek to end of header
fseek(fid,432,'cof');
end
