function varargout = seqWriterPlugin( cmd, h, varargin )
% Plugin for seqIo and videoIO to allow writing of seq files.
%
% Do not call directly, use as plugin for seqIo or videoIO instead.
% The following is a list of commands available (swp=seqWriterPlugin):
%  h=swp('open',h,fName,info) % Open a seq file for writing (h ignored).
%  h=swp('close',h)           % Close seq file (output h is -1).
%  swp('addframe',h,I,[ts])   % Writes a video frame.
%  swp('addframeb',h,I,[ts])  % Writes a video frame with no encoding.
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
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% persistent variables to keep track of all loaded .seq files
persistent h1 hs cfs fids infos tNms;
if(isempty(h1)), h1=int32(now); hs=int32([]); infos={}; tNms={}; end
nIn=nargin-2; in=varargin; o1=[];

% open seq file
if(strcmp(cmd,'open'))
  chk(nIn,2); h=length(hs)+1; hs(h)=h1; varargout={h1}; h1=h1+1;
  [pth name]=fileparts(in{1}); if(isempty(pth)), pth='.'; end
  fName=[pth filesep name '.seq']; cfs(h)=-1;
  [infos{h},fids(h),tNms{h}]=open(fName,in{2}); return;
end

% Get the handle for this instance
[v,h]=ismember(h,hs); if(~v), error('Invalid load plugin handle'); end
cf=cfs(h); fid=fids(h); info=infos{h}; tNm=tNms{h};

% close seq file
if(strcmp(cmd,'close'))
  writeHeader(fid,info,cf);
  chk(nIn,0); varargout={-1}; fclose(fid); kp=[1:h-1 h+1:length(hs)];
  hs=hs(kp); cfs=cfs(kp); fids=fids(kp); infos=infos(kp);
  tNms=tNms(kp); if(exist(tNm,'file')), delete(tNm); end; return;
end

% perform appropriate operation
switch( cmd )
  case 'addframe', chk(nIn,1,2); cf=addFrame(fid,info,cf,tNm,1,in{:});
  case 'addframeb',chk(nIn,1,2); cf=addFrame(fid,info,cf,tNm,0,in{:});
  otherwise,       error(['Unrecognized command: "' cmd '"']);
end
cfs(h)=cf; varargout={o1};

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

function cf = addFrame( fid, info, cf, tNm, encode, I, ts )
% write frame
imageFormat=info.imageFormat; cf=cf+1;
if( encode )
  siz = [info.height info.width info.imageBitDepth/8];
  assert(size(I,1)==siz(1) && size(I,2)==siz(2) && size(I,3)==siz(3));
end
switch imageFormat
  case {100,200}
    % write an uncompressed image (assume imageBitDepthReal==8)
    if( ~encode ), assert(numel(I)==info.imageSizeBytes); else
      if(imageFormat==200), t=I(:,:,3); I(:,:,3)=I(:,:,1); I(:,:,1)=t; end
      if( siz(3)==1 ), I=I'; else I=permute(I,[3,2,1]); end
    end
    fwrite(fid,I(:),'uint8'); pad=info.trueImageSize-info.imageSizeBytes-6;
  case {102,201}
    % write/read to/from temporary .jpg (not that much overhead)
    q=info.quality; pad=10;
    if( ~encode ), fwrite(fid,I(:),'uint8'); else
      wjpg8c(I,tNm,struct('quality',q,'comment',{{}},'mode','lossy'));
      fr=fopen(tNm,'r'); assert(fr~=-1); I=fread(fr); fclose(fr);
      assert(I(1)==255 && I(2)==216 && I(end-1)==255 && I(end)==217); % JPG
      fwrite(fid,numel(I)+4,'uint32'); fwrite(fid,I);
    end
  otherwise, assert(false);
end
% write timestamp
if(nargin<7), ts=cf/info.fps; end; s=floor(ts); ms=floor(mod(ts,1)*1000);
fwrite(fid,s,'int32'); fwrite(fid,ms,'uint16');
% pad with zeros
if(pad>0), fwrite(fid,zeros(1,pad),'uint8'); end
end

function writeHeader( fid, info, cf )
fseek(fid,0,'bof'); info.numFrames=cf+1;
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
