function varargout = seqWriterPlugin( cmd, h, varargin )
% Plugin for seqIo and videoIO to allow writing of seq files.
%
% Do not call directly, use as plugin for seqIo or videoIO instead.
% The following is a list of commands available (swp=seqWriterPlugin):
%  h=swp('open',h,fName,info) % Open a seq file for writing (h ignored).
%  h=swp('close',h)           % Close seq file (output h is -1).
%  swp('addframe',h,I,[ts])   % Writes video frame (and timestamp).
%  swp('addframeb',h,I,[ts])  % Writes video frame with no encoding.
%  info = swp('getinfo',h)    % Return struct with info about video.
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
%  varargout = seqWriterPlugin( cmd, h, varargin )
%
% INPUTS
%  cmd        - string indicating operation to perform
%  h          - unique identifier for open seq file
%  varargin   - additional options (vary according to cmd)
%
% OUTPUTS
%  varargout  - output (varies according to cmd)
%
% EXAMPLE
%
% See also SEQIO, SEQREADERPLUGIN
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.66
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% persistent variables to keep track of all loaded .seq files
persistent h1 hs fids infos tNms;
if(isempty(h1)), h1=int32(now); hs=int32([]); infos={}; tNms={}; end
nIn=nargin-2; in=varargin; o1=[]; cmd=lower(cmd);

% open seq file
if(strcmp(cmd,'open'))
  chk(nIn,2); h=length(hs)+1; hs(h)=h1; varargout={h1}; h1=h1+1;
  [pth,name]=fileparts(in{1}); if(isempty(pth)), pth='.'; end
  fName=[pth filesep name];
  [infos{h},fids(h),tNms{h}]=open(fName,in{2}); return;
end

% Get the handle for this instance
[v,h]=ismember(h,hs); if(~v), error('Invalid load plugin handle'); end
fid=fids(h); info=infos{h}; tNm=tNms{h};

% close seq file
if(strcmp(cmd,'close'))
  writeHeader(fid,info);
  chk(nIn,0); varargout={-1}; fclose(fid); kp=[1:h-1 h+1:length(hs)];
  hs=hs(kp); fids=fids(kp); infos=infos(kp);
  tNms=tNms(kp); if(exist(tNm,'file')), delete(tNm); end; return;
end

% perform appropriate operation
switch( cmd )
  case 'addframe',  chk(nIn,1,2); info=addFrame(fid,info,tNm,1,in{:});
  case 'addframeb', chk(nIn,1,2); info=addFrame(fid,info,tNm,0,in{:});
  case 'getinfo',   chk(nIn,0); o1=info;
  otherwise,        error(['Unrecognized command: "' cmd '"']);
end
infos{h}=info; varargout={o1};

end

function chk(nIn,nMin,nMax)
if(nargin<3), nMax=nMin; end
if(nIn>0 && nMin==0 && nMax==0), error(['"' cmd '" takes no args.']); end
if(nIn<nMin||nIn>nMax), error(['Incorrect num args for "' cmd '".']); end
end

function success = getImgFile( fName )
% create local copy of fName which is in a imagesci/private
fName = [fName '.' mexext]; s = filesep; success = 1;
sName = [fileparts(which('imread.m')) s 'private' s fName];
tName = [fileparts(mfilename('fullpath')) s 'private' s fName];
if(~exist(tName,'file')), success=copyfile(sName,tName); end
end

function [info, fid, tNm] = open( fName, info )
% open video for writing, create space for header
t=[fName '.seq']; if(exist(t,'file')), delete(t); end
t=[fName '-seek.mat']; if(exist(t,'file')), delete(t); end
fid=fopen([fName '.seq'],'w','l'); assert(fid~=-1);
fwrite(fid,zeros(1,1024),'uint8');
% initialize info struct (w all fields necessary for writeHeader)
assert(isfield2(info,{'width','height','fps','codec'},1));
switch(info.codec)
  case {'monoraw', 'imageFormat100'}, frmt=100; nCh=1; ext='raw';
  case {'raw', 'imageFormat200'},     frmt=200; nCh=3; ext='raw';
  case {'monojpg', 'imageFormat102'}, frmt=102; nCh=1; ext='jpg';
  case {'jpg', 'imageFormat201'},     frmt=201; nCh=3; ext='jpg';
  case {'monopng', 'imageFormat001'}, frmt=001; nCh=1; ext='png';
  case {'png', 'imageFormat002'},     frmt=002; nCh=3; ext='png';
  otherwise, error('unknown format');
end; s=1;
if(strcmp(ext,'jpg')), s=getImgFile('wjpg8c'); end
if(strcmp(ext,'png')), s=getImgFile('png');
  if(s), info.writeImg=@(p) png('write',p{:}); end; end
if(strcmp(ext,'png') && ~s), s=getImgFile('pngwritec');
  if(s), info.writeImg=@(p) pngwritec(p{:}); end; end
if(~s), error('Cannot find Matlab''s source image writer'); end
info.imageFormat=frmt; info.ext=ext;
if(any(strcmp(ext,{'jpg','png'}))), info.seek=1024; info.seekNm=t; end
if(~isfield2(info,'quality')), info.quality=80; end
info.imageBitDepth=8*nCh; info.imageBitDepthReal=8;
nByte=info.width*info.height*nCh; info.imageSizeBytes=nByte;
info.numFrames=0; info.trueImageSize=nByte+6+512-mod(nByte+6,512);
% generate unique temporary name
[~,tNm]=fileparts(fName); t=clock; t=mod(t(end),1);
tNm=sprintf('tmp_%s_%15i.%s',tNm,round((t+rand)/2*1e15),ext);
end

function info = addFrame( fid, info, tNm, encode, I, ts )
% write frame
nCh=info.imageBitDepth/8; ext=info.ext; c=info.numFrames+1;
if( encode )
  siz = [info.height info.width nCh];
  assert(size(I,1)==siz(1) && size(I,2)==siz(2) && size(I,3)==siz(3));
end
switch ext
  case 'raw'
    % write an uncompressed image (assume imageBitDepthReal==8)
    if( ~encode ), assert(numel(I)==info.imageSizeBytes); else
      if(nCh==3), t=I(:,:,3); I(:,:,3)=I(:,:,1); I(:,:,1)=t; end
      if(nCh==1), I=I'; else I=permute(I,[3,2,1]); end
    end
    fwrite(fid,I(:),'uint8'); pad=info.trueImageSize-info.imageSizeBytes-6;
  case 'jpg'
    if( encode )
      % write/read to/from temporary .jpg (not that much overhead)
      p=struct('quality',info.quality,'comment',{{}},'mode','lossy');
      for t=0:99, try wjpg8c(I,tNm,p); fr=fopen(tNm,'r'); assert(fr>0);
          break; catch, pause(.01); fr=-1; end; end %#ok<CTCH>
      if(fr<0), error(['write fail: ' tNm]); end; I=fread(fr); fclose(fr);
    end
    assert(I(1)==255 && I(2)==216 && I(end-1)==255 && I(end)==217); % JPG
    fwrite(fid,numel(I)+4,'uint32'); fwrite(fid,I); pad=10;
  case 'png'
    if( encode )
      % write/read to/from temporary .png (not that much overhead)
      p=cell(1,17); if(nCh==1), p{4}=0; else p{4}=2; end
      p{1}=I; p{3}=tNm; p{5}=8; p{8}='none'; p{16}=cell(0,2);
      for t=0:99, try info.writeImg(p); fr=fopen(tNm,'r'); assert(fr>0);
          break; catch, pause(.01); fr=-1; end; end %#ok<CTCH>
      if(fr<0), error(['write fail: ' tNm]); end; I=fread(fr); fclose(fr);
    end
    fwrite(fid,numel(I)+4,'uint32'); fwrite(fid,I); pad=10;
  otherwise, assert(false);
end
% store seek info
if(any(strcmp(ext,{'jpg','png'})))
  if(length(info.seek)<c+1), info.seek=[info.seek; zeros(c,1)]; end
  info.seek(c+1)=info.seek(c)+numel(I)+10+pad;
end
% write timestamp
if(nargin<6),ts=(c-1)/info.fps; end; s=floor(ts); ms=round(mod(ts,1)*1000);
fwrite(fid,s,'int32'); fwrite(fid,ms,'uint16'); info.numFrames=c;
% pad with zeros
if(pad>0), fwrite(fid,zeros(1,pad),'uint8'); end
end

function writeHeader( fid, info )
fseek(fid,0,'bof');
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
% write seek info for compressed images to disk
if(any(strcmp(info.ext,{'jpg','png'})))
  seek=info.seek(1:info.numFrames); %#ok<NASGU>
  try save(info.seekNm,'seek'); catch; end %#ok<CTCH>
end
end
