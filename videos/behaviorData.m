function A = behaviorData( action, fName, nFrame1 )
% Retrieve and manipulate behavior annotation of a video.
%
% Overview: A behavior annotation assigns every frame of a video to one of
% k behaviors. Each consecutive set of frames is a single behavior
% instance, the video is divided into n such behavior instances each with
% its own type. Such a delineation is considered a single stream. To allow
% labeling of overlapping behaviors or simultaneous labeling of behaviors
% for multiple subjects, multiple streams can be used.
%
% Construction: Calling behaviorData(action,fName,nFrame) creates or loads
% an object A that is used to represent a behavior annotation. The 'action'
% flag controls whether to 'load' a previously saved annotation or to
% 'create' a new annotation. If constructing a new annotation, two
% parameters control the annotation created: a configuration file (fName)
% with the number of streams to use and the behavior list (see below) and
% the number of frames in the video (nFrame). If loading a new annotation,
% fName should point to the name of a previously saved annotation (with
% either a .bAnn or .txt extension), nFrame is not needed. The .txt format
% may be preferred as it is human readable (although slightly larger file
% sizes may result). After creation, A is manipulated using object oriented
% syntax, for example A.nFrame() returns the number of frames of the
% underlying video (more details below).
%
% Config file: should be a text file listing possible behavior types along
% with a single character for each that will serve as a shortcut key. The
% first line should be "nStream [val]" where [val] is the number of
% annotation streams. Each following line should be the behavior name
% followed by a character representing the key. Additionally, the first
% behavior serves as the default behavior initially assigned to the entire
% video, and should be named accordingly. Below is an example config file:
%   nStream 2
%   other o
%   eating e
%   grooming g
%   drinking d
%   sleeping s
%
% Representation: An annotation of a single stream can be represented as
% n+1 boundaries (bnds) delineating the starts of each behavior, with the
% last bnd being the number of frames, and n integer types representing the
% type of each behavior. For example, bnds=[0 100 nFrame] and types=[1 2]
% would indicate frames 0-99 have type 1 and 100-(nFrame-1) have type 2.
% Each type must have value in 1 to k, and the associated behavior name of
% each type can be retrieved from a string cell array containing the k
% names. Note that consecutive behaviors of the same type are merged.
%
% Save, recreate, merge:
%  save(fName)        - save to file (.bAnn or .txt)
%  recreate(cName)    - specify new configuration file
%  merge(fName)       - load second annotation, merge streams
%
% Inspect (always inspect current stream):
%  n1 = n()           - number of behavior instances
%  k1 = k()           - number of behavior types
%  nFrame1 = nFrame() - number of frames in underlying video
%  nStrm1 = nStrm()   - number of annotation streams
%  types = getTypes() - length n vector of integer types
%  bnds = getBnds()   - length n+1 vector of frame boundaries
%  names = getNames() - length k cell vector of behavior names
%  keys = getKeys()   - length k char vector of key shortcuts
%  type = getType(id) - type of behavior for id-th instance
%  name = getName(id) - name of behavior for id-th instance
%  frm = getStart(id) - start frame for id-th instance
%  frm = getEnd(id)   - end frame for id-th instance
%  id = getId(frm)    - id of behavior at given frame (1<=id<=n)
%  ids = getIds(type) - all ids for behavior of given type
%  lbl = getLbls()    - get per frame labeling - [1 x nFrame]
%
% Alter (always alter current stream):
%  setStrm(strm)      - set current stream
%  setType(id,type)   - change type of given behavior
%  move(id,frame)     - move behavior start (must remain between prev/next)
%  add(type, frame)   - add behavior with start at given frame
%  delete(id)         - delete behavior by extending prev behavior
%  crop(fr0,fr1)      - crop annotation to given range
%  insert(frs)        - extend annotation by inserting frames
%  setLbls(lbl)       - set per frame labeling - [1 x nFrame]
%
% USAGE
%  A = behaviorData( action, fName, nFrame )
%
% INPUTS
%  action   - 'load' or 'create'
%  fName    - location of annotation or config file
%  nFrame   - number of frames if creating video
%
% OUTPUTS
%  A        - annotation structure
%
% EXAMPLE
%
% See also behaviorAnnotator
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.60
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% fields for storing annotation
[bnds,types,names,keys,s]=deal([]);

% load or initialize
assert(nargin>=2); if(nargin<3), nFrame1=[]; end
switch action
  case 'load', load1(fName,nFrame1);
  case 'create', create(fName,nFrame1);
end

% create API
A = struct( 'save',@save1,'recreate',@recreate, ...
  'merge',@merge, 'n',@n, 'k',@k, 'nFrame',@nFrame, 'nStrm',@nStrm, ...
  'getTypes',@getTypes, 'getBnds',@getBnds, 'getNames',@getNames, ...
  'getKeys',@getKeys, 'getType',@getType, 'getName',@getName, ...
  'getStart',@getStart, 'getEnd',@getEnd, 'getId',@getId, ...
  'getIds',@getIds, 'getLbls',@getLbls, 'setStrm',@setStrm, ...
  'setType',@setType, 'move',@move, 'add',@add, 'delete',@delete, ...
  'crop',@crop, 'insert',@insert, 'setLbls',@setLbls );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function save1( fName )
    [d,f,ext] = fileparts(fName);
    if(strcmp(ext,'.txt')), saveTxt(fName); return; end
    vers=.5; if(isempty(d)), d='.'; end; f=[d '/' f '.bAnn']; %#ok<NASGU>
    save('-v6',f,'bnds','types','names','keys','vers');
  end

  function load1( fName, cName )
    [d,f,ext] = fileparts(fName); if(nargin<2), cName=[]; end
    if(strcmp(ext,'.txt')), loadTxt(fName,cName); return; end
    vers=.5; if(isempty(d)), d='.'; end; f=[d '/' f '.bAnn'];
    L=load( '-mat', f );
    % backward compatibilty w vers=.4
    if(isfield(L,'vers') && L.vers==.4)
      L.bnds=L.bndss; L.types=L.typess; L.vers=.5;
    end
    % check if valid annotation file / correct version
    if( ~isfield(L,'vers') || L.vers~=vers || ~isfield(L,'bnds') );
      error('Not a valid video annotation file or incorrect version.');
    end;
    % retrieve variables
    bnds=L.bnds; types=L.types; names=L.names; keys=L.keys; s=1;
  end

  function merge( fName )
    % store current annotation data
    bs0=bnds; ts0=types; ns0=names; ks0=keys; s0=s; k0=k; nFr0=nFrame;
    % append new anntation
    load1(fName); bnds=[bs0 bnds]; types=[ts0 types]; s=s0;
    % confirm configs are same
    if( nFr0~=nFrame ), error('Mismatched frame length.'); end
    if( k~=k0 || ~strcmp(keys,ks0) || ~all(strcmp(names,ns0)) )
      error(['Mismatched config files: ' fName]);
    end
  end

  function saveTxt( fName )
    % begin exporting
    f=fopen(fName,'wt'); fp=@(varargin) fprintf(f,varargin{:});
    fp('Caltech Behavior Annotator - Annotation File\n\n');
    % output configuration info
    fp('Configuration file:\n');
    for i=1:k, fp('%s %s\n',names{i},keys(i)); end
    % behavior output
    s0=s; str='%8i  %6i    %s\n';
    for s1=1:nStrm, s=s1;
      fp('\nS%i: start    end     type\n',s1);
      fp('-----------------------------\n');
      for i=1:n, fp(str,getStart(i)+1,getEnd(i)+1,getName(i)); end
    end
    s=s0; fclose(f);
  end

  function loadTxt( fName, cName )
    % load annotation from text file created by saveTxt()
    try
      header='Caltech Behavior Annotator - Annotation File';
      f=fopen(fName,'rt'); s=fgetl(f); header=strcmp(s,header);
      if(header==0), fseek(f,0,'bof'); assert(~isempty(cName)); end
      if( header )
        % read in rest of header and config file
        s=fgetl(f); assert(isempty(s));
        s=fgetl(f); assert(strcmp(s,'Configuration file:'));
        names=cell(1,1000); keys=char(zeros(1,1000)); k=0;
        while(1), s=fgetl(f); if(~ischar(s) || isempty(s)), break; end
          t=textscan(s,'%s %1c',1); k=k+1; names{k}=t{1}{1}; keys(k)=t{2};
        end
        names=names(1:k); keys=keys(1:k);
      end
      % use names/keys from externally specified config file
      if(~isempty(cName)), create(cName,1); end
      % read in each stream in turn until end of file
      bnds0=cell(1,10000); types0=cell(1,10000); nStrm1=0; s=fgetl(f);
      while( 1 ), nStrm1=nStrm1+1;
        t=textscan(s,'S%d: start    end     type\n'); assert(t{1}==nStrm1);
        s=fgetl(f); assert(strcmp(s,'-----------------------------'));
        bnds1=zeros(1,10000); types1=zeros(1,10000); k=1;
        while(1), s=fgetl(f); if(~ischar(s) || all(isspace(s))), break; end
          t=textscan(s,'%d %d %s',1); k=k+1; type=find(strcmp(t{3},names));
          if(isempty(type)), error('undefined behavior %s',t{3}{1}); end
          if(bnds1(k-1)~=t{1}-1), error('%i~=%i',bnds1(k-1),t{1}-1); end
          bnds1(k)=t{2}; types1(k)=type;
        end
        if(nStrm1==1), nFrame1=bnds1(k); end; assert(nFrame1==bnds1(k));
        bnds0{nStrm1}=bnds1(1:k); types0{nStrm1}=types1(2:k);
        while(all(isspace(s))), s=fgetl(f); end; if(s==-1), break; end
      end
      % create annotation
      create( nFrame1, nStrm1, names, keys );
      bnds=bnds0(1:nStrm); types=types0(1:nStrm);
      for s1=nStrm1:-1:1, setStrm(s1); condense(); end; fclose(f);
    catch e, fclose(f); throw(e);
    end
  end

  function create( varargin )
    % create new annotation (load or use passed in config)
    if( nargin==2 )
      [cName,nFrame1]=deal(varargin{:});
      f=fopen(cName,'rt'); t1=textscan(f,'nStream %d');
      t2=textscan(f,'%s %1c'); fclose(f);
      nStrm1=t1{1}; names=t2{1}; keys=t2{2};
    elseif( nargin==4 )
      [nFrame1,nStrm1,names,keys]=deal(varargin{:});
    else assert(false);
    end
    % error check configuration
    k1=length(keys); m=[];
    if(length(names)~=k1), m='Name/key mismatch.'; end
    if(~all(keys+0>=48)), m='Bad key bindings.'; end
    if(length(unique(keys))~=k1), m='Multiply defined keys.'; end
    if(length(unique(names))~=k1), m='Multiply defined names.'; end
    if(~isempty(m)), error(['Invalid config file (' cName '): ' m]); end
    % initialize data structure
    bnds=cell(1,nStrm1); types=cell(1,nStrm1); s=1;
    for s1=1:nStrm1, bnds{s1}=[0 nFrame1]; end
    for s1=1:nStrm1, types{s1}=1; end
  end

  function recreate( cName )
    % store current annotation data (except keys and s)
    bs0=bnds; ts0=types; ns0=names; k0=k(); nStrm0=nStrm();
    % create brand new annotation data, copy over old
    create(cName,nFrame()); mins=min(nStrm0,nStrm());
    bnds(1:mins)=bs0(1:mins); types(1:mins)=ts0(1:mins);
    % remap types to match new names list (deleted names default to type 1)
    map=ones(1,k0);
    for i=1:k0, m=find(strcmp(ns0{i},names)); if(m), map(i)=m; end; end
    for i=1:mins, s=i; types{s}=map(types{s}); condense(); end; s=1;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function n1 = n(), n1=length(types{s}); end

  function k1 = k(), k1=length(names); end

  function nFrame1 = nFrame(), nFrame1=bnds{s}(n+1); end

  function nStrm1 = nStrm(), nStrm1=length(bnds); end

  function types1 = getTypes(), types1=types{s}; end

  function bnds1 = getBnds(), bnds1=bnds{s}; end

  function names1 = getNames(), names1=names; end

  function keys1 = getKeys(), keys1=keys; end

  function type = getType( id ), type=types{s}(id); end

  function name = getName( id ), name=names{getType(id)}; end

  function frame = getStart( id ), frame=bnds{s}(id); end

  function frame = getEnd( id ), frame=bnds{s}(id+1)-1; end

  function id = getId( frame ), [~,id]=min(bnds{s}<=frame); id=id-1; end

  function ids = getIds( type ), ids=find(types{s}==type); end

  function lbl = getLbls()
    lbl=zeros(1,nFrame);
    for i=1:n, lbl(bnds{s}(i)+1:bnds{s}(i+1))=types{s}(i); end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function setStrm( s1 ), assert(s1>0 && s1<=nStrm); s=s1; end

  function setType( id, type )
    assert(type>0 && type<=k);
    types{s}(id)=type; condense();
  end

  function move( id, frame )
    assert(id>=1 && id<=n); if(id==1), return; end
    assert(frame>bnds{s}(id-1) && frame<bnds{s}(id+1));
    bnds{s}(id)=frame;
  end

  function add( type, frame )
    id=getId(frame);
    if(frame==bnds{s}(id)), setType(id,type); else
      bnds{s} = [bnds{s}(1:id) frame bnds{s}(id+1:end)];
      types{s} = [types{s}(1:id) type types{s}(id+1:end)];
      condense();
    end
  end

  function delete( id )
    assert(all(id>=1 & id<=n)); if(n==1), return; end
    kp = setdiff(1:n,id); assert(~isempty(kp));
    bnds{s} = bnds{s}([kp n+1]); bnds{s}(1)=0;
    types{s} = types{s}(kp); condense();
  end

  function crop( fr0, fr1 )
    assert(fr0>=0 && fr1<nFrame()); sOrig=s;
    for s1=1:nStrm, s=s1;
      id=getId(fr0); types{s}(1:id-1)=getType(id);
      id=getId(fr1); types{s}(id+1:end)=getType(id);
      condense(); bnds{s}=bnds{s}-fr0;
      bnds{s}(1)=0; bnds{s}(end)=fr1-fr0+1;
    end; s=sOrig;
  end

  function insert( frs )
    assert(all(frs>=0 & frs<nFrame())); sOrig=s; frs0=sort(frs);
    for s1=1:nStrm, s=s1; frs=frs0;
      for f=1:length(frs)
        id=getId(frs(f)); frs=frs+1;
        bnds{s}(id+1:end)=bnds{s}(id+1:end)+1;
      end
    end; s=sOrig;
  end

  function setLbls( lbl )
    assert(min(lbl)>=1 && max(lbl)<=k() && length(lbl)==nFrame);
    ids=find(lbl(1:end-1)~=lbl(2:end));
    bnds{s}=[0 ids nFrame]; types{s}=lbl([0 ids]+1);
  end

  function condense()
    % internal cleanup: merge consecutive behaviors of same type
    ids = find(types{s}(1:end-1)==types{s}(2:end));
    if(~isempty(ids)), delete(ids+1); end
  end

end
