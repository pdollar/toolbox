function sobj = seqIo( fName, mode, varargin )
% Wrapper for reading/writing seq files.
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
% videoIO. The seq file format is modeled after the Norpix seq format (in
% fact this reader can be used to read some Norpix seq files).
%
% The actual work of reading/writing seq files is done by seqReaderPlugin
% and seqWriterPlugin. These plugins were originally intended for use with
% the videoIO Toolbox for Matlab written by Gerald Daley:
%  http://sourceforge.net/projects/videoio/.
% However, the plugins also work with seqIo.m (this function), and there is
% no need to actually have videoIO installed to use seq files. In fact,
% the plugins have not yet been tested with videoIO.
%
% mode=='r': Serves as a wrapper for seqReaderPlugin, available actions:
%  sr=seqIo(fName,'r')    % Create new sequence reader object.
%  sr.close();            % Close seq file (sr is useless after).
%  [I,ts]=sr.getframe();  % Get current frame (returns [] if invalid).
%  [I,ts]=sr.getframeb(); % Get current frame with no decoding.
%  ts = sr.getts();       % Return timestamps for all frames.
%  info = sr.getinfo();   % Return struct with info about video.
%  [I,ts]=sr.getnext();   % Shortcut for next() followed by getframe().
%  out = sr.next();       % Go to next frame (out=-1 on fail).
%  out = sr.seek(frame);  % Go to specified frame (out=-1 on fail).
%  out = sr.step(delta);  % Go to current frame + delta (out=-1 on fail).
% See seqReaderPlugin for more info about the individual actions.
%
% mode=='w': Serves as a wrapper for seqWriterPlugin, available actions:
%  sw=seqIo(fName,'w',info) % Create new sequence writer object.
%  sw.close();              % Close seq file (sw is useless after).
%  sw.addframe(I,[ts]);     % Writes video frame (and timestamp)
%  sw.addframeb(bytes);     % Writes video frame with no encoding.
%  info = sw.getinfo();     % Return struct with info about video.
% See seqWriterPlugin for more info about the individual actions and about
% the parameter sturcutre 'info' used to create the writer.
%
% mode=='rdual': Wrapper for two videos of the same image dims and roughly
% the same frame counts that are treated as a single IO object. getframe()
% returns the concatentation of the two frames. For videos of different
% frame counts, the first video serves as the "dominant" video and the
% frame count of the second video is adjusted accordingly. Same general
% usage as in mode=='r', but the only supported operations are: close(),
% getframe(), getinfo(), and seek(). Open with:
%  sr = seqIo( {fName1,fName2}, 'rdual' )
%
% mode=='getinfo': Get info about seq file.
%  info = seqIo( fName, 'getinfo' )
%
% mode=='crop': Crop subsequence from seq file:
%  seqIo( fName, 'crop', tName, f0, f1 )
%  seqIo( fName, 'crop', tName, frames )
%
% mode=='toimgs': Extract images from seq file to dir/I[frame,5].ext:
%  seqIo( fName, 'toimgs', dir, [skip] )
%
% mode=='frimgs': Make seq file from images in dir/I[frame,5].ext:
%  seqIo( fName, 'frimgs', dir, info, [skip] )
%
% mode=='frimgs': Make seq file from images in array IS:
%  seqIo( fName, 'frimgs', IS, info )
%
% mode='convert': Convert fName to tName applying imgFun(I) to each frame.
%  seqIo( fName, 'convert', tName, imgFun, [info], [skip] )
%
% mode='header': Replace header of seq file w provided info.
%  seqIo(fName,'header',info)
%
% USAGE
%  sobj = seqIo( fName, mode, varargin )
%
% INPUTS
%  fName      - seq file to open
%  mode       - 'r'=read, 'w'=write, for other modes see above
%  varargin   - additional input (varies according to cmd)
%
% OUTPUTS
%  sobj       - object used to access seq file
%
% EXAMPLE
%
% See also SEQPLAYER, SEQREADERPLUGIN, SEQWRITERPLUGIN
%
% Piotr's Image&Video Toolbox      Version 2.41
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

srp=@seqReaderPlugin;
swp=@seqWriterPlugin;

mode=lower(mode);
if( strcmp(mode,'r') )
  % sr = seqIo(fName,'r')
  s = srp( 'open', int32(-1), fName );
  sobj = struct( 'close',@() srp('close',s), ...
    'getframe',@() srp('getframe',s), ...
    'getframeb',@() srp('getframeb',s), 'getts',@() srp('getts',s), ...
    'getinfo',@() srp('getinfo',s), 'getnext',@() srp('getnext',s), ...
    'next',@() srp('next',s), 'seek',@(f) srp('seek',s,f), ...
    'step',@(d) srp('step',s,d));
  
elseif( strcmp(mode,'w') )
  % sw = seqIo(fName,'w',info)
  s = swp( 'open', int32(-1), fName, varargin{1} );
  sobj = struct( 'close',@() swp('close',s), ...
    'addframe',@(varargin) swp('addframe',s,varargin{:}), ...
    'addframeb',@(varargin) swp('addframeb',s,varargin{:}), ...
    'getinfo',@() swp('getinfo',s) );
  
elseif( strcmp(mode,'rdual') )
  sobj = seqReaderDual(fName{:});
  
elseif( strcmp(mode,'getinfo') )
  % info = seqIo( fName, 'getinfo' )
  sr=seqIo(fName,'r'); sobj=sr.getinfo(); sr.close();
  
elseif( strcmp(mode,'crop') )
  % seqIo( fName, 'crop', tName, f0, f1 )
  % seqIo( fName, 'crop', tName, frames )
  tName=varargin{1}; fs=varargin{2}; ordered=0;
  if(nargin==5), fs=fs:varargin{3}; ordered=1; end; fs=fs(:)';
  sr=seqIo(fName,'r'); info=sr.getinfo();
  sw=seqIo(tName,'w',info); pad=sr.getnext(); pad(:)=0;
  for f=fs
    if( ordered )
      sr.seek(f); [I,ts]=sr.getframeb(); sw.addframeb(I,ts);
    elseif( f>=0 )
      sr.seek(f); I=sr.getframeb(); sw.addframeb(I);
    else
      sw.addframe(pad);
    end
  end
  sw.close(); sr.close();
  
elseif( strcmp(mode,'toimgs') )
  % seqIo( fName, 'toimgs', dir, [skip] )
  d=varargin{1}; if(~exist(d,'dir')), mkdir(d); end
  if(nargin==4), skip=varargin{2}; else skip=1; end
  sr=seqIo(fName,'r'); info=sr.getinfo(); ext=['.' info.ext];
  for frame = skip-1:skip:info.numFrames-1
    f=[d '/I' int2str2(frame,5) ext]; sr.seek(frame);
    I=sr.getframeb(); f=fopen(f,'w'); assert(f>0); fwrite(f,I); fclose(f);
  end
  sr.close();
  
elseif( strcmp(mode,'frimgs') && ischar(varargin{1}) )
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
  
elseif( strcmp(mode,'frimgs') )
  % seqIo( fName, 'frimgs', IS, info )
  IS=varargin{1}; info=varargin{2};
  nd=ndims(IS); if(nd==2), nd=3; end; assert(nd<=4); nFrm=size(IS,nd);
  info.height=size(IS,1); info.width=size(IS,2); sw=seqIo(fName,'w',info);
  if(nd==3), for f=1:nFrm, sw.addframe(IS(:,:,f)); end; end
  if(nd==4), for f=1:nFrm, sw.addframe(IS(:,:,:,f)); end; end
  sw.close();
  
elseif( strcmp(mode,'convert') )
  % seqIo( fName, 'convert', tName, imgFun, [info], [skip] )
  tName=varargin{1}; imgFun=varargin{2}; assert(~strcmp(tName,fName));
  if(nargin>=5), info=varargin{3}; else info=[]; end
  if(nargin>=6), skip=varargin{4}; else skip=1; end
  sr=seqIo(fName,'r'); if(isempty(info)), info=sr.getinfo(); end
  I=sr.getnext(); info.width=size(I,2); info.height=size(I,1);
  sw=seqIo(tName,'w',info);
  for frame = skip-1:skip:info.numFrames-1
    sr.seek(frame); [I,ts]=sr.getframe(); I=imgFun(I); sw.addframe(I,ts);
  end
  sw.close(); sr.close();
  
elseif( strcmp(mode,'header') )
  % seqIo(fName,'header',info)
  [d,n]=fileparts(fName); fName=[d '/' n];
  oName=[fName '-' datestr(now,30)];
  if(exist([fName '-seek.mat'],'file')); delete([fName '-seek.mat']); end
  movefile([fName '.seq'],[oName '.seq'],'f');
  hr = srp( 'open', int32(-1), oName, varargin{1} );
  info = seqReaderPlugin('getinfo',hr);
  hw = swp( 'open', int32(-1), fName, info );
  for frame = 0:info.numFrames-1, srp('next',hr);
    [I,ts]=srp('getframeb',hr); swp('addframeb',hw,I,ts); end
  srp('close',hr); swp('close',hw);
  
end

  function sobj = seqReaderDual( fName1, fName2 )
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

end
