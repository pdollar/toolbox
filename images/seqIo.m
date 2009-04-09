function sobj = seqIo( fName, mode, info )
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
% videoIO. The seq file format is very similar to the Norpix seq format (in
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
% mode=='r': Serves as a for wrapper for seqReaderPlugin. Create with:
%  sr = seqIo( fName, 'r' )
% This creates the object sr which is used as the interface to the seq
% file. The available actions on sr (modeled on videoIO) are as follows:
%   sr.close();            % Close seq file (sr is useless after).
%   [I,ts]=sr.getframe();  % Get current frame (returns [] if invalid).
%   [I,ts]=sr.getframeb(); % Get current frame with no decoding.
%   info = sr.getinfo();   % Return struct with info about video.
%   [I,ts]=sr.getnext();   % Shortcut for next() followed by getframe().
%   out = sr.next();       % Go to next frame (out=-1 on fail).
%   out = sr.seek(frame);  % Go to specified frame (out=-1 on fail).
%   out = sr.step(delta);  % Go to current frame + delta (out=-1 on fail).
% See seqReaderPlugin for more info about the individual actions.
%
% mode=='w': Serves as a wrapper for seqWriterPlugin. Create with:
%  sw = seqIo( fName, 'w', info )
% This creates the object sw which is used as the interface to the seq
% file. The available actions on sw (modeled on videoIO) are as follows:
%   sw.close();            % Close seq file (sw is useless after).
%   sw.addframe(I,[ts]);   % Writes video frame (and timestamp)
%   sw.addframeb(bytes);   % Writes video frame with no encoding.
% See seqWriterPlugin for more info about the individual actions and about
% the parameter sturcutre 'info' used to create the writer.
%
% mode=='rdual': Wrapper for two videos of the same image dims and roughly
% the same frame counts that are treated as a single IO object. getframe()
% returns the concatentation of the two frames. For videos of different
% frame counts, the first video serves as the "dominant" video and the
% frame count of the second video is adjusted accordingly. Same general
% usage as in mode=='r', but the only supported operations are: close,
% getframe, getinfo, and seek. Open with:
%  sr = seqIo( {fName1,fName2}, 'rdual' )
%
% USAGE
%  sobj = seqIo( fName, mode, info )
%
% INPUTS
%  fName      - seq file to open
%  mode       - 'r' = read, 'w' = write, 'rdual' = dual read
%  info       - struct that defines seq encoding (see seqWriterPlugin)
%
% OUTPUTS
%  sobj       - object used to access seq file
%
% EXAMPLE
%
% See also SEQPLAYER, SEQREADERPLUGIN, SEQWRITERPLUGIN
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

srp=@seqReaderPlugin;
swp=@seqWriterPlugin;

if( strcmp(mode,'r') )
  s = srp( 'open', int32(-1), fName );
  sobj = struct( 'close',@() srp('close',s), ...
    'getframe',@() srp('getframe',s), ...
    'getframeb',@() srp('getframeb',s), ...
    'getinfo',@() srp('getinfo',s), 'getnext',@() srp('getnext',s), ...
    'next',@() srp('next',s), 'seek',@(f) srp('seek',s,f), ...
    'step',@(d) srp('step',s,d));
  
elseif( strcmp(mode,'w') )
  s = swp( 'open', int32(-1), fName, info );
  sobj = struct( 'close',@() swp('close',s), ...
    'addframe',@(varargin) swp('addframe',s,varargin{:}), ...
    'addframeb',@(varargin) swp('addframeb',s,varargin{:}) );
  
elseif( strcmp(mode,'rdual') )
  sobj = seqReaderDual(fName{:});
  
else assert(0);
  
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
