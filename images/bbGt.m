function varargout = bbGt( action, varargin )
% Bounding box (bb) annotations struct, evaluation and sampling routines.
%
% bbGt gives acces to three types of routines:
% (1) Data structure for storing bb image annotations.
% (2) Routines for evaluating the Pascal criteria for object detection.
% (3) Routines for sampling training examples from a labeled image.
%
% The bb annotation stores bb for objects of interest with additional
% information per object, such as occlusion information. The underlying
% data structure is simply a Matlab stuct array, one struct per object.
% This annotation format is an alternative to the annotation format used
% for the PASCAL object challenges.
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
% Load bb annotation from text file.
%   objs = bbGt( 'bbLoad', fName )
% Get object property 'name' (in a standard array).
%   vals = bbGt( 'get', objs, name )
% Set object property 'name' (with a standard array).
%   objs = bbGt( 'set', objs, name, vals )
% Draw an ellipse for each labeled object.
%   hs = draw( objs, varargin )
%
%%% (2) Routines for evaluating the Pascal criteria for object detection.
% Returns filtered ground truth bbs for purpose of evaluation.
%   gtBbs = bbGt( 'toGt', objs, prm )
% Evaluates detections in a single frame against ground truth data.
%  [gt, dt] = bbGt( 'evalRes', gt0, dt0, [thr], [mul] )
% Display evaluation results for given image.
%  [hs,hImg] = bbGt( 'showRes' I, gt, dt, varargin )
% Run evaluation evalRes for each ground truth/detection result in dirs.
%  [gt,dt,files] = bbGt( 'evalResDir', gtDir, dtDir, [varargin] )
% Compute ROC or PR based on outputs of evalRes on multiple images.
%  [xs,ys,ref] = bbGt( 'compRoc', gt, dt, roc, ref )
% Extract true or false positives or negatives for visualization.
%  [Is,scores,imgIds] = bbGt( 'cropRes', gt, dt, files, varargin )
% Computes (modified) overlap area between pairs of bbs.
%   oa = bbGt( 'compOas', dt, gt, [ig] )
% Optimized version of compOas for a single pair of bbs.
%   oa = bbGt( 'compOa', dt, gt, ig )
%
%%% (3) Routines for sampling training examples from a labeled image.
% Sample pos or neg examples for training from an annotated image.
%   [bbs, IS] = bbGt( 'sampleData', I, prm )
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
% bbGt>get, bbGt>set, bbGt>draw, bbGt>toGt, bbGt>evalRes, bbGt>showRes,
% bbGt>evalResDir, bbGt>compRoc, bbGt>cropRes, bbGt>compOas, bbGt>compOa,
% bbGt>sampleData
%
% Piotr's Image&Video Toolbox      Version 2.52
% Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

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
if(nargin<1), n=1; end; objs=repmat(o,n,1);
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

function objs = bbLoad( fName )
% Load bb annotation from text file.
%
% USAGE
%  objs = bbGt( 'bbLoad', fName )
%
% INPUTS
%  fName  - name of text file
%
% OUTPUTS
%  objs   - loaded objects
%
% EXAMPLE
%
% See also bbGt, bbGt>bbSave
if(~exist(fName,'file')), error([fName ' not found']); end
try v=textread(fName,'%% bbGt version=%d',1); catch, v=0; end %#ok<CTCH>
if(isempty(v)), v=0; end; opts={'commentstyle','matlab'};
% if old ann version may have fewer fields m (initialize them to 0)
if(all(v~=[0 1 2 3])), error('Unknown version %i.',v); end
ms=[10 10 11 12]; m=ms(v+1); in=cell(1,m);
[in{:}]=textread(fName,['%s' repmat(' %d',1,m-1)],opts{:});
for i=m+1:12, in{i}=zeros(length(in{1}),1); end
% create objs struct from read in fields
nObj=length(in{1}); O=ones(1,nObj); occ=mat2cell(in{6},O,1);
bb=mat2cell([in{2:5}],O,4); bbv=mat2cell([in{7:10}],O,4);
ign=mat2cell(in{11},O,1); ang=mat2cell(in{12},O,1);
objs=struct('lbl',in{1},'bb',bb,'occ',occ,'bbv',bbv,'ign',ign,'ang',ang);
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
  case 'occ', for i=1:nObj, objs(i).ooc=vals(i); end
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
%  objs = bbGt( 'draw', objs, prm )
%
% INPUTS
%  objs       - [nx1] struct array of objects
%  varargin   - additional params (struct or name/value pairs)
%   .col        - ['g'] color or [kx1] array of colors
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

function [gtBbs,ids] = toGt( objs, prm )
% Returns filtered ground truth bbs for purpose of evaluation.
%
% Returns bbs for all objects with lbl in lbls. The result is an [nx5]
% array where each row is of the form [x y w h ignore]. [x y w h] is the bb
% and ignore is a 0/1 flag that indicates regions to be ignored. For each
% returned object, the ignore flag is set to 1 if obj.ign==1 or any object
% property is outside of the specified range (details below). The ignore
% flag is used during evaluation so that objects with certain properties
% (such as very small or heavily occluded objects) can be excluded.
%
% For oriented bbs, the extent of the bb is returned instead, where the
% extent is the smallest axis aligned bb containing the oriented bb. If the
% oriented bb was labeled as a rectangle as opposed to an ellipse, the
% tightest bb will usually increase slightly in size due to the corners of
% the rectangle sticking out beyond the ellipse bounds. The 'ellipse' flag
% controls how an oriented bb is converted to a regular bb. Specifically,
% set ellipse=1 if an ellipse tightly delineates the object and 0 ow.
%
% The range for each property is a two element vector, [0 inf] by default;
% a property value v is inside the range if v>=rng(1) && v<=rng(2). Tested
% properties include height (h), width (w), area (a), aspect ratio (ar),
% orienation (o), extent x-coordinate (x), extent y-coordinate (y), and
% fraction visible (v). The last property is computed as the visible object
% area divided by the total area, except if o.occ==0, in which case v=1, or
% all(o.bbv==o.bb), which indicates the object may be barely visible, in
% which case v=0 (note that v~=1 in this case).
%
% USAGE
%  gtBbs = bbGt( 'toGt', objs, prm )
%
% INPUTS
%  objs     - ground truth objects
%  prm      -
%   .lbls       - [] return objs w these labels (or [] to return all)
%   .ilbls      - [] return objs w these labels but set to ignore
%   .hRng       - [0 inf] range of acceptable obj heights
%   .wRng       - [0 inf] range of acceptable obj widths
%   .aRng       - [0 inf] range of acceptable obj areas
%   .arRng      - [0 inf] range of acceptable obj aspect ratios
%   .oRng       - [0 inf] range of acceptable obj orientations (angles)
%   .xRng       - [-inf inf] range of x coordinates of bb extent
%   .yRng       - [-inf inf] range of y coordinates of bb extent
%   .vRng       - [0 inf] range of acceptable obj occlusion levels
%   .ar         - [] standardize aspect ratios of bbs
%   .pad        - [0] frac extra padding for each patch (or [padx pady])
%   .ellipse    - [1] controls how oriented bb is converted to regular bb
%
% OUTPUTS
%  gtBbs    - [n x 5] array containg ground truth bbs [x y w h ignore]
%  ids      - [n x 1] list of object ids selected
%
% EXAMPLE
%  objs=bbGt('create',3);
%  objs(1).ign=0; objs(1).lbl='person'; objs(1).bb=[0 0 10 10];
%  objs(2).ign=0; objs(2).lbl='person'; objs(2).bb=[0 0 20 20];
%  objs(3).ign=0; objs(3).lbl='bicycle'; objs(3).bb=[0 0 20 20];
%  [gtBbs,ids] = bbGt('toGt',objs,{'lbls',{'person'},'hRng',[15 inf]})
%
% See also bbGt

r=[0 inf]; r1=[-inf inf];
dfs={'lbls',[],'ilbls',[],'hRng',r,'wRng',r,'aRng',r,'arRng',r,...
  'oRng',r,'xRng',r1,'yRng',r1,'vRng',r,'ar',[],'pad',0,'ellipse',1};
[lbls,ilbls,hRng,wRng,aRng,arRng,oRng,xRng,yRng,vRng,ar0,pad,ellipse] = ...
  getPrmDflt(prm,dfs,1);
if(numel(pad)==1), pad=[pad pad]; end;
nObj=length(objs); keep=true(nObj,1); gtBbs=zeros(nObj,5);
chk = @(v,rng) v<rng(1) || v>rng(2); lbls=[lbls ilbls];
for i=1:nObj, o=objs(i);
  if(~isempty(lbls) && ~any(strcmp(o.lbl,lbls))), keep(i)=0; continue; end
  bb=o.bb; bbv=o.bbv; w=bb(3); h=bb(4); a=w*h; ar=w/h; ang=mod(o.ang,360);
  if(~o.occ || all(bbv==0)), v=1; elseif(all(bbv==bb)), v=0; else
    v=bbv(3)*bbv(4)/a; end
  ex = bbExtent(o.bb,ang,ellipse);
  ign = o.ign || any(strcmp(o.lbl,ilbls)) || chk(h,hRng) || chk(w,wRng) ...
    || chk(a,aRng) || chk(ar,arRng) || chk(ang,oRng) || chk(v,vRng) ...
    || chk(ex(1),xRng) || chk(ex(1)+ex(3),xRng) ...
    || chk(ex(2),yRng) || chk(ex(2)+ex(4),xRng);
  gtBbs(i,1:4)=ex; gtBbs(i,5)=ign;
end
ids=find(keep); gtBbs=gtBbs(keep,:);
if(ar0), gtBbs=bbApply('squarify',gtBbs,0,ar0); end
if(any(pad~=0)), gtBbs=bbApply('resize',gtBbs,1+pad(2),1+pad(1)); end

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

function [gt, dt] = evalRes( gt0, dt0, thr, mul )
% Evaluates detections in a single frame against ground truth data.
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
% See also bbGt, bbGt>compOas

% check inputs
if(nargin<3 || isempty(thr)), thr=.5; end
if(nargin<4 || isempty(mul)), mul=0; end
if(isempty(gt0)), gt0=zeros(0,5); end
if(isempty(dt0)), dt0=zeros(0,5); end
assert( size(dt0,2)==5 ); nd=size(dt0,1);
assert( size(gt0,2)==5 ); ng=size(gt0,1);

% sort dt highest score first, sort gt ignore last
[disc,ord]=sort(dt0(:,5),'descend'); dt0=dt0(ord,:);
[disc,ord]=sort(gt0(:,5),'ascend'); gt0=gt0(ord,:);
gt=gt0; gt(:,5)=-gt(:,5); dt=dt0; dt=[dt zeros(nd,1)];

% Attempt to match each (sorted) dt to each (sorted) gt
for d=1:nd
  bstOa=thr; bstg=0; bstm=0; % info about best match so far
  for g=1:ng
    % if this gt already matched, continue to next gt
    m=gt(g,5); if( m==1 && ~mul ), continue; end
    % if dt already matched, and on ignore gt, nothing more to do
    if( bstm~=0 && m==-1 ), break; end
    % compute overlap area, continue to next gt unless better match made
    oa=compOa(dt(d,1:4),gt(g,1:4),m==-1); if(oa<bstOa), continue; end
    % match successful and best so far, store appropriately
    bstOa=oa; bstg=g; if(m==0), bstm=1; else bstm=-1; end
  end; g=bstg; m=bstm;
  % store type of match for both dt and gt
  if(m==-1), assert(mul || gt(g,5)==m); dt(d,6)=m; end
  if(m==1), assert(gt(g,5)==0); gt(g,5)=m; dt(d,6)=m; end
end

end

function [hs,hImg] = showRes( I, gt, dt, varargin )
% Display evaluation results for given image.
%
% USAGE
%  [hs,hImg] = bbGt( 'showRes', I, gt, dt, [varargin] )
%
% INPUTS
%  I          - image to display, image filename, or []
%  gt         - first output of evalRes()
%  dt         - second output of evalRes()
%  varargin   - additional params (struct or name/value pairs)
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
% See also bbGt, bbGt>evalRes, bbGt>toGt
dfs={'evShow',1,'gtShow',1,'dtShow',1,'cols','krg',...
  'gtLs','-','dtLs','--','lw',3};
[evShow,gtShow,dtShow,cols,gtLs,dtLs,lw]=getPrmDflt(varargin,dfs,1);
% optionally display image
if(ischar(I)), I=imread(I); end
if(~isempty(I)), hImg=im(I,[],0); title(''); end
% display bbs with or w/o color coding based on output of evalRes
hold on; hs=cell(1,1000); k=0;
if( evShow )
  if( gtShow )
    for i=1:size(gt,1), k=k+1;
      hs{k}=bbApply('draw',gt(i,1:4),cols(gt(i,5)+2),lw,gtLs);
    end
  end
  if( dtShow )
    for i=1:size(dt,1), k=k+1;
      hs{k}=bbApply('draw',dt(i,1:5),cols(dt(i,6)+2),lw,dtLs);
    end
  end
else
  if(gtShow), k=k+1; hs{k}=bbApply('draw',gt(:,1:4),cols(3),lw,gtLs); end
  if(dtShow), k=k+1; hs{k}=bbApply('draw',dt(:,1:5),cols(3),lw,dtLs); end
end
hs=[hs{:}]; hold off;
end

function [gt,dt,files] = evalResDir( gtDir, dtDir, varargin )
% Run evaluation evalRes for each ground truth/detection result in dirs.
%
% Loads each ground truth annotation in gtDir and the corresponding
% detection in gtDir, and call evalRes() on the pair. The detection should
% just be a text file with each row containing 5 numbers which represent a
% bounding box (left/top/width/height/detection score). The text file may
% be empty in the case of no detections, but it must exist.
%
% Prior to calling evalRes(), the ground truth annotation is passed through
% bbGt>toGt() with the parameters pGt. See bbGt>toGt() for more info. The
% detections are optionally resized before comparing against the ground
% truth. The resizing is important as some detectors return bbs that are
% padded. For example, if a detector returns a bounding box of size 128x64
% around objects of size 100x43 (as is typical for some pedestrian
% detectors on the INRIA pedestrian database), the resize parameters should
% be {100/128, 43/64, 0}, see bbApply>resize() for more info. Finally nms
% is optionally applied to the detections (if pNms are specified), see
% bbNms() for more info.
%
% USAGE
%  [gt,dt,files] = bbGt( 'evalResDir', gtDir, dtDir, [varargin] )
%
% INPUTS
%  gtDir        - location of ground truth
%  dtDir        - location of detections
%  varargin     - additional params (struct or name/value pairs)
%   .thr          - [.5] threshold for evalRes()
%   .mul          - [0] multiple match flag for evalRes()
%   .pGt          - {} params for bbGt>toGt
%   .resize       - {} parameters for bbApply('resize')
%   .pNms         - ['type','none'] params non maximal suppresion
%   .f0           - [1] first ground truth file to use
%   .f1           - [inf] last ground truth file to use
%   .imDir        - [gtDir] directory containing images
%
% OUTPUTS
%  gt           - {1xn} first output of evalRes() for each image
%  dt           - {1xn} second output of evalRes() for each image
%  files        - {1xn} names of corresponding images (possibly w/o ext)
%
% EXAMPLE
%
% See also bbGt, bbGt>evalRes, bbGt>toGt, bbNms, bbGt>compRoc,
% bbApply>resize

dfs={'thr',.5,'mul',0,'pGt',{},'resize',{},...
  'pNms',struct('type','none'),'f0',1,'f1',inf,'imDir',''};
[thr,mul,pGt,resize,pNms,f0,f1,imDir]=getPrmDflt(varargin,dfs,1);
if(isempty(imDir)), imDir=gtDir; end
% get files in ground truth directory
files=dir([gtDir '/*.txt']); files={files.name};
files=files(f0:min(f1,end)); n=length(files); assert(n>0);
gt=cell(1,n); dt=cell(1,n); ticId=ticStatus('evaluating');
for i=1:n
  % load detections results and process appropriately
  dtNm=[dtDir '/' files{i}];
  if(~exist(dtNm,'file')), dtNm=[dtDir '/' files{i}(1:end-8) '.txt']; end
  dt1=load(dtNm,'-ascii');
  if(numel(dt1)==0), dt1=zeros(0,5); end; dt1=dt1(:,1:5);
  if(~isempty(resize)), dt1=bbApply('resize',dt1,resize{:}); end
  dt1=bbNms(dt1,pNms);
  % load ground truth and prepare for evaluation
  gtNm=[gtDir '/' files{i}];
  gt1 = bbGt('toGt',bbGt('bbLoad',gtNm),pGt);
  % name of corresponding image
  files{i} = [imDir '/' files{i}(1:end-4)];
  % run evaluation and store result
  [gt1,dt1] = bbGt('evalRes',gt1,dt1,thr,mul);
  gt{i}=gt1; dt{i}=dt1; tocStatus(ticId,i/n);
end

end

function [xs,ys,score,ref] = compRoc( gt, dt, roc, ref )
% Compute ROC or PR based on outputs of evalRes on multiple images.
%
% ROC="Receiver operating characteristic"; PR="Precision Recall"
% Also computes result at reference point (ref):
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
%  ref        - [1/.1] reference point for ROC or PR curve
%
% OUTPUTS
%  xs         - x coords for curve: ROC->FPPI; PR->recall
%  ys         - y coords for curve: ROC->TP; PR->precision
%  score      - score at each coord
%  ref        - y value at reference point
%
% EXAMPLE
%
% See also bbGt, bbGt>evalRes

% get additional parameters
if(nargin<3 || isempty(roc)), roc=1; end
if(nargin<4 || isempty(ref)), if(roc), ref=1; else ref=.1; end; end
% convert to single matrix, discard ignore bbs
nImg=length(gt); assert(length(dt)==nImg);
gt=cat(1,gt{:}); gt=gt(gt(:,5)~=-1,:);
dt=cat(1,dt{:}); dt=dt(dt(:,6)~=-1,:);
% compute results
if(size(dt,1)==0), xs=0; ys=0; ref=0; return; end
np=size(gt,1); score=dt(:,5); tp=dt(:,6);
[score, order]=sort(score,'descend'); tp=tp(order);
fp=double(tp~=1); fp=cumsum(fp); tp=cumsum(tp);
if( roc )
  tp=tp/np; fppi=fp/nImg; xs=fppi; ys=tp;
else
  rec=tp/np; prec=tp./(fp+tp); xs=rec; ys=prec;
end
% reference point
[d,ind]=min(abs(xs-ref)); ref=ys(ind);
end

function [Is,scores,imgIds] = cropRes( gt, dt, files, varargin )
% Extract true or false positives or negatives for visualization.
%
% USAGE
%  [Is,scores,imgIds] = bbGt( 'cropRes', gt, dt, files, varargin )
%
% INPUTS
%  gt         - {1xN} first output of evalRes() for each image
%  dt         - {1xN} second output of evalRes() for each image
%  files      - {1xN} name of each image
%  varargin   - additional params (struct or name/value pairs)
%   .dims       - ['REQ'] target dimensions for extracted windows
%   .pad        - [0] padding amount for cropping
%   .type       - ['fp'] one of: 'fp', 'fn', 'tp', 'dt'
%   .n          - [100] max number of windows to extract
%   .show       - [1] figure for displaying results (or 0)
%   .fStr       - ['%0.1f'] label{i}=num2str(score(i),fStr)
%
% OUTPUTS
%  Is         - [dimsxn] extracted image windows
%  scores     - [1xn] detection score for each bb unless 'fn'
%  imgIds     - [1xn] image id for each cropped window
%
% EXAMPLE
%
% See also bbGt, bbGt>evalRes
dfs={'dims','REQ','pad',0,'type','fp','n',100,'show',1,'fStr','%0.1f'};
[dims,pad,type,n,show,fStr]=getPrmDflt(varargin,dfs,1);
N=length(files); assert(length(gt)==N && length(dt)==N);
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
if(~strcmp(type,'fn')), [d,ord]=sort(bbs(:,5),'descend'); else
  if(size(bbs,1)<n), ord=randperm(size(bbs,1)); else ord=1:n; end; end
bbs=bbs(ord(1:n),:); ids=ids(ord(1:n));
% extract patches from each image
if(n==0), Is=[]; scores=[]; imgIds=[]; return; end;
Is=cell(1,n); scores=zeros(1,n); imgIds=zeros(1,n);
if(any(pad>0)), dims1=dims+2*pad; rs=dims1./dims; dims=dims1; end
if(any(pad>0)), bbs=bbApply('resize',bbs,rs(1),rs(2)); end
for i=1:N
  locs=find(ids==i); if(isempty(locs)), continue; end
  Is1=bbApply('crop',imread(files{i}),bbs(locs,1:4),'replicate',dims);
  for j=1:length(locs), Is{locs(j)}=Is1{j}; end;
  scores(locs)=bbs(locs,5); imgIds(locs)=i;
end; Is=cell2array(Is);
% optionally display
if(~show), return; end; figure(show); clf;
pMnt={'hasChn',size(Is1{1},3)>1};
if(~isempty(fStr) && ~strcmp(type,'fn'))
  lbls=cell(1,n); for i=1:n, lbls{i}=num2str(scores(i),fStr); end
  pMnt=[pMnt 'labels' {lbls}];
end; montage2(Is,pMnt); title(type);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [bbs, IS] = sampleData( I, prm )
% Sample pos or neg examples for training from an annotated image.
%
% An annotated image can contain both pos and neg examples of a given class
% (such as a pedestrian). This function allows for sampling of only pos
% windows, without sampling any negs, or vice-versa. For example, this can
% be quite useful during bootstrapping, to sample high scoring false pos
% without actually sampling any windows that contain true pos.
%
% bbs should contain the candidate bounding boxes, and ibbs should contain
% the bounding boxes that are to be ignored. During sampling, only bbs that
% do not match any ibbs are kept (two bbs match if their area of overlap is
% above the given thr, see bbGt>compOas). Use gtBbs=toGt(...) to obtain a
% list of ground truth bbs containing the positive windows. Let dtBbs
% contain the bbs output by some detection algorithm. Then,
%  to sample true-positives, use:   bbs=gtBbs and ibbs=[]
%  to sample false-negatives, use:  bbs=gtBbs and ibbs=dtBbs
%  to sample false-positives, use:  bbs=dtBbs and ibbs=gtBbs
% To sample regular negatives without bootstrapping generate bbs
% systematically or randomly (see for example bbApply>random).
%
% dims determines the dimension of the sampled bbs. If dims has two
% elements [w h], then the aspect ratio (ar) of each bb is set to ar=w/h
% using bbApply>squarify, and the extracted patches are resized to the
% target w and h. If dims has 1 element then ar=dims, but the bbs are not
% resized to a fixed size. If dims==[], the bbs are not altered.
%
% USAGE
%  [bbs, IS] = bbGt( 'sampleData', I, prm )
%
% INPUTS
%  I        - input image from which to sample
%  prm      -
%   .n          - [inf] max number of bbs to sample
%   .bbs        - [REQ] candidate bbs from which to sample [x y w h ign]
%   .ibbs       - [] bbs that should not be sampled [x y w h ign]
%   .thr        - [.5] overlap threshold between bbs and ibbs
%   .dims       - [] target bb aspect ratio [ar] or dims [w h]
%   .squarify   - [1] if squarify expand bb to ar else stretch patch to ar
%   .pad        - [0] frac extra padding for each patch (or [padx pady])
%   .padEl      - ['replicate'] how to pad at boundaries (see bbApply>crop)
%   .flip       - [0] if true use left/right reflection of each bb
%   .rots       - [0] specify 90 degree rotations of each bb (e.g. 0:3)
%
% OUTPUTS
%  bbs      - actual sampled bbs
%  IS       - [1xn] cell of cropped image regions
%
% EXAMPLE
%
% See also bbGt, bbGt>toGt, bbApply>crop, bbApply>resize, bbApply>squarify
% bbApply>random, bbGt>compOas

% get parameters
dfs={'n',inf, 'bbs','REQ', 'ibbs',[], 'thr',.5, 'dims',[], ...
  'squarify',1, 'pad',0, 'padEl','replicate', 'flip',0, 'rots',0 };
[n,bbs,ibbs,thr,dims,squarify,pad,padEl,flip,rots]=getPrmDflt(prm,dfs,1);
if(numel(dims)==2), ar=dims(1)/dims(2); else ar=dims; dims=[]; end
if(numel(pad)==1), pad=[pad pad]; end; if(dims), dims=dims.*(1+pad); end
% discard any candidate bbs that match the ignore bbs, sample to at most n
nd=size(bbs,2); if(nd==5), bbs=bbs(bbs(:,5)==0,:); end
if(flip), n=n/2; end; n=n/length(rots); m=size(bbs,1);
if(isempty(ibbs)), if(m>n), bbs=bbs(randsample(m,n),:); end; else
  if(m>n), bbs=bbs(randperm(m),:); end; K=false(1,m); i=1;
  keep=@(i) all(compOas(bbs(i,:),ibbs,ibbs(:,5))<thr);
  while(sum(K)<n && i<=m), K(i)=keep(i); i=i+1; end; bbs=bbs(K,:);
end
% standardize aspect ratios (by growing bbs) and pad bbs
if(~isempty(ar) && squarify), bbs=bbApply('squarify',bbs,0,ar); end
if(any(pad~=0)), bbs=bbApply('resize',bbs,1+pad(2),1+pad(1)); end
% crop IS, resizing if dims~=[]
crop=nargout==2; dims=round(dims);
if(crop), [IS,bbs]=bbApply('crop',I,bbs,padEl,dims); end
% finally create flipped and rotated versions of each croppted patch
nf=flip+1; nr=length(rots); bbs=reshape(repmat(bbs,1,nf*nr)',nd,[])';
if(~crop), return; end; IS=repmat(IS,nf*nr,1); IS=IS(:);
for i=1:size(bbs,1)
  I=IS{i}; f=mod(i+1,nf); if(f), I=flipdim(I,2); end
  I0=I; r=rots(floor(mod(i-1,nr*nf)/nf)+1);
  if(mod(r,2)==1), I=permute(I,[2 1 3]); end
  for k=1:size(I,3), I(:,:,k)=rot90(I0(:,:,k),r); end; IS{i}=I;
end
end
