function varargout = bbEval( action, varargin )
% Routines for evaluating the Pascal criteria for object detection.
%
% bbEval contains a number of utility functions, accessed using:
%  outputs = bbEval( 'action', inputs );
% The list of functions and help for each is given below. Also, help on
% individual subfunctions can be accessed by: "help bbEval>action".
%
% Evaluates detections in a single frame against ground truth data.
%   [gt, dt] = evalRes( gt0, dt0, thr )
% Computes (modified) overlap area between pairs of bbs.
%   oa = bbEval( 'compOas', dt, gt, [ig] )
% Optimized version of compOas for a single pair of bbs.
%   oa = bbEval( 'compOa', dt, gt, ig )
%
% USAGE
%  varargout = bbEval( action, varargin );
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
% See also bbApply, bbGt, bbEval>evalRes, bbEval>compOas, bbEval>compOa
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

%#ok<*DEFNU>
varargout = cell(1,max(1,nargout));
[varargout{:}] = feval(action,varargin{:});
end

function [gt, dt] = evalRes( gt0, dt0, thr )
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
%  [gt, dt] = bbEval( 'evalRes', gt0, dt0, thr )
%
% INPUTS
%  gt0  - [mx5] ground truth array with rows [x y w h ignore]
%  dt0  - [nx5] detection results array with rows [x y w h score]
%  thr  - the threshold on oa for comparing two bbs
%
% OUTPUTS
%  gt   - [mx5] ground truth results [x y w h match]
%  dt   - [nx6] detection results [x y w h score match]
%
% EXAMPLE
%
% See also bbEval, bbEval>compOas

% check / sort inputs
assert( size(dt0,2)==5 ); nd=size(dt0,1);
assert( size(gt0,2)==5 ); ng=size(gt0,1);
[disc,ord]=sort(dt0(:,5),'descend'); dt0=dt0(ord,:);
[disc,ord]=sort(gt0(:,5),'ascend'); gt0=gt0(ord,:);
gt=gt0; gt(:,5)=-gt(:,5); dt=dt0; dt=[dt zeros(nd,1)];

% Attempt to match each (sorted) dt to each (sorted) gt
for d=1:nd
  dtm=0; maxOa=thr; maxg=0;
  for g=1:ng
    gtm=gt(g,5); if(gtm==1), continue; end
    if( dtm==1 && gtm==-1 ), break; end
    oa = compOa(dt(d,1:4),gt(g,1:4),gtm==-1);
    if(oa<maxOa), continue; end
    maxOa=oa; maxg=g; if(gtm==0), dtm=1; else dtm=-1; end
  end; g=maxg;
  if(dtm==-1), assert(gt(g,5)==-1); dt(d,6)=-1; end
  if(dtm==1), assert(gt(g,5)==0); gt(g,5)=1; dt(d,6)=1; end
end

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
%  oa = bbEval( 'compOas', dt, gt, [ig] )
%
% INPUTS
%  dt       - [nx4] detected bbs
%  gt       - [nx4] gt bbs
%  ig       - [nx1] 0/1 ignore flags (0 by default)
%
% OUTPUTS
%  oas      - [m x n] overlap area between each gt and each dt bb
%
% EXAMPLE
%  dt=[0 0 10 10]; gt=[0 0 20 20];
%  oa0 = bbEval('compOas',dt,gt,0)
%  oa1 = bbEval('compOas',dt,gt,1)
%
% See also bbEval, bbEval>evalRes
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
%  oa = bbEval( 'compOa', dt, gt, ig )
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
%  oa0 = bbEval('compOa',dt,gt,0)
%  oa1 = bbEval('compOa',dt,gt,1)
%
% See also bbEval, bbEval>compOas
w=min(dt(3)+dt(1),gt(3)+gt(1))-max(dt(1),gt(1)); if(w<=0), return; end
h=min(dt(4)+dt(2),gt(4)+gt(2))-max(dt(2),gt(2)); if(h<=0), return; end
i=w*h; if(ig),u=dt(3)*dt(4); else u=dt(3)*dt(4)+gt(3)*gt(4)-i; end; oa=i/u;
end