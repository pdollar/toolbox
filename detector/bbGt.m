function varargout = bbGt( action, varargin )
% Bounding box (bb) annotations struct, evaluation and sampling routines.
%
% bbGt gives access to two types of routines:
% (1) Data structure for storing bb image annotations.
% (2) Routines for evaluating the Pascal criteria for object detection.
%
% The bb annotation stores bb for objects of interest with additional
% information per object, such as occlusion information. The underlying
% data structure is simply a Matlab stuct array, one struct per object.
% This annotation format is an alternative to the annotation format used
% for the PASCAL object challenges (in addition routines for loading PASCAL
% format data are provided, see bbLoad()).
%
% Each object struct has the following fields:
%  lbl  - a string label describing object type (eg: 'pedestrian')
%  bb   - [l t w h]: bb indicating predicted object extent
%  occ  - 0/1 value indicating if bb is occluded
%  bbv  - [l t w h]: bb indicating visible region (may be [0 0 0 0])
%  ign  - 0/1 value indicating bb was marked as ignore
%  ang  - [0-360] orientation of bb in degrees
%
% Note: although orientation (angle) is stored for each bb, for now it is
% not being used during evaluation or sampling.
%
% bbGt contains a number of utility functions, accessed using:
%  outputs = bbGt( 'action', inputs );
% The list of functions and help for each is given below. Also, help on
% individual subfunctions can be accessed by: "help bbGt>action".
%
%%% (1) Data structure for storing bb image annotations.
% Create annotation of n empty objects.
%   objs = bbGt( 'create', [n] );
% Save bb annotation to text file.
%   objs = bbGt( 'bbSave', objs, fName )
% Load bb annotation from text file and filter.
%   [objs,bbs] = bbGt( 'bbLoad', fName, [pLoad] )
% Get object property 'name' (in a standard array).
%   vals = bbGt( 'get', objs, name )
% Set object property 'name' (with a standard array).
%   objs = bbGt( 'set', objs, name, vals )
% Draw an ellipse for each labeled object.
%   hs = draw( objs, pDraw )
%
%%% (2) Routines for evaluating the Pascal criteria for object detection.
% Get all corresponding files in given directories.
%   [fs,fs0] = bbGt('getFiles', dirs, [f0], [f1] )
% Copy corresponding files into given directories.
%   fs = bbGt( 'copyFiles', fs, dirs )
% Load all ground truth and detection bbs in given directories.
%   [gt0,dt0] = bbGt( 'loadAll', gtDir, [dtDir], [pLoad] )
% Evaluates detections against ground truth data.
%   [gt,dt] = bbGt( 'evalRes', gt0, dt0, [thr], [mul] )
% Display evaluation results for given image.
%   [hs,hImg] = bbGt( 'showRes' I, gt, dt, varargin )
% Compute ROC or PR based on outputs of evalRes on multiple images.
%   [xs,ys,ref] = bbGt( 'compRoc', gt, dt, roc, ref )
% Extract true or false positives or negatives for visualization.
%   [Is,scores,imgIds] = bbGt( 'cropRes', gt, dt, imFs, varargin )
% Computes (modified) overlap area between pairs of bbs.
%   oa = bbGt( 'compOas', dt, gt, [ig] )
% Optimized version of compOas for a single pair of bbs.
%   oa = bbGt( 'compOa', dt, gt, ig )
%
% USAGE
%  varargout = bbGt( action, varargin );
%
% INPUTS
%  action     - string specifying action
%  varargin   - depends on action, see above
%
% OUTPUTS
%  varargout  - depends on action, see above
%
% EXAMPLE
%
% See also bbApply, bbLabeler, bbGt>create, bbGt>bbSave, bbGt>bbLoad,
% bbGt>get, bbGt>set, bbGt>draw, bbGt>getFiles, bbGt>copyFiles,
% bbGt>loadAll, bbGt>evalRes, bbGt>showRes,  bbGt>compRoc, bbGt>cropRes,
% bbGt>compOas, bbGt>compOa
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.26
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

%#ok<*DEFNU>
varargout = cell(1,max(1,nargout));
[varargout{:}] = feval(action,varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function objs = create( n )
% Create annotation of n empty objects.
%
% USAGE
%  objs = bbGt( 'create', [n] )
%
% INPUTS
%  n      - [1] number of objects to create
%
% OUTPUTS
%  objs   - annotation of n 'empty' objects
%
% EXAMPLE
%  objs = bbGt('create')
%
% See also bbGt
o=struct('lbl','','bb',[0 0 0 0],'occ',0,'bbv',[0 0 0 0],'ign',0,'ang',0);
if(nargin<1 || n==1), objs=o; return; end; objs=o(ones(n,1));
end

function objs = bbSave( objs, fName )
% Save bb annotation to text file.
%
% USAGE
%  objs = bbGt( 'bbSave', objs, fName )
%
% INPUTS
%  objs   - objects to save
%  fName  - name of text file
%
% OUTPUTS
%  objs   - objects to save
%
% EXAMPLE
%
% See also bbGt, bbGt>bbLoad
vers=3; fid=fopen(fName,'w'); assert(fid>0);
fprintf(fid,'%% bbGt version=%i\n',vers);
objs=set(objs,'bb',round(get(objs,'bb')));
objs=set(objs,'bbv',round(get(objs,'bbv')));
objs=set(objs,'ang',round(get(objs,'ang')));
for i=1:length(objs)
  o=objs(i); bb=o.bb; bbv=o.bbv;
  fprintf(fid,['%s' repmat(' %i',1,11) '\n'],o.lbl,...
    bb,o.occ,bbv,o.ign,o.ang);
end
fclose(fid);
end

function [objs,bbs] = bbLoad( fName, varargin )
% Load bb annotation from text file and filter.
%
% FORMAT: Specify 'format' to indicate the format of the ground truth.
% format=0 is the default format (created by bbSave/bbLabeler). format=1 is
% the PASCAL VOC format. Loading ground truth in this format requires
% 'VOCcode/' to be in directory path. It's part of VOCdevkit available from
% the PASCAL VOC: http://pascallin.ecs.soton.ac.uk/challenges/VOC/. Objects
% labeled as either 'truncated' or 'occluded' using the PASCAL definitions
% have the 'occ' flag set to true. Objects labeled as 'difficult' have the
% 'ign' flag set to true. 'class' is used for 'lbl'. format=2 is the
% ImageNet detection format and requires the ImageNet Dev Kit.
%
% FILTERING: After loading, the objects can be filtered. First, only
% objects with lbl in lbls or ilbls or returned. For each object, obj.ign
% is set to 1 if it was already at 1, if its label was in ilbls, or if any
% object property is outside of the specified range. The ignore flag is
% used during training and testing so that objects with certain properties
% (such as very small or heavily occluded objects) are excluded. The range
% for each property is a two element vector, [0 inf] by default; a property
% value v is inside the range if v>=rng(1) && v<=rng(2). Tested properties
% include height (h), width (w), area (a), aspect ratio (ar), orientation
% (o), extent x-coordinate (x), extent y-coordinate (y), and fraction
% visible (v). The last property is computed as the visible object area
% divided by the total area, except if o.occ==0, in which case v=1, or
% all(o.bbv==o.bb), which indicates the object may be barely visible, in
% which case v=0 (note that v~=1 in this case).
%
% RETURN: In addition to outputting the objs, bbLoad() can return the
% corresponding bounding boxes (bbs) in an [nx5] array where each row is of
% the form [x y w h ignore], [x y w h] is the bb and ignore=obj.ign. For
% oriented bbs, the extent of the bb is returned, where the extent is the
% smallest axis aligned bb containing the oriented bb. If the oriented bb
% was labeled as a rectangle as opposed to an ellipse, the tightest bb will
% usually increase slightly in size due to the corners of the rectangle
% sticking out beyond the ellipse bounds. The 'ellipse' flag controls how
% an oriented bb is converted to a regular bb. Specifically, set ellipse=1
% if an ellipse tightly delineates the object and 0 if a rectangle does.
% Finally, if 'squarify' is not empty the (non-ignore) bbs are converted to
% a fixed aspect ratio using bbs=bbApply('squarify',bbs,squarify{:}).
%
% USAGE
%  [objs,bbs] = bbGt( 'bbLoad', fName, [pLoad] )
%
% INPUTS
%  fName    - name of text file
%  pLoad    - parameters (struct or name/value pairs)
%   .format   - [0] gt format 0:default, 1:PASCAL, 2:ImageNet
%   .ellipse  - [1] controls how oriented bb is converted to regular bb
%   .squarify - [] controls optional reshaping of bbs to fixed aspect ratio
%   .lbls     - [] return objs with these labels (or [] to return all)
%   .ilbls    - [] return objs with these labels but set to ignore
%   .hRng     - [] range of acceptable obj heights
%   .wRng     - [] range of acceptable obj widths
%   .aRng     - [] range of acceptable obj areas
%   .arRng    - [] range of acceptable obj aspect ratios
%   .oRng     - [] range of acceptable obj orientations (angles)
%   .xRng     - [] range of x coordinates of bb extent
%   .yRng     - [] range of y coordinates of bb extent
%   .vRng     - [] range of acceptable obj occlusion levels
%
% OUTPUTS
%  objs     - loaded objects
%  bbs      - [nx5] array containg ground truth bbs [x y w h ignore]
%
% EXAMPLE
%
% See also bbGt, bbGt>bbSave

% get parameters
df={'format',0,'ellipse',1,'squarify',[],'lbls',[],'ilbls',[],'hRng',[],...
  'wRng',[],'aRng',[],'arRng',[],'oRng',[],'xRng',[],'yRng',[],'vRng',[]};
[format,ellipse,sqr,lbls,ilbls,hRng,wRng,aRng,arRng,oRng,xRng,yRng,vRng]...
  = getPrmDflt(varargin,df,1);

% load objs
if( format==0 )
  % load objs stored in default format
  fId=fopen(fName);
  if(fId==-1), error(['unable to open file: ' fName]); end; v=0;
  try v=textscan(fId,'%% bbGt version=%d'); v=v{1}; catch, end %#ok<CTCH>
  if(isempty(v)), v=0; end
  % read in annotation (m is number of fields for given version v)
  if(all(v~=[0 1 2 3])), error('Unknown version %i.',v); end
  frmt='%s %d %d %d %d %d %d %d %d %d %d %d';
  ms=[10 10 11 12]; m=ms(v+1); frmt=frmt(1:2+(m-1)*3);
  in=textscan(fId,frmt); for i=2:m, in{i}=double(in{i}); end; fclose(fId);
  % create objs struct from read in fields
  n=length(in{1}); objs=create(n);
  for i=1:n, objs(i).lbl=in{1}{i}; objs(i).occ=in{6}(i); end
  bb=[in{2} in{3} in{4} in{5}]; bbv=[in{7} in{8} in{9} in{10}];
  for i=1:n, objs(i).bb=bb(i,:); objs(i).bbv=bbv(i,:); end
  if(m>=11), for i=1:n, objs(i).ign=in{11}(i); end; end
  if(m>=12), for i=1:n, objs(i).ang=in{12}(i); end; end
elseif( format==1 )
  % load objs stored in PASCAL VOC format
  if(exist('PASreadrecord.m','file')~=2)
    error('bbLoad() requires the PASCAL VOC code.'); end
  os=PASreadrecord(fName); os=os.objects;
  n=length(os); objs=create(n);
  if(~isfield(os,'occluded')), for i=1:n, os(i).occluded=0; end; end
  for i=1:n
    bb=os(i).bbox; bb(3)=bb(3)-bb(1); bb(4)=bb(4)-bb(2); objs(i).bb=bb;
    objs(i).lbl=os(i).class; objs(i).ign=os(i).difficult;
    objs(i).occ=os(i).occluded || os(i).truncated;
    if(objs(i).occ), objs(i).bbv=bb; end
  end
elseif( format==2 )
  if(exist('VOCreadxml.m','file')~=2)
    error('bbLoad() requires the ImageNet dev code.'); end
  os=VOCreadxml(fName); os=os.annotation;
  if(isfield(os,'object')), os=os.object; else os=[]; end
  n=length(os); objs=create(n);
  for i=1:n
    bb=os(i).bndbox; bb=str2double({bb.xmin bb.ymin bb.xmax bb.ymax});
    bb(3)=bb(3)-bb(1); bb(4)=bb(4)-bb(2); objs(i).bb=bb;
    objs(i).lbl=os(i).name;
  end
else error('bbLoad() unknown format: %i',format);
end

% only keep objects whose lbl is in lbls or ilbls
if(~isempty(lbls) || ~isempty(ilbls)), K=true(n,1);
  for i=1:n, K(i)=any(strcmp(objs(i).lbl,[lbls ilbls])); end
  objs=objs(K); n=length(objs);
end

% filter objs (set ignore flags)
for i=1:n, objs(i).ang=mod(objs(i).ang,360); end
if(~isempty(ilbls)), for i=1:n, v=objs(i).lbl;
    objs(i).ign = objs(i).ign || any(strcmp(v,ilbls)); end; end
if(~isempty(xRng)),  for i=1:n, v=objs(i).bb(1);
    objs(i).ign = objs(i).ign || v<xRng(1) || v>xRng(2); end; end
if(~isempty(xRng)),  for i=1:n, v=objs(i).bb(1)+objs(i).bb(3);
    objs(i).ign = objs(i).ign || v<xRng(1) || v>xRng(2); end; end
if(~isempty(yRng)),  for i=1:n, v=objs(i).bb(2);
    objs(i).ign = objs(i).ign || v<yRng(1) || v>yRng(2); end; end
if(~isempty(yRng)),  for i=1:n, v=objs(i).bb(2)+objs(i).bb(4);
    objs(i).ign = objs(i).ign || v<yRng(1) || v>yRng(2); end; end
if(~isempty(wRng)),  for i=1:n, v=objs(i).bb(3);
    objs(i).ign = objs(i).ign || v<wRng(1) || v>wRng(2); end; end
if(~isempty(hRng)),  for i=1:n, v=objs(i).bb(4);
    objs(i).ign = objs(i).ign || v<hRng(1) || v>hRng(2); end; end
if(~isempty(oRng)),  for i=1:n, v=objs(i).ang; if(v>180), v=v-360; end
    objs(i).ign = objs(i).ign || v<oRng(1) || v>oRng(2); end; end
if(~isempty(aRng)),  for i=1:n, v=objs(i).bb(3)*objs(i).bb(4);
    objs(i).ign = objs(i).ign || v<aRng(1) || v>aRng(2); end; end
if(~isempty(arRng)), for i=1:n, v=objs(i).bb(3)/objs(i).bb(4);
    objs(i).ign = objs(i).ign || v<arRng(1) || v>arRng(2); end; end
if(~isempty(vRng)),  for i=1:n, o=objs(i); bb=o.bb; bbv=o.bbv; %#ok<ALIGN>
    if(~o.occ || all(bbv==0)), v=1; elseif(all(bbv==bb)), v=0; else
      v=(bbv(3)*bbv(4))/(bb(3)*bb(4)); end
    objs(i).ign = objs(i).ign || v<vRng(1) || v>vRng(2); end
end

% finally get extent of each bounding box (not trivial if ang~=0)
if(nargout<=1), return; end; if(n==0), bbs=zeros(0,5); return; end
bbs=double([reshape([objs.bb],4,[]); [objs.ign]]'); ign=bbs(:,5)==1;
for i=1:n, bbs(i,1:4)=bbExtent(bbs(i,1:4),objs(i).ang,ellipse); end
if(~isempty(sqr)), bbs(~ign,:)=bbApply('squarify',bbs(~ign,:),sqr{:}); end

  function bb = bbExtent( bb, ang, ellipse )
    % get bb that fully contains given oriented bb
    if(~ang), return; end
    if( ellipse ) % get bb that encompases ellipse (tighter)
      x=bbApply('getCenter',bb); a=bb(4)/2; b=bb(3)/2; ang=ang-90;
      rx=(a*cosd(ang))^2+(b*sind(ang))^2; rx=abs(rx/sqrt(rx));
      ry=(a*sind(ang))^2+(b*cosd(ang))^2; ry=abs(ry/sqrt(ry));
      bb=[x(1)-rx x(2)-ry 2*rx 2*ry];
    else % get bb that encompases rectangle (looser)
      c=cosd(ang); s=sind(ang); R=[c -s; s c]; rs=bb(3:4)/2;
      x0=-rs(1); x1=rs(1); y0=-rs(2); y1=rs(2); pc=bb(1:2)+rs;
      p=[x0 y0; x1 y0; x1 y1; x0 y1]*R'+pc(ones(4,1),:);
      x0=min(p(:,1)); x1=max(p(:,1)); y0=min(p(:,2)); y1=max(p(:,2));
      bb=[x0 y0 x1-x0 y1-y0];
    end
  end
end

function vals = get( objs, name )
% Get object property 'name' (in a standard array).
%
% USAGE
%  vals = bbGt( 'get', objs, name )
%
% INPUTS
%  objs   - [nx1] struct array of objects
%  name   - property name ('lbl','bb','occ',etc.)
%
% OUTPUTS
%  vals   - [nxk] array of n values (k=1 or 4)
%
% EXAMPLE
%
% See also bbGt, bbGt>set
nObj=length(objs); if(nObj==0), vals=[]; return; end
switch name
  case 'lbl', vals={objs.lbl}';
  case 'bb',  vals=reshape([objs.bb]',4,[])';
  case 'occ', vals=[objs.occ]';
  case 'bbv', vals=reshape([objs.bbv]',4,[])';
  case 'ign', vals=[objs.ign]';
  case 'ang', vals=[objs.ang]';
  otherwise, error('unkown type %s',name);
end
end

function objs = set( objs, name, vals )
% Set object property 'name' (with a standard array).
%
% USAGE
%  objs = bbGt( 'set', objs, name, vals )
%
% INPUTS
%  objs   - [nx1] struct array of objects
%  name   - property name ('lbl','bb','occ',etc.)
%  vals   - [nxk] array of n values (k=1 or 4)
%
% OUTPUTS
%  objs   - [nx1] struct array of updated objects
%
% EXAMPLE
%
% See also bbGt, bbGt>get
nObj=length(objs);
switch name
  case 'lbl', for i=1:nObj, objs(i).lbl=vals{i}; end
  case 'bb',  for i=1:nObj, objs(i).bb=vals(i,:); end
  case 'occ', for i=1:nObj, objs(i).occ=vals(i); end
  case 'bbv', for i=1:nObj, objs(i).bbv=vals(i,:); end
  case 'ign', for i=1:nObj, objs(i).ign=vals(i); end
  case 'ang', for i=1:nObj, objs(i).ang=vals(i); end
  otherwise, error('unkown type %s',name);
end
end

function hs = draw( objs, varargin )
% Draw an ellipse for each labeled object.
%
% USAGE
%  hs = bbGt( 'draw', objs, pDraw )
%
% INPUTS
%  objs       - [nx1] struct array of objects
%  pDraw      - parameters (struct or name/value pairs)
%   .col        - ['g'] color or [nx1] array of colors
%   .lw         - [2] line width
%   .ls         - ['-'] line style
%
% OUTPUTS
%  hs     - [nx1] handles to drawn graphic objects
%
% EXAMPLE
%
% See also bbGt
dfs={'col',[],'lw',2,'ls','-'};
[col,lw,ls]=getPrmDflt(varargin,dfs,1);
n=length(objs); hold on; hs=zeros(n,4);
if(isempty(col)), if(n==1), col='g'; else col=hsv(n); end; end
tProp={'FontSize',10,'color','w','FontWeight','bold',...
  'VerticalAlignment','bottom'};
for i=1:n
  bb=objs(i).bb; ci=col(i,:);
  hs(i,1)=text(bb(1),bb(2),objs(i).lbl,tProp{:});
  x=bbApply('getCenter',bb); r=bb(3:4)/2; a=objs(i).ang/180*pi-pi/2;
  [hs(i,2),hs(i,3),hs(i,4)]=plotEllipse(x(2),x(1),r(2),r(1),a,ci,[],lw,ls);
end; hold off;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fs,fs0] = getFiles( dirs, f0, f1 )
% Get all corresponding files in given directories.
%
% The first dir in 'dirs' serves as the baseline dir. getFiles() returns
% all files in the baseline dir and all corresponding files in the
% remaining dirs to the files in the baseline dir, in the same order. Two
% files are in correspondence if they have the same base name (regardless
% of extension). For example, given a file named "name.jpg", a
% corresponding file may be named "name.txt" or "name.jpg.txt". Every file
% in the baseline dir must have a matching file in the remaining dirs.
%
% USAGE
%  [fs,fs0] = bbGt('getFiles', dirs, [f0], [f1] )
%
% INPUTS
%   dirs      - {1xm} list of m directories
%   f0        - [1] index of first file in baseline dir to use
%   f1        - [inf] index of last file in baseline dir to use
%
% OUTPUTS
%   fs        - {mxn} list of full file names in each dir
%   fs0       - {1xn} list of file names without path or extensions
%
% EXAMPLE
%
% See also bbGt

if(nargin<2 || isempty(f0)), f0=1; end
if(nargin<3 || isempty(f1)), f1=inf; end
m=length(dirs); assert(m>0); sep=filesep;

for d=1:m, dir1=dirs{d}; dir1(dir1=='\')=sep; dir1(dir1=='/')=sep;
  if(dir1(end)==sep), dir1(end)=[]; end; dirs{d}=dir1; end

[fs0,fs1] = getFiles0(dirs{1},f0,f1,sep);
n1=length(fs0); fs=cell(m,n1); fs(1,:)=fs1;
for d=2:m, fs(d,:)=getFiles1(dirs{d},fs0,sep); end

  function [fs0,fs1] = getFiles0( dir1, f0, f1, sep )
    % get fs1 in dir1 (and fs0 without path or extension)
    fs1=dir([dir1 sep '*']); fs1={fs1.name}; fs1=fs1(3:end);
    fs1=fs1(f0:min(f1,end)); fs0=fs1; n=length(fs0);
    if(n==0), error('No files found in baseline dir %s.',dir1); end
    for i=1:n, fs1{i}=[dir1 sep fs0{i}]; end
    n=length(fs0); for i=1:n, f=fs0{i};
      f(find(f=='.',1,'first'):end)=[]; fs0{i}=f; end
  end

  function fs1 = getFiles1( dir1, fs0, sep )
    % get fs1 in dir1 corresponding to fs0
    n=length(fs0); fs1=cell(1,n); i2=0; i1=0;
    fs2=dir(dir1); fs2={fs2.name}; n2=length(fs2);
    eMsg='''%s'' has no corresponding file in %s.';
    for i0=1:n, r=length(fs0{i0}); match=0;
      while(i2<n2), i2=i2+1; if(strcmpi(fs0{i0},fs2{i2}(1:min(end,r))))
          i1=i1+1; fs1{i1}=fs2{i2}; match=1; break; end; end
      if(~match), error(eMsg,fs0{i0},dir1); end
    end
    for i1=1:n, fs1{i1}=[dir1 sep fs1{i1}]; end
  end
end

function fs = copyFiles( fs, dirs )
% Copy corresponding files into given directories.
%
% Useful for splitting data into training, validation and testing sets.
% See also bbGt>getFiles for obtaining a set of corresponding files.
%
% USAGE
%  fs = bbGt( 'copyFiles', fs, dirs )
%
% INPUTS
%   fs        - {mxn} list of full file names in each dir
%   dirs      - {1xm} list of m target directories
%
% OUTPUTS
%   fs        - {mxn} list of full file names of copied files
%
% EXAMPLE
%
% See also bbGt, bbGt>getFiles
[m,n]=size(fs); assert(numel(dirs)==m); if(n==0), return; end
for d=1:m
  if(~exist(dirs{d},'dir')), mkdir(dirs{d}); end
  for i=1:n, f=fs{d,i}; j=[0 find(f=='/' | f=='\')]; j=j(end);
    fs{d,i}=[dirs{d} '/' f(j+1:end)]; copyfile(f,fs{d,i}); end
end
end

function [gt0,dt0] = loadAll( gtDir, dtDir, pLoad )
% Load all ground truth and detection bbs in given directories.
%
% Loads each ground truth (gt) annotation in gtDir and the corresponding
% detection (dt) in dtDir. gt and dt files must correspond according to
% getFiles(). Alternatively, dtDir may be a filename of a single text file
% that contains the detection results across all images.
%
% Each dt should be a text file where each row contains 5 numbers
% representing a bb (left/top/width/height/score). If dtDir is a text file,
% it should contain the detection results across the full set of images. In
% this case each row in the text file should have an extra leading column
% specifying the image id: (imgId/left/top/width/height/score).
%
% The output of this function can be used in bbGt>evalRes().
%
% USAGE
%  [gt0,dt0] = bbGt( 'loadAll', gtDir, [dtDir], [pLoad] )
%
% INPUTS
%  gtDir      - location of ground truth
%  dtDir      - [] optional location of detections
%  pLoad      - {} params for bbGt>bbLoad() (determine format/filtering)
%
% OUTPUTS
%  gt0        - {1xn} loaded ground truth bbs (each is a mx5 array of bbs)
%  dt0        - {1xn} loaded detections (each is a mx5 array of bbs)
%
% EXAMPLE
%
% See also bbGt, bbGt>getFiles, bbGt>evalRes

% get list of files
if(nargin<2), dtDir=[]; end
if(nargin<3), pLoad={}; end
if(isempty(dtDir)), fs=getFiles({gtDir}); gtFs=fs(1,:); else
  dtFile=length(dtDir)>4 && strcmp(dtDir(end-3:end),'.txt');
  if(dtFile), dirs={gtDir}; else dirs={gtDir,dtDir}; end
  fs=getFiles(dirs); gtFs=fs(1,:);
  if(dtFile), dtFs=dtDir; else dtFs=fs(2,:); end
end

% load ground truth
persistent keyPrv gtPrv; key={gtDir,pLoad}; n=length(gtFs);
if(isequal(key,keyPrv)), gt0=gtPrv; else gt0=cell(1,n);
  for i=1:n, [~,gt0{i}]=bbLoad(gtFs{i},pLoad); end
  gtPrv=gt0; keyPrv=key;
end

% load detections
if(isempty(dtDir) || nargout<=1), dt0=cell(0); return; end
if(iscell(dtFs)), dt0=cell(1,n);
  for i=1:n, dt1=load(dtFs{i},'-ascii');
    if(numel(dt1)==0), dt1=zeros(0,5); end; dt0{i}=dt1(:,1:5); end
else
  dt1=load(dtFs,'-ascii'); if(numel(dt1)==0), dt1=zeros(0,6); end
  ids=dt1(:,1); assert(max(ids)<=n);
  dt0=cell(1,n); for i=1:n, dt0{i}=dt1(ids==i,2:6); end
end

end

function [gt,dt] = evalRes( gt0, dt0, thr, mul )
% Evaluates detections against ground truth data.
%
% Uses modified Pascal criteria that allows for "ignore" regions. The
% Pascal criteria states that a ground truth bounding box (gtBb) and a
% detected bounding box (dtBb) match if their overlap area (oa):
%  oa(gtBb,dtBb) = area(intersect(gtBb,dtBb)) / area(union(gtBb,dtBb))
% is over a sufficient threshold (typically .5). In the modified criteria,
% the dtBb can match any subregion of a gtBb set to "ignore". Choosing
% gtBb' in gtBb that most closely matches dtBb can be done by using
% gtBb'=intersect(dtBb,gtBb). Computing oa(gtBb',dtBb) is equivalent to
%  oa'(gtBb,dtBb) = area(intersect(gtBb,dtBb)) / area(dtBb)
% For gtBb set to ignore the above formula for oa is used.
%
% Highest scoring detections are matched first. Matches to standard,
% (non-ignore) gtBb are preferred. Each dtBb and gtBb may be matched at
% most once, except for ignore-gtBb which can be matched multiple times.
% Unmatched dtBb are false-positives, unmatched gtBb are false-negatives.
% Each match between a dtBb and gtBb is a true-positive, except matches
% between dtBb and ignore-gtBb which do not affect the evaluation criteria.
%
% In addition to taking gt/dt results on a single image, evalRes() can take
% cell arrays of gt/dt bbs, in which case evaluation proceeds on each
% element. Use bbGt>loadAll() to load gt/dt for multiple images.
%
% Each gt/dt output row has a flag match that is either -1/0/1:
%  for gt: -1=ignore,  0=fn [unmatched],  1=tp [matched]
%  for dt: -1=ignore,  0=fp [unmatched],  1=tp [matched]
%
% USAGE
%  [gt, dt] = bbGt( 'evalRes', gt0, dt0, [thr], [mul] )
%
% INPUTS
%  gt0  - [mx5] ground truth array with rows [x y w h ignore]
%  dt0  - [nx5] detection results array with rows [x y w h score]
%  thr  - [.5] the threshold on oa for comparing two bbs
%  mul  - [0] if true allow multiple matches to each gt
%
% OUTPUTS
%  gt   - [mx5] ground truth results [x y w h match]
%  dt   - [nx6] detection results [x y w h score match]
%
% EXAMPLE
%
% See also bbGt, bbGt>compOas, bbGt>loadAll

% get parameters
if(nargin<3 || isempty(thr)), thr=.5; end
if(nargin<4 || isempty(mul)), mul=0; end

% if gt0 and dt0 are cell arrays run on each element in turn
if( iscell(gt0) && iscell(dt0) ), n=length(gt0);
  assert(length(dt0)==n); gt=cell(1,n); dt=gt;
  for i=1:n, [gt{i},dt{i}] = evalRes(gt0{i},dt0{i},thr,mul); end; return;
end

% check inputs
if(isempty(gt0)), gt0=zeros(0,5); end
if(isempty(dt0)), dt0=zeros(0,5); end
assert( size(dt0,2)==5 ); nd=size(dt0,1);
assert( size(gt0,2)==5 ); ng=size(gt0,1);

% sort dt highest score first, sort gt ignore last
[~,ord]=sort(dt0(:,5),'descend'); dt0=dt0(ord,:);
[~,ord]=sort(gt0(:,5),'ascend'); gt0=gt0(ord,:);
gt=gt0; gt(:,5)=-gt(:,5); dt=dt0; dt=[dt zeros(nd,1)];

% Attempt to match each (sorted) dt to each (sorted) gt
oa = compOas( dt(:,1:4), gt(:,1:4), gt(:,5)==-1 );
for d=1:nd
  bstOa=thr; bstg=0; bstm=0; % info about best match so far
  for g=1:ng
    % if this gt already matched, continue to next gt
    m=gt(g,5); if( m==1 && ~mul ), continue; end
    % if dt already matched, and on ignore gt, nothing more to do
    if( bstm~=0 && m==-1 ), break; end
    % compute overlap area, continue to next gt unless better match made
    if(oa(d,g)<bstOa), continue; end
    % match successful and best so far, store appropriately
    bstOa=oa(d,g); bstg=g; if(m==0), bstm=1; else bstm=-1; end
  end; g=bstg; m=bstm;
  % store type of match for both dt and gt
  if(m==-1), dt(d,6)=m; elseif(m==1), gt(g,5)=m; dt(d,6)=m; end
end

end

function [hs,hImg] = showRes( I, gt, dt, varargin )
% Display evaluation results for given image.
%
% USAGE
%  [hs,hImg] = bbGt( 'showRes', I, gt, dt, varargin )
%
% INPUTS
%  I          - image to display, image filename, or []
%  gt         - first output of evalRes()
%  dt         - second output of evalRes()
%  varargin   - additional parameters (struct or name/value pairs)
%   .evShow     - [1] if true show results of evaluation
%   .gtShow     - [1] if true show ground truth
%   .dtShow     - [1] if true show detections
%   .cols       - ['krg'] colors for ignore/mistake/correct
%   .gtLs       - ['-'] line style for gt bbs
%   .dtLs       - ['--'] line style for dt bbs
%   .lw         - [3] line width
%
% OUTPUTS
%  hs         - handles to bbs and text labels
%  hImg       - handle for image graphics object
%
% EXAMPLE
%
% See also bbGt, bbGt>evalRes
dfs={'evShow',1,'gtShow',1,'dtShow',1,'cols','krg',...
  'gtLs','-','dtLs','--','lw',3};
[evShow,gtShow,dtShow,cols,gtLs,dtLs,lw]=getPrmDflt(varargin,dfs,1);
% optionally display image
if(ischar(I)), I=imread(I); end
if(~isempty(I)), hImg=im(I,[],0); title(''); end
% display bbs with or w/o color coding based on output of evalRes
hold on; hs=cell(1,1000); k=0;
if( evShow )
  if(gtShow), for i=1:size(gt,1), k=k+1;
      hs{k}=bbApply('draw',gt(i,1:4),cols(gt(i,5)+2),lw,gtLs); end; end
  if(dtShow), for i=1:size(dt,1), k=k+1;
      hs{k}=bbApply('draw',dt(i,1:5),cols(dt(i,6)+2),lw,dtLs); end; end
else
  if(gtShow), k=k+1; hs{k}=bbApply('draw',gt(:,1:4),cols(3),lw,gtLs); end
  if(dtShow), k=k+1; hs{k}=bbApply('draw',dt(:,1:5),cols(3),lw,dtLs); end
end
hs=[hs{:}]; hold off;
end

function [xs,ys,score,ref] = compRoc( gt, dt, roc, ref )
% Compute ROC or PR based on outputs of evalRes on multiple images.
%
% ROC="Receiver operating characteristic"; PR="Precision Recall"
% Also computes result at reference points (ref):
%  which for ROC curves is the *detection* rate at reference *FPPI*
%  which for PR curves is the *precision* at reference *recall*
% Note, FPPI="false positive per image"
%
% USAGE
%  [xs,ys,score,ref] = bbGt( 'compRoc', gt, dt, roc, ref )
%
% INPUTS
%  gt         - {1xn} first output of evalRes() for each image
%  dt         - {1xn} second output of evalRes() for each image
%  roc        - [1] if 1 compue ROC else compute PR
%  ref        - [] reference points for ROC or PR curve
%
% OUTPUTS
%  xs         - x coords for curve: ROC->FPPI; PR->recall
%  ys         - y coords for curve: ROC->TP; PR->precision
%  score      - detection scores corresponding to each (x,y)
%  ref        - recall or precision at each reference point
%
% EXAMPLE
%
% See also bbGt, bbGt>evalRes

% get additional parameters
if(nargin<3 || isempty(roc)), roc=1; end
if(nargin<4 || isempty(ref)), ref=[]; end
% convert to single matrix, discard ignore bbs
nImg=length(gt); assert(length(dt)==nImg);
gt=cat(1,gt{:}); gt=gt(gt(:,5)~=-1,:);
dt=cat(1,dt{:}); dt=dt(dt(:,6)~=-1,:);
% compute results
if(size(dt,1)==0), xs=0; ys=0; score=0; ref=ref*0; return; end
m=length(ref); np=size(gt,1); score=dt(:,5); tp=dt(:,6);
[score,order]=sort(score,'descend'); tp=tp(order);
fp=double(tp~=1); fp=cumsum(fp); tp=cumsum(tp);
if( roc )
  xs=fp/nImg; ys=tp/np; xs1=[-inf; xs]; ys1=[0; ys];
  for i=1:m, j=find(xs1<=ref(i)); ref(i)=ys1(j(end)); end
else
  xs=tp/np; ys=tp./(fp+tp); xs1=[xs; inf]; ys1=[ys; 0];
  for i=1:m, j=find(xs1>=ref(i)); ref(i)=ys1(j(1)); end
end
end

function [Is,scores,imgIds] = cropRes( gt, dt, imFs, varargin )
% Extract true or false positives or negatives for visualization.
%
% USAGE
%  [Is,scores,imgIds] = bbGt( 'cropRes', gt, dt, imFs, varargin )
%
% INPUTS
%  gt         - {1xN} first output of evalRes() for each image
%  dt         - {1xN} second output of evalRes() for each image
%  imFs       - {1xN} name of each image
%  varargin   - additional parameters (struct or name/value pairs)
%   .dims       - ['REQ'] target dimensions for extracted windows
%   .pad        - [0] padding amount for cropping
%   .type       - ['fp'] one of: 'fp', 'fn', 'tp', 'dt'
%   .n          - [100] max number of windows to extract
%   .show       - [1] figure for displaying results (or 0)
%   .fStr       - ['%0.1f'] label{i}=num2str(score(i),fStr)
%   .embed      - [0] if true embed dt/gt bbs into cropped windows
%
% OUTPUTS
%  Is         - [dimsxn] extracted image windows
%  scores     - [1xn] detection score for each bb unless 'fn'
%  imgIds     - [1xn] image id for each cropped window
%
% EXAMPLE
%
% See also bbGt, bbGt>evalRes
dfs={'dims','REQ','pad',0,'type','fp','n',100,...
  'show',1,'fStr','%0.1f','embed',0};
[dims,pad,type,n,show,fStr,embed]=getPrmDflt(varargin,dfs,1);
N=length(imFs); assert(length(gt)==N && length(dt)==N);
% crop patches either in gt or dt according to type
switch type
  case 'fn', bbs=gt; keep=@(bbs) bbs(:,5)==0;
  case 'fp', bbs=dt; keep=@(bbs) bbs(:,6)==0;
  case 'tp', bbs=dt; keep=@(bbs) bbs(:,6)==1;
  case 'dt', bbs=dt; keep=@(bbs) bbs(:,6)>=0;
  otherwise, error('unknown type: %s',type);
end
% create ids that will map each bb to correct name
ms=zeros(1,N); for i=1:N, ms(i)=size(bbs{i},1); end; cms=[0 cumsum(ms)];
ids=zeros(1,sum(ms)); for i=1:N, ids(cms(i)+1:cms(i+1))=i; end
% flatten bbs and keep relevent subset
bbs=cat(1,bbs{:}); K=keep(bbs); bbs=bbs(K,:); ids=ids(K); n=min(n,sum(K));
% reorder bbs appropriately
if(~strcmp(type,'fn')), [~,ord]=sort(bbs(:,5),'descend'); else
  if(size(bbs,1)<n), ord=randperm(size(bbs,1)); else ord=1:n; end; end
bbs=bbs(ord(1:n),:); ids=ids(ord(1:n));
% extract patches from each image
if(n==0), Is=[]; scores=[]; imgIds=[]; return; end;
Is=cell(1,n); scores=zeros(1,n); imgIds=zeros(1,n);
if(any(pad>0)), dims1=dims.*(1+pad); rs=dims1./dims; dims=dims1; end
if(any(pad>0)), bbs=bbApply('resize',bbs,rs(1),rs(2)); end
for i=1:N
  locs=find(ids==i); if(isempty(locs)), continue; end; I=imread(imFs{i});
  if( embed )
    if(any(strcmp(type,{'fp','dt'}))), bbs1=gt{i};
    else bbs1=dt{i}(:,[1:4 6]); end
    I=bbApply('embed',I,bbs1(bbs1(:,5)==0,1:4),'col',[255 0 0]);
    I=bbApply('embed',I,bbs1(bbs1(:,5)==1,1:4),'col',[0 255 0]);
  end
  Is1=bbApply('crop',I,bbs(locs,1:4),'replicate',dims);
  for j=1:length(locs), Is{locs(j)}=Is1{j}; end;
  scores(locs)=bbs(locs,5); imgIds(locs)=i;
end; Is=cell2array(Is);
% optionally display
if(~show), return; end; figure(show); pMnt={'hasChn',size(Is1{1},3)>1};
if(isempty(fStr)), montage2(Is,pMnt); title(type); return; end
ls=cell(1,n); for i=1:n, ls{i}=int2str2(imgIds(i)); end
if(~strcmp(type,'fn'))
  for i=1:n, ls{i}=[ls{i} '/' num2str(scores(i),fStr)]; end; end
montage2(Is,[pMnt 'labels' {ls}]); title(type);
end

function oa = compOas( dt, gt, ig )
% Computes (modified) overlap area between pairs of bbs.
%
% Uses modified Pascal criteria with "ignore" regions. The overlap area
% (oa) of a ground truth (gt) and detected (dt) bb is defined as:
%  oa(gt,dt) = area(intersect(dt,dt)) / area(union(gt,dt))
% In the modified criteria, a gt bb may be marked as "ignore", in which
% case the dt bb can can match any subregion of the gt bb. Choosing gt' in
% gt that most closely matches dt can be done using gt'=intersect(dt,gt).
% Computing oa(gt',dt) is equivalent to:
%  oa'(gt,dt) = area(intersect(gt,dt)) / area(dt)
%
% USAGE
%  oa = bbGt( 'compOas', dt, gt, [ig] )
%
% INPUTS
%  dt       - [mx4] detected bbs
%  gt       - [nx4] gt bbs
%  ig       - [nx1] 0/1 ignore flags (0 by default)
%
% OUTPUTS
%  oas      - [m x n] overlap area between each gt and each dt bb
%
% EXAMPLE
%  dt=[0 0 10 10]; gt=[0 0 20 20];
%  oa0 = bbGt('compOas',dt,gt,0)
%  oa1 = bbGt('compOas',dt,gt,1)
%
% See also bbGt, bbGt>evalRes
m=size(dt,1); n=size(gt,1); oa=zeros(m,n);
if(nargin<3), ig=zeros(n,1); end
de=dt(:,[1 2])+dt(:,[3 4]); da=dt(:,3).*dt(:,4);
ge=gt(:,[1 2])+gt(:,[3 4]); ga=gt(:,3).*gt(:,4);
for i=1:m
  for j=1:n
    w=min(de(i,1),ge(j,1))-max(dt(i,1),gt(j,1)); if(w<=0), continue; end
    h=min(de(i,2),ge(j,2))-max(dt(i,2),gt(j,2)); if(h<=0), continue; end
    t=w*h; if(ig(j)), u=da(i); else u=da(i)+ga(j)-t; end; oa(i,j)=t/u;
  end
end
end

function oa = compOa( dt, gt, ig )
% Optimized version of compOas for a single pair of bbs.
%
% USAGE
%  oa = bbGt( 'compOa', dt, gt, ig )
%
% INPUTS
%  dt       - [1x4] detected bb
%  gt       - [1x4] gt bb
%  ig       - 0/1 ignore flag
%
% OUTPUTS
%  oa       - overlap area between gt and dt bb
%
% EXAMPLE
%  dt=[0 0 10 10]; gt=[0 0 20 20];
%  oa0 = bbGt('compOa',dt,gt,0)
%  oa1 = bbGt('compOa',dt,gt,1)
%
% See also bbGt, bbGt>compOas
w=min(dt(3)+dt(1),gt(3)+gt(1))-max(dt(1),gt(1)); if(w<=0),oa=0; return; end
h=min(dt(4)+dt(2),gt(4)+gt(2))-max(dt(2),gt(2)); if(h<=0),oa=0; return; end
i=w*h; if(ig),u=dt(3)*dt(4); else u=dt(3)*dt(4)+gt(3)*gt(4)-i; end; oa=i/u;
end
