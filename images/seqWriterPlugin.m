function out = seqWriterPlugin( cmd, handle, varargin )
% Plugin to allow writing of seq files.
%
% For information on .seq files and general usage see seqReaderPlugin.
%
% When opening a sequence writer, the following parameters must be
% specified in the struct info:
%  width          - frame width
%  height         - frame height
%  fps            - frames per second of resulting video
%  codec          - string representing codec, options include:
%   {'monoraw', 'imageFormat100'}     - black/white uncompressed
%   {'raw', 'imageFormat200'}         - color (BGR) uncompressed
%   {'monojpg', 'imageFormat102'}     - black/white jpg compressed
%   {'jpg', 'imageFormat201'}         - color jpg compressed
%  quality        - [80] compression quality (between 0 and 100)
%
% The following is a list of commands available (modeled after videoIO):
%  'open': Open a seq file for writing (input handle ignored).
%    handle = seqWriterPlugin( 'open', handle, fName, info )
%  'close': Close seq file (output handle is -1).
%    handle = seqWriterPlugin( 'close', handle )
%  'addframe': Writes a video frame.
%    seqWriterPlugin( 'addframe', handle, I, [ts] )
%  'addframeb': Writes a video frame with no encoding.
%    seqWriterPlugin( 'addframeb', handle, I, [ts] )
%
% USAGE
%  out = seqWriterPlugin( cmd, handle, varargin )
%
% INPUTS
%  cmd        - string indicating operation to perform
%  handle     - unique identifier for open seq file
%  varargin   - additional options (vary according to cmd)
%
% OUTPUTS
%  out        - output (varies according to cmd)
%
% EXAMPLE
%
% See also SEQREADERPLUGIN, SEQIO
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
  chk(nIn,2); fName=in{1}; h=length(handles)+1;
  handles(h)=nextHandle; out=nextHandle; nextHandle=int32(nextHandle+1);
  [pth name]=fileparts(fName); if(isempty(pth)), pth='.'; end
  fName=[pth filesep name '.seq']; cFrms(h)=-1;
  [infos{h},fids(h),tNms{h}] = open(fName,in{2}); return;
end

% Get the handle for this instance
[v,h] = ismember(handle,handles);
if(~v), error('Invalid load plugin handle'); end
cFrm=cFrms(h); fid=fids(h); info=infos{h}; tNm=tNms{h};

if(strcmp(cmd,'close')) % close seq file
  writeHeader(fid,info,cFrm);
  chk(nIn,0); fclose(fids(h)); kp=[1:h-1 h+1:length(handles)];
  handles=handles(kp); cFrms=cFrms(kp); fids=fids(kp); infos=infos(kp);
  tNms=tNms(kp); if(exist(tNm,'file')), delete(tNm); end; out=nan; return
end

% perform appropriate operation
switch( cmd )
  case 'addframe',  chk(nIn,1,2); cFrm=addFrame(fid,info,cFrm,tNm,in{:});
  case 'addframeb', chk(nIn,1,2); cFrm=addFrameb(fid,info,cFrm,in{:});
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

function [info, fid, tNm] = open( fName, info )
% open video for writing, create space for header
if(exist(fName,'file')), delete(fName); end
fid=fopen(fName,'w','l'); assert(fid~=-1);
fwrite(fid,zeros(1,1024),'uint8'); tNm=[];
% initialize info struct (w all fields necessary for writeHeader)
assert(isfield2(info,{'width','height','fps','codec'},1));
switch(info.codec)
  case {'monoraw', 'imageFormat100'}, info.imageFormat=100; nCh=1;
  case {'raw', 'imageFormat200'},     info.imageFormat=200; nCh=3;
  case {'monojpg', 'imageFormat102'}, info.imageFormat=102; nCh=1;
  case {'jpg', 'imageFormat201'},     info.imageFormat=201; nCh=3;
end
if(any(info.imageFormat==[102 201]))
  tNm=['tmp' int2str(fid) '.jpg']; getImgFile( 'wjpg8c' );
end
if(~isfield2(info,'quality')), info.quality=80; end
info.imageBitDepth=8*nCh; info.imageBitDepthReal=8;
nByte=info.width*info.height*nCh; info.imageSizeBytes=nByte;
info.numFrames=0; info.trueImageSize=nByte+6+512-mod(nByte+6,512);
end

function cFrm = addFrame( fid, info, cFrm, tNm, I, ts )
% write frame
imageFormat=info.imageFormat; cFrm=cFrm+1;
siz = [info.height info.width info.imageBitDepth/8];
assert(size(I,1)==siz(1) && size(I,2)==siz(2) && size(I,3)==siz(3));
switch imageFormat
  case {100,200}
    % write an uncompressed image (assume imageBitDepthReal==8)
    if(imageFormat==200), t=I(:,:,3); I(:,:,3)=I(:,:,1); I(:,:,1)=t; end
    if( siz(3)==1 ), I=I'; else I=permute(I,[3,2,1]); end
    fwrite(fid,I(:),'uint8'); pad=info.trueImageSize-info.imageSizeBytes-6;
  case {102,201}
    % write/read to/from temporary .jpg (not that much overhead)
    q=info.quality;
    wjpg8c(I,tNm,struct('quality',q,'comment',{{}},'mode','lossy'));
    fr=fopen(tNm,'r'); assert(fr~=-1); J=fread(fr); fclose(fr);
    assert(J(1)==255 && J(2)==216 && J(end-1)==255 && J(end)==217); % JPG
    fwrite(fid,numel(J)+4,'uint32'); fwrite(fid,J); pad=10;
  otherwise, assert(false);
end
% write timestamp
if(nargin<6), ts=cFrm/info.fps; end; s=floor(ts); ms=floor(mod(ts,1)*1000);
fwrite(fid,s,'int32'); fwrite(fid,ms,'uint16');
% pad with zeros
if(pad>0), fwrite(fid,zeros(1,pad),'uint8'); end
end

function cFrm = addFrameb( fid, info, cFrm, I, ts )
% Write video frame with no encoding.
switch info.imageFormat
  case {100,200}
    assert(numel(I)==info.imageSizeBytes);
    pad=info.trueImageSize-info.imageSizeBytes-6;
  case {102,201}
    assert(I(5)==255 && I(6)==216 && I(end-1)==255 && I(end)==217); pad=10;
  otherwise, assert(false);
end
fwrite(fid,I(:)); cFrm=cFrm+1;
if(nargin<5), ts=cFrm/info.fps; end; s=floor(ts); ms=floor(mod(ts,1)*1000);
fwrite(fid,s,'int32'); fwrite(fid,ms,'uint16');
if(pad>0), fwrite(fid,zeros(1,pad),'uint8'); end
end

function writeHeader( fid, info, cFrm )
fseek(fid,0,'bof'); info.numFrames=cFrm+1;
% first 4 bytes store OxFEED, next 24 store 'Norpix seq  '
fwrite(fid,hex2dec('FEED'),'uint32');
fwrite(fid,['Norpix seq' 0 0],'uint16');
% next 8 bytes for version (3) and header size (1024), then 512 for descr
fwrite(fid,[3 1024],'int32');
if(isfield(info,'descr')), d=info.descr(:); else d=('No Description')'; end
d=[d(1:min(256,end)); zeros(256-length(d),1)]; fwrite(fid,d,'uint16');
% write remaining info
vals=[info.width info.height info.imageBitDepth info.imageBitDepthReal ...
  info.imageSizeBytes info.imageFormat info.numFrames 0 ...
  info.trueImageSize];
fwrite(fid,vals,'uint32');
% store frame rate and pad with 0's
fwrite(fid,info.fps,'float64'); fwrite(fid,zeros(1,432),'uint8');
end
