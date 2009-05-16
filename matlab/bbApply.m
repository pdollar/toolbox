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
% bbApply>convert bbApply>random bbApply>frMask bbApply>toMask
% bbApply>nms bbApply>nmsMax
%
% Piotr's Image&Video Toolbox      Version 2.30
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
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
% Draw single or multiple bbs to image (calls rectangle()).
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
[n,m]=size(bb); if(m==4), hs=zeros(1,n); else hs=zeros(1,2*n); end
for b=1:n
  hs(b) = rectangle( 'Position',bb(b,1:4), 'EdgeColor',col, ...
    'LineWidth',lw, 'LineStyle',ls, prop{:});
  if(m==4), continue; end
  hs(b+n)=text( bb(b,1), bb(b,2), num2str(bb(b,5),4), 'FontSize',10, ...
    'color','w', 'FontWeight','bold', 'VerticalAlignment','bottom' );
end
end

function [patches, bbs] = crop( I, bbs, padEl )
% Crop image regions from I encompassed by bbs.
%
% The only subtlety is that a pixel centered at location (i,j) would have a
% bb of [j-1/2,i-1/2,1,1].  The -1/2 is because pixels are located at
% integer locations. This is a Matlab convention, to confirm use:
%  im(rand(3)); bbApply('draw',[1.5 1.5 1 1],'g')
% If bb contains all integer entries cropping is straightforward. If
% entries are not integers, x=round(x+.499) is used, eg 1.2 actually goes
% to 2 (since it is closer to 1.5 then .5), and likewise for y.
%
% If ~isempty(padEl), image is padded so can extract full bb region (no
% actual padding is done, this is fast). Otherwise bb is intersected with
% the image bb prior to cropping. If padEl is a string ('circular',
% 'replicate', or 'symmetric'), uses padarray to do actual padding (slow).
%
% USAGE
%  [patches, bbs] = bbApply('crop',I,bb,[padEl])
%
% INPUTS
%  I        - image from which to crop patches
%  bbs      - bbs that indicate regions to crop
%  padEl    - [0] value to pad I or [] to indicate no padding (see above)
%
% OUTPUTS
%  patches  - [1xn] cell of cropped image regions
%  bbs      - actual integer-valued bbs used to crop
%
% EXAMPLE
%  I=imread('cameraman.tif'); bb=[-10 -10 100 100];
%  p1=bbApply('crop',I,bb); p2=bbApply('crop',I,bb,'replicate');
%  figure(1); im(I); figure(2); im(p1{1}); figure(3); im(p2{1});
%
% See also bbApply, ARRAYCROP, PADARRAY

% get padEl, bound bb to visible region if empty
if( nargin<3 ), padEl=0; end; h=size(I,1); w=size(I,2);
if(isempty(padEl)), bbs=intersect([.5 .5 w h],bbs); end
% crop each patch in turn
n=size(bbs,1); patches=cell(1,n);
for i=1:n, [patches{i},bbs(i,1:4)]=crop1(bbs(i,1:4)); end

  function [patch, bb] = crop1( bb )
    % crop single patch (use arrayCrop only if necessary)
    lcsS=round(bb([2 1])+.5-.001); lcsE=lcsS+round(bb([4 3]))-1;
    if( any(lcsS<1) || lcsE(1)>h || lcsE(2)>w )
      if( ischar(padEl) )
        pt=max(0,1-lcsS(1)); pb=max(0,lcsE(1)-h);
        pl=max(0,1-lcsS(2)); pr=max(0,lcsE(2)-w);
        lcsS=max(1,lcsS); lcsE=min(lcsE,[h w]);
        patch = I(lcsS(1):lcsE(1),lcsS(2):lcsE(2),:);
        patch = padarray(patch,[pt pl],padEl,'pre');
        patch = padarray(patch,[pb pr],padEl,'post');
      else
        if(ndims(I)==3); lcsS=[lcsS 1]; lcsE=[lcsE 3]; end
        patch = arrayCrop(I,lcsS,lcsE,padEl);
      end
    else
      patch = I(lcsS(1):lcsE(1),lcsS(2):lcsE(2),:);
    end
    bb = [lcsS([2 1]) lcsE([2 1])-lcsS([2 1])+1];
  end
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
bb(:,1) = randint2(n,1,[1,w-bbw+1]);
bb(:,2) = randint2(n,1,[1,h-bbh+1]);

end

function bbs = frMask( M, bbw, bbh )
% Convert binary mask to bbs, assuming `on' pixels indicate bb centers.
%
% USAGE
%  bbs = bbApply('frMask',M,bbw,bbh)
%
% INPUTS
%  M      - mask
%  bbw    - bb target width
%  bbh    - bb target height
%
% OUTPUTS
%  bbs    - bounding boxes
%
% EXAMPLE
%  w=20; h=10; bbw=5; bbh=8; M=uint8(rand(h,w)>0.95);
%  bbs=bbApply('frMask',M,bbw,bbh); M2=bbApply('toMask',bbs,w,h);
%  sum(abs(M(:)-M2(:)))
%
% See also bbApply, bbApply>toMask
pos=ind2sub2(size(M),find(M));
bbs=[fliplr(pos) pos]; bbs(:,3)=bbw; bbs(:,4)=bbh;
bbs(:,1)=bbs(:,1)-floor(bbw/2);
bbs(:,2)=bbs(:,2)-floor(bbh/2);
end

function M = toMask( bbs, w, h )
% Create binary mask encoding bb centers.
%
% USAGE
%  M = bbApply('toMask',bbs,w,h)
%
% INPUTS
%  bbs    - bounding boxes
%  w      - mask target width
%  h      - mask target height
%
% OUTPUTS
%  M      - hxw binary mask
%
% EXAMPLE
%
% See also bbApply, bbApply>frMask
M=zeros(h,w,'uint8'); cen=floor(getCenter(bbs));
M(sub2ind([h w],cen(:,2),cen(:,1)))=1;
end

function bbs = nms( bbs, thr, radii, maxn )
% Mean shift non-maximal suppression (nms) of bbs w variable width kernel.
%
% radii controls the amount of suppression. radii is a 4 element vector
% containing the radius for each dimension (x,y,w,h). Typically the first
% two elements should be the same, as should the last two. Distance between
% w/h are computed in log2 space (ie w and w*2 are 1 unit apart), and the
% radii should be set accordingly. radii should change depending on spatial
% and scale stride of bbs.
%
% Mean shift is O(n^2) where n is the number of bbs. To speed things up for
% large n, can divide data randomly into two sets, run nms on each, combine
% and run nms on the result. If maxn is specified, will split the set if
% n>maxn. Note that this is a heuristic and can change the results of nms.
%
% USAGE
%  bbs = bbApply('nms',bbs,thr,[radii],[maxn])
%
% INPUTS
%  bbs      - original bbs (must be of form [x y w h wt])
%  thr      - threshold below which to discard bbs
%  radii    - [.25 .25 1 1] supression radii (see above)
%  maxn     - [1000] if n>maxn split and run nms recursively (see above)
%
% OUTPUTS
%  bbs      - suppressed bbs
%
% EXAMPLE
%  bbs=[0 0 1 1 1; .1 .1 1 1 1.1; 2 2 1 1 1];
%  bbs1 = bbApply('nms',bbs,.1)
%
% See also bbApply, bbApply>nmsMax, nonMaxSuprList

% remove all bbs that fall below threshold
keep=bbs(:,5)>thr; bbs=bbs(keep,:); if(size(bbs,1)<=1), return; end;
if(nargin<3 || isempty(radii)), radii=[.15 .15 1 1]; end
if(nargin<4 || isempty(maxn)), maxn=1000; end

% position = [x+w/2,y+h/2,log2(w),log2(h)], ws=weights-thr
ws=bbs(:,5)-thr; w=bbs(:,3); h=bbs(:,4);
ps=[bbs(:,1)+w/2 bbs(:,2)+h/2 log2(w) log2(h)];

% perform actual nms
[ps,ws]=nms1(ps,ws,radii,maxn);

% convert back to bbs format and sort by weight
w=pow2(ps(:,3)); h=pow2(ps(:,4));
bbs=[ps(:,1)-w/2 ps(:,2)-h/2 w h ws+thr];
[ws,ord]=sort(ws,'descend'); bbs=bbs(ord,:);

  function [ps,ws]=nms1(ps,ws,radii,maxn)
    % if too many split in two randomly and recurse
    n=size(ps,1);
    if( n>maxn )
      ord=randperm(n); ps=ps(ord,:); ws=ws(ord); n2=floor(n/2); n3=n2+1;
      ps0=ps(1:n2,:); ws0=ws(1:n2,:); [ps0,ws0]=nms1(ps0,ws0,radii,maxn);
      ps1=ps(n3:n,:); ws1=ws(n3:n,:); [ps1,ws1]=nms1(ps1,ws1,radii,maxn);
      ps=[ps0; ps1]; ws=[ws0; ws1]; n0=n; n=size(ps,1);
      if(n<n0), [ps,ws]=nms1(ps,ws,radii,maxn); return; end
    end
    
    % find modes starting from each element, then merge nodes that are same
    ps1=zeros(n,4); ws1=zeros(n,1); stopThr=1e-2;
    for i=1:n, [ps1(i,:) ws1(i,:)]=nms2(i); end
    [ps,ws] = nonMaxSuprList(ps1,ws1,stopThr*100,[],[],2);
    
    function [p,w]=nms2(ind)
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
end

function bbs = nmsMax( bbs, thr, overlap, maxn )
% Non-maximal suppression (nms) of bbs using area of overlap criteria.
%
% For each pair of bounding boxes, if their overlap, defined by:
%  overlap(bb1,bb2) = area(intersect(bb1,bb2))/area(union(bb1,bb2))
% is greater than overlap, then the bb with the lower score is suppressed.
% In the Pascal critieria two bbs are considered a match if overlap>=.5;
%
% Although efficient, this function is O(n^2). To speed things up for large
% n, can divide data randomly into two sets, run nms on each, combine and
% run nms on the result. If maxn is specified, will split the set if
% n>maxn. Note that this is a heuristic and can change the results of nms.
%
% USAGE
%  bbs = bbApply('nmsMax',bbs,thr,[overlap],[maxn])
%
% INPUTS
%  bbs      - original bbs (must be of form [x y w h wt])
%  thr      - threshold below which to discard bbs
%  overlap  - [.5] area of overlap between bbs to be considered a match
%  maxn     - [1000] if n>maxn split and run nms recursively (see above)
%
% OUTPUTS
%  bbs      - suppressed bbs
%
% EXAMPLE
%  bbs=[0 0 1 1 1; .1 .1 1 1 1.1; 2 2 1 1 1];
%  bbs1 = bbApply('nmsMax',bbs,.5)
%
% See also bbApply, bbApply>nms

if(nargin<3 || isempty(overlap)), overlap=.5; end
if(nargin<4 || isempty(maxn)), maxn=1000; end
kp=bbs(:,5)>thr; bbs=bbs(kp,:); if(size(bbs,1)<=1), return; end;
assert(maxn>=2); assert(numel(overlap)==1);
bbs=nmsMax1(bbs,overlap,maxn); % perform actual nms

  function bbs = nmsMax1(bbs,overlap,maxn)
    % if too many split in two randomly and recurse
    if( size(bbs,1)>maxn )
      n=size(bbs,1); bbs=bbs(randperm(n),:); n2=floor(n/2);
      bbs0=nmsMax1(bbs(1:n2,:),overlap,maxn);
      bbs1=nmsMax1(bbs(n2+1:n,:),overlap,maxn);
      bbs=[bbs0; bbs1]; n0=n; n=size(bbs,1);
      if(n<n0), bbs=nmsMax1(bbs,overlap,maxn); return; end
    end
    
    % for each i suppress all j st j>i and overlap>.5
    [score,ord]=sort(bbs(:,5),'descend'); bbs=bbs(ord,:);
    n=size(bbs,1); kp=true(1,n); areas=bbs(:,3).*bbs(:,4);
    xs=bbs(:,1); xe=bbs(:,1)+bbs(:,3); ys=bbs(:,2); ye=bbs(:,2)+bbs(:,4);
    for i=1:n
      for j=i+find( kp(i+1:n) )
        iw=min(xe(i),xe(j))-max(xs(i),xs(j)); if(iw<=0), continue; end
        ih=min(ye(i),ye(j))-max(ys(i),ys(j)); if(ih<=0), continue; end
        o=iw*ih; o=o/(areas(i)+areas(j)-o); if(o>overlap), kp(j)=0; end
      end
    end
    bbs=bbs(kp,:);
  end

end
