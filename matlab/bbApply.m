function varargout = bbApply( action, varargin )
% Functions for manipulating bounding boxes (bb).
%
% A bounding box (bb) is also known as a position vector or a rectangle
% object. It is a four element vector with the fields: [x y w h]. A set of
% n bbs can be stores as an [nx4] array, most funcitons below can handle
% either a single or multiple bbs. In addtion, typically [nxm] inputs with
% m>4 are ok (with the additional columns ignored/copied to the output).
%
% bbApply contains a number of utility functions for working with bbs. The
% format for accessing the various utility functions is:
%  outputs = bbApply( 'action', inputs );
% The list of functions and help for each is given in the "See also"
% section. Also, help on individual subfunctions can be accessed by:
%  help bbApply>action;
%
% USAGE
%  varargout = bbApply( action, varargin );
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
% See also bbApply>area bbApply>shift bbApply>getCenter bbApply>intersect
% bbApply>union bbApply>resize bbApply>squarify bbApply>draw bbApply>crop
% bbApply>convert bbApply>random bbApply>nms
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]
varargout = cell(1,nargout);
[varargout{:}] = eval([action '(varargin{:});']);
end

function a = area( bb ) %#ok<*DEFNU>
% Compute area of bbs.
%
% USAGE
%  bb = bbApply( 'area', bb )
%
% INPUTS
%  bb     - [nx4] original bbs
%
% OUTPUTS
%  a      - [nx1] area of each bb
%
% EXAMPLE
%  a = bbApply('area', [0 0 10 10])
%
% See also bbApply
a=prod(bb(:,3:4),2);
end

function bb = shift( bb, xdel, ydel )
% Shift center of bbs.
%
% USAGE
%  bb = bbApply( 'shift', bb, xdel, ydel )
%
% INPUTS
%  bb     - [nx4] original bbs
%  xdel   - amount to shift x coord of each bb left
%  ydel   - amount to shift y coord of each bb up
%
% OUTPUTS
%  bb     - [nx4] shifted bbs
%
% EXAMPLE
%  bb = bbApply('shift', [0 0 10 10], 1, 2)
%
% See also bbApply
bb(:,1)=bb(:,1)-xdel; bb(:,2)=bb(:,2)-ydel;
end

function cen = getCenter( bb )
% Get center of bbs.
%
% USAGE
%  cen = bbApply( 'getCenter', bb )
%
% INPUTS
%  bb     - [nx4] original bbs
%
% OUTPUTS
%  cen    - [nx1] centers of bbs
%
% EXAMPLE
%  cen = bbApply('getCenter', [0 0 10 10])
%
% See also bbApply
cen=bb(:,1:2)+bb(:,3:4)/2;
end

function bb = intersect( bb1, bb2 )
% Get bb at intersection of bb1 and bb2 (may be empty).
%
% USAGE
%  bb = bbApply( 'intersect', bb1, bb2 )
%
% INPUTS
%  bb1    - [nx4] first set of bbs
%  bb2    - [nx4] second set of bbs
%
% OUTPUTS
%  bb     - [nx4] intersection of bbs
%
% EXAMPLE
%  bb = bbApply('intersect', [0 0 10 10], [5 5 10 10])
%
% See also bbApply bbApply>union
n1=size(bb1,1); n2=size(bb2,1);
if(n1==0 || n2==0), bb=zeros(0,4); return, end
if(n1==1 && n2>1), bb1=repmat(bb1,n2,1); n1=n2; end
if(n2==1 && n1>1), bb2=repmat(bb2,n1,1); n2=n1; end
assert(n1==n2);
lcsE=min(bb1(:,1:2)+bb1(:,3:4),bb2(:,1:2)+bb2(:,3:4));
lcsS=max(bb1(:,1:2),bb2(:,1:2)); empty=any(lcsE<lcsS,2);
bb=[lcsS lcsE-lcsS]; bb(empty,:)=0;
end

function bb = union( bb1, bb2 )
% Get bb that is union of bb1 and bb2 (smallest bb containing both).
%
% USAGE
%  bb = bbApply( 'union', bb1, bb2 )
%
% INPUTS
%  bb1    - [nx4] first set of bbs
%  bb2    - [nx4] second set of bbs
%
% OUTPUTS
%  bb     - [nx4] intersection of bbs
%
% EXAMPLE
%  bb = bbApply('union', [0 0 10 10], [5 5 10 10])
%
% See also bbApply bbApply>intersect
n1=size(bb1,1); n2=size(bb2,1);
if(n1==0 || n2==0), bb=zeros(0,4); return, end
if(n1==1 && n2>1), bb1=repmat(bb1,n2,1); n1=n2; end
if(n2==1 && n1>1), bb2=repmat(bb2,n1,1); n2=n1; end
assert(n1==n2);
lcsE=max(bb1(:,1:2)+bb1(:,3:4),bb2(:,1:2)+bb2(:,3:4));
lcsS=min(bb1(:,1:2),bb2(:,1:2));
bb=[lcsS lcsE-lcsS];
end

function bbr = resize( bb, hr, wr, ar )
% Resize the bbs (without moving their centers).
%
% The w/h of each bb is adjusted in the following order:
%  if(hr~=0); h=h*hr; end;
%  if(wr~=0); w=w*wr; end
%  if(hr==0); h=w/ar; end
%  if(wr==0); w=h*ar; end
% Only one of hr/wr may be set to 0, and then only if ar>0.
%
% USAGE
%  bbr = bbApply( 'resize', bb, hr, wr, [ar] )
%
% INPUTS
%  bb     - [nx4] original bbs
%  hr     - ratio by which to multiply height (or 0)
%  wr     - ratio by which to multiply width (or 0)
%  ar     - [0] aspect ratio to fix (or 0)
%
% OUTPUT
%  bbr    - [nx4] the output resized bbs
%
% EXAMPLE
%  bbr = bbApply('resize',[0 0 1 1],1.2,0,.5) % h'=1.2*h; w'=h'/2;
%
% See also bbApply, bbApply>squarify
if(nargin<4), ar=0; end
assert(hr>0||wr>0); assert((hr>0&&wr>0)||ar>0);
assert(size(bb,2)>=4); bbr=bb;
for i=1:size(bb,1)
  p=bb(i,1:4);
  % possibly adjust h/w based on hr/wr
  if(hr~=0), dy=(hr-1)*p(4); p(2)=p(2)-dy/2; p(4)=p(4)+dy; end
  if(wr~=0), dx=(wr-1)*p(3); p(1)=p(1)-dx/2; p(3)=p(3)+dx; end
  % possibly adjust h/w based on ar and NEW h/w
  if(hr==0), dy=p(3)/ar-p(4); p(2)=p(2)-dy/2; p(4)=p(4)+dy; end
  if(wr==0), dx=p(4)*ar-p(3); p(1)=p(1)-dx/2; p(3)=p(3)+dx; end
  bbr(i,1:4)=p;
end
end

function bbr = squarify( bb, flag )
% Make bbs square (without moving their centers).
%
% The w/h of each bb is adjusted to make it square with side length s.
% flag controls which of w/h is used as s. Possible values for flag:
%  flag==0: s = max(w,h)
%  flag==1: s = min(w,h)
%  flag==2: s = w
%  flag==3: s = h
%
% USAGE
%  bbr = bbApply( 'squarify', bb, flag )
%
% INPUTS
%  bb     - [nx4] original bbs
%  flag   - controls which of w/h is used as s
%
% OUTPUT
%  bbr    - the output 'squarified' bbs
%
% EXAMPLE
%  bbr = bbApply('squarify',[0 0 1 2],0)
%
% See also bbApply, bbApply>resize
bbr=bb;
for i=1:size(bb,1)
  p=bb(i,1:4);
  useWidth = (flag==0 && p(3)>p(4)) || (flag==1 && p(3)<p(4)) || flag==2;
  if(useWidth), p=resize(p,0,1,1); else p=resize(p,1,0,1); end
  bbr(i,1:4)=p;
end

end

function hs = draw( bb, col, lw, ls, prop )
% Draw single or multiple bbs to image (calls rectangle())
%
% USAGE
%  hs = bbApply( 'draw', bb, col, [lw], [ls], [prop] )
%
% INPUTS
%  bb     - [nx4] input bbs
%  col    - color for rectangle
%  lw     - [2] LineWidth for rectangle
%  ls     - ['-'] LineStyle for rectangle
%  prop   - [] other properties for rectangle
%
% OUTPUT
%  hs     - [nx1] handles to drawn rectangles
%
% EXAMPLE
%  im(rand(3)); bbApply('draw',[1.5 1.5 1 1],'g')
%
% See also bbApply
if(nargin<3 || isempty(lw)), lw=2; end
if(nargin<4 || isempty(ls)), ls='-'; end
if(nargin<5 || isempty(prop)), prop={}; end
n=size(bb,1); hs=zeros(1,n);
for b=1:n
  hs(b) = rectangle( 'Position',bb(b,1:4), 'EdgeColor',col, ...
    'LineWidth',lw, 'LineStyle',ls, prop{:});
end
end

function [I, bb] = crop( I, bb, padEl )
% Crop image region from I encompassed by bb.
%
% The only subtlety is that a pixel centered at location (i,j) would have a
% bb of [j-.5,i-.5,1,1].  The .-5 is because pixels are located at integer
% locations. This is a Matlab convention, to confirm use:
%  im(rand(3)); bbApply('draw',[1.5 1.5 1 1],'g')
% If bb contains all integer entries cropping is straightforward. If
% entries are not integers, x=round(x+.499) is used, ie 1.2 actually goes
% to 2 (since it is closer to 1.5 then .5), and likewise for y.
%
% If ~isempty(padEl), image is padded so can extract full bb region (no
% actual padding is done, this is fast). Otherwise bb is intersected with
% the image bb prior to cropping.
%
% USAGE
%  I = bbApply( 'crop', I, bb, [padEl] )
%
% INPUTS
%  I      - image to crop from
%  bb     - defines region to crop
%  padEl  - [0] value to pad I
%
% OUTPUTS
%  I      - cropped image region
%  bb     - actual integer-valued bb used to crop
%
% EXAMPLE
%  I=imread('cameraman.tif'); bb=[-10 -10 100 100];
%  I1=bbApply('crop',I,bb); I2=bbApply('crop',I,bb,[]);
%  figure(1); im(I); figure(2); im(I1); figure(3); im(I2);
%
% See also bbApply, ARRAYCROP

% get padEl, bound bb to visible region if empty
if( nargin<3 ); padEl=0; end
if( isempty(padEl) )
  bb1 = [.5 .5 size(I,2) size(I,1)];
  bb = intersect(bb1,bb);
end

% crop (use arrayCrop only if necessary)
lcsS=round(bb([2 1])+.5-.001); lcsE=lcsS+round(bb([4 3]))-1;
if( any(lcsS<1) || lcsE(1)>size(I,1) || lcsE(2)>size(I,2) )
  if(ndims(I)==3); lcsS=[lcsS 1]; lcsE=[lcsE 3]; end
  I = arrayCrop(I,lcsS,lcsE,padEl);
else
  I = I( lcsS(1):lcsE(1), lcsS(2):lcsE(2), : );
end
bb = [lcsS([2 1]) lcsE([2 1])-lcsS([2 1])+1];

end

function bb = convert( bb, bbRef, isAbs )
% Convert bb relative to absolute coordinates and vice-versa.
%
% If isAbs==1, bb is assumed to be given in absolute coords, and the output
% is given in coords relative to bbRef. Otherwise, if isAbs==0, bb is
% assumed to be given in coords relative to bbRef and the output is given
% in absolute coords.
%
% USAGE
%  bb = bbApply( 'convert', bb, bbRef, isAbs )
%
% INPUTS
%  bb     - original bb, either in abs or rel coords
%  bbRef  - reference bb
%  isAbs  - 1: bb is in abs coords, 0: bb is in rel coords
%
% OUTPUTS
%  bb     - converted bb
%
% EXAMPLE
%  bbRef=[5 5 15 15]; bba=[10 10 5 5];
%  bbr = bbApply( 'convert', bba, bbRef, 1 )
%  bba2 = bbApply( 'convert', bbr, bbRef, 0 )
%
% See also bbApply
if( isAbs )
  bb(1:2)=bb(1:2)-bbRef(1:2);
  bb=bb./bbRef([3 4 3 4]);
else
  bb=bb.*bbRef([3 4 3 4]);
  bb(1:2)=bb(1:2)+bbRef(1:2);
end
end

function bb = random( w, h, bbw, bbh, n )
% Uniformly generate n (integer) bbs constrained between [1,w]x[1,h].
%
% USAGE
%  bb = bbApply('random',w,h,bbw,bbh,n)
%
% INPUTS
%  w      - maximum right most bb location
%  h      - maximum bottom most bb location
%  bbw    - bb width
%  bbh    - bb height
%  n      - number of bbs to generate
%
% OUTPUTS
%  bb     - randomly generate bbs
%
% EXAMPLE
%  bb = bbApply('random',5,5,3,3,10)
%
% See also bbApply

bb=zeros(n,4); bb(:,3)=bbw; bb(:,4)=bbh;
bb(:,1) = randint2(n,1,[1,h-bbh+1]);
bb(:,2) = randint2(n,1,[1,w-bbw+1]);

end

function bbs = nms( bbs, thr, radii )
% Mean shift non-maximal suppression (nms) of bbs w variable width kernel.
%
% radii controls the amount of suppression. radii is a 4 element vector
% containing the radius for each dimension (x,y,w,h). Typically the first
% two elements should be the same, as should the last two. Distance between
% w/h are computed in log2 space (ie w and w*2 are 1 unit apart), and the
% radii should be set accordingly. Default radii=[.05 .05 .5 .5].
%
% USAGE
%  bbs = bbApply('nms',bbs,thr,[radii])
%
% INPUTS
%  bbs      - original bbs (must be of form [x y w h wt])
%  thr      - threshold below which to discard bbs
%  radii    - [] supression radii (see above)
%
% OUTPUTS
%  bbs      - suppressed bbs
%
% EXAMPLE
%  bbs=[0 0 1 1 1; .1 .1 1 1 1.1; 2 2 1 1 1];
%  bbs1 = bbApply('nms',bbs,.1)
%
% See also bbApply, nonMaxSuprList

% remove all bbs that fall below threshold
keep=bbs(:,5)>thr; bbs=bbs(keep,:); n=size(bbs,1);
if(n<=1), return; end; 
if(nargin<3 || isempty(radii)), radii=[.05 .05 .5 .5]; end

% position = [x/w,y/h,log2(w),log2(h)], ws=weights-thr
ws=bbs(:,5)-thr; w=bbs(:,3); h=bbs(:,4);
ps=[bbs(:,1)+w/2 bbs(:,2)+h/2 log2(w) log2(h)];

% find modes starting from each element, then merge nodes that are same
ps1=zeros(n,4); ws1=zeros(n,1); stopThr=1e-2;
for i=1:n, [ps1(i,:) ws1(i,:)]=nms1(i); end
[ps1,ws1] = nonMaxSuprList(ps1,ws1,stopThr*100,[],[],2);

% convert back to bbs format
w=pow2(ps1(:,3)); h=pow2(ps1(:,4));
bbs=[ps1(:,1)-w/2 ps1(:,2)-h/2 w h ws1+thr];

  function [p,w]=nms1(ind)
    % variable bandwith kernel (analytically defined)
    p=ps(ind,:); [n,m]=size(ps); onesN=ones(n,1);
    h = [pow2(ps(:,3)) pow2(ps(:,4)) onesN onesN];
    h = h .* radii(onesN,:); hInv=1./h;
    while(1)
      % compute (weighted) squared Euclidean distance to each neighbor
      d=(ps-p(onesN,:)).*hInv; d=d.*d; d=sum(d,2);
      % compute new mode
      wMask=ws.*exp(-d); wMask=wMask/sum(wMask); p1=wMask'*ps;
      % stopping criteria
      diff=sum(abs(p1-p))/m; p=p1; if(diff<stopThr), break; end
    end
    w = sum(ws.*wMask);
  end
end
