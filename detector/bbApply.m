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
% The list of functions and help for each is given below. Also, help on
% individual subfunctions can be accessed by: "help bbApply>action".
%
% Compute area of bbs.
%   bb = bbApply( 'area', bb )
% Shift center of bbs.
%   bb = bbApply( 'shift', bb, xdel, ydel )
% Get center of bbs.
%   cen = bbApply( 'getCenter', bb )
% Get bb at intersection of bb1 and bb2 (may be empty).
%   bb = bbApply( 'intersect', bb1, bb2 )
% Get bb that is union of bb1 and bb2 (smallest bb containing both).
%   bb = bbApply( 'union', bb1, bb2 )
% Resize the bbs (without moving their centers).
%   bb = bbApply( 'resize', bb, hr, wr, [ar] )
% Fix bb aspect ratios (without moving the bb centers).
%   bbr = bbApply( 'squarify', bb, flag, [ar] )
% Draw single or multiple bbs to image (calls rectangle()).
%   hs = bbApply( 'draw', bb, [col], [lw], [ls], [prop], [ids] )
% Embed single or multiple bbs directly into image.
%  I = bbApply( 'embed', I, bb, [varargin] )
% Crop image regions from I encompassed by bbs.
%   [patches, bbs] = bbApply('crop',I,bb,[padEl],[dims])
% Convert bb relative to absolute coordinates and vice-versa.
%   bb = bbApply( 'convert', bb, bbRef, isAbs )
% Randomly generate bbs that fall in a specified region.
%   bbs =  bbApply( 'random', pRandom )
% Convert weighted mask to bbs.
%   bbs = bbApply('frMask',M,bbw,bbh,[thr])
% Create weighted mask encoding bb centers (or extent).
%   M = bbApply('toMask',bbs,w,h,[fill],[bgrd])
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
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.30
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

%#ok<*DEFNU>
varargout = cell(1,max(1,nargout));
[varargout{:}] = feval(action,varargin{:});
end

function a = area( bb )
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

function bb = resize( bb, hr, wr, ar )
% Resize the bbs (without moving their centers).
%
% If wr>0 or hr>0, the w/h of each bb is adjusted in the following order:
%  if(hr~=0), h=h*hr; end
%  if(wr~=0), w=w*wr; end
%  if(hr==0), h=w/ar; end
%  if(wr==0), w=h*ar; end
% Only one of hr/wr may be set to 0, and then only if ar>0. If, however,
% hr=wr=0 and ar>0 then resizes bbs such that areas and centers are
% preserved but aspect ratio becomes ar.
%
% USAGE
%  bb = bbApply( 'resize', bb, hr, wr, [ar] )
%
% INPUTS
%  bb     - [nx4] original bbs
%  hr     - ratio by which to multiply height (or 0)
%  wr     - ratio by which to multiply width (or 0)
%  ar     - [0] target aspect ratio (used only if hr=0 or wr=0)
%
% OUTPUT
%  bb    - [nx4] the output resized bbs
%
% EXAMPLE
%  bb = bbApply('resize',[0 0 1 1],1.2,0,.5) % h'=1.2*h; w'=h'/2;
%
% See also bbApply, bbApply>squarify
if(nargin<4), ar=0; end; assert(size(bb,2)>=4);
assert((hr>0&&wr>0)||ar>0);
% preserve area and center, set aspect ratio
if(hr==0 && wr==0), a=sqrt(bb(:,3).*bb(:,4)); ar=sqrt(ar);
  d=a*ar-bb(:,3); bb(:,1)=bb(:,1)-d/2; bb(:,3)=bb(:,3)+d;
  d=a/ar-bb(:,4); bb(:,2)=bb(:,2)-d/2; bb(:,4)=bb(:,4)+d; return;
end
% possibly adjust h/w based on hr/wr
if(hr~=0), d=(hr-1)*bb(:,4); bb(:,2)=bb(:,2)-d/2; bb(:,4)=bb(:,4)+d; end
if(wr~=0), d=(wr-1)*bb(:,3); bb(:,1)=bb(:,1)-d/2; bb(:,3)=bb(:,3)+d; end
% possibly adjust h/w based on ar and NEW h/w
if(~hr), d=bb(:,3)/ar-bb(:,4); bb(:,2)=bb(:,2)-d/2; bb(:,4)=bb(:,4)+d; end
if(~wr), d=bb(:,4)*ar-bb(:,3); bb(:,1)=bb(:,1)-d/2; bb(:,3)=bb(:,3)+d; end
end

function bbr = squarify( bb, flag, ar )
% Fix bb aspect ratios (without moving the bb centers).
%
% The w or h of each bb is adjusted so that w/h=ar.
% The parameter flag controls whether w or h should change:
%  flag==0: expand bb to given ar
%  flag==1: shrink bb to given ar
%  flag==2: use original w, alter h
%  flag==3: use original h, alter w
%  flag==4: preserve area, alter w and h
% If ar==1 (the default), always converts bb to a square, hence the name.
%
% USAGE
%  bbr = bbApply( 'squarify', bb, flag, [ar] )
%
% INPUTS
%  bb     - [nx4] original bbs
%  flag   - controls whether w or h should change
%  ar     - [1] desired aspect ratio
%
% OUTPUT
%  bbr    - the output 'squarified' bbs
%
% EXAMPLE
%  bbr = bbApply('squarify',[0 0 1 2],0)
%
% See also bbApply, bbApply>resize
if(nargin<3 || isempty(ar)), ar=1; end; bbr=bb;
if(flag==4), bbr=resize(bb,0,0,ar); return; end
for i=1:size(bb,1), p=bb(i,1:4);
  usew = (flag==0 && p(3)>p(4)*ar) || (flag==1 && p(3)<p(4)*ar) || flag==2;
  if(usew), p=resize(p,0,1,ar); else p=resize(p,1,0,ar); end; bbr(i,1:4)=p;
end
end

function hs = draw( bb, col, lw, ls, prop, ids )
% Draw single or multiple bbs to image (calls rectangle()).
%
% To draw bbs aligned with pixel boundaries, subtract .5 from the x and y
% coordinates (since pixel centers are located at integer locations).
%
% USAGE
%  hs = bbApply( 'draw', bb, [col], [lw], [ls], [prop], [ids] )
%
% INPUTS
%  bb     - [nx4] standard bbs or [nx5] weighted bbs
%  col    - ['g'] color or [kx1] array of colors
%  lw     - [2] LineWidth for rectangle
%  ls     - ['-'] LineStyle for rectangle
%  prop   - [] other properties for rectangle
%  ids    - [ones(1,n)] id in [1,k] for each bb into colors array
%
% OUTPUT
%  hs     - [nx1] handles to drawn rectangles (and labels)
%
% EXAMPLE
%  im(rand(3)); bbApply('draw',[1.5 1.5 1 1 .5],'g');
%
% See also bbApply, bbApply>embed, rectangle
[n,m]=size(bb); if(n==0), hs=[]; return; end
if(nargin<2 || isempty(col)), col=[]; end
if(nargin<3 || isempty(lw)), lw=2; end
if(nargin<4 || isempty(ls)), ls='-'; end
if(nargin<5 || isempty(prop)), prop={}; end
if(nargin<6 || isempty(ids)), ids=ones(1,n); end
% prepare display properties
prop=['LineWidth' lw 'LineStyle' ls prop 'EdgeColor'];
tProp={'FontSize',10,'color','w','FontWeight','bold',...
  'VerticalAlignment','bottom'}; k=max(ids);
if(isempty(col)), if(k==1), col='g'; else col=hsv(k); end; end
if(size(col,1)<k), ids=ones(1,n); end; hs=zeros(1,n);
% draw rectangles and optionally labels
for b=1:n, hs(b)=rectangle('Position',bb(b,1:4),prop{:},col(ids(b),:)); end
if(m==4), return; end; hs=[hs zeros(1,n)]; bb=double(bb);
for b=1:n, hs(b+n)=text(bb(b,1),bb(b,2),num2str(bb(b,5),4),tProp{:}); end
end

function I = embed( I, bb, varargin )
% Embed single or multiple bbs directly into image.
%
% USAGE
%  I = bbApply( 'embed', I, bb, varargin )
%
% INPUTS
%  I      - input image
%  bb     - [nx4] or [nx5] input bbs
%  varargin   - additional params (struct or name/value pairs)
%    .col       - [0 255 0] color for rectangle or nx3 array of colors
%    .lw        - [3] width for rectangle in pixels
%    .fh        - [35] font height (if displaying weight), may be 0
%    .fcol      - [255 0 0] font color or nx3 array of colors
%
% OUTPUT
%  I      - output image
%
% EXAMPLE
%  I=imResample(imread('cameraman.tif'),2); bb=[200 70 70 90 0.25];
%  J=bbApply('embed',I,bb,'col',[0 0 255],'lw',8,'fh',30); figure(1); im(J)
%  K=bbApply('embed',J,bb,'col',[0 255 0],'lw',2,'fh',30); figure(2); im(K)
%
% See also bbApply, bbApply>draw, char2img

% get additional parameters
dfs={'col',[0 255 0],'lw',3,'fh',35,'fcol',[255 0 0]};
[col,lw,fh,fcol]=getPrmDflt(varargin,dfs,1);
n=size(bb,1); bb(:,1:4)=round(bb(:,1:4));
if(size(col,1)==1), col=col(ones(1,n),:); end
if(size(fcol,1)==1), fcol=fcol(ones(1,n),:); end
if( ismatrix(I) ), I=I(:,:,[1 1 1]); end
% embed each bb
x0=bb(:,1); x1=x0+bb(:,3)-1; y0=bb(:,2); y1=y0+bb(:,4)-1;
j0=floor((lw-1)/2); j1=ceil((lw-1)/2); h=size(I,1); w=size(I,2);
x00=max(1,x0-j0); x01=min(x0+j1,w); x10=max(1,x1-j0); x11=min(x1+j1,w);
y00=max(1,y0-j0); y01=min(y0+j1,h); y10=max(1,y1-j0); y11=min(y1+j1,h);
for b=1:n
  for c=1:3, I([y00(b):y01(b) y10(b):y11(b)],x00(b):x11(b),c)=col(b,c); end
  for c=1:3, I(y00(b):y11(b),[x00(b):x01(b) x10(b):x11(b)],c)=col(b,c); end
end
% embed text displaying bb score (inside upper-left bb corner)
if(size(bb,2)<5 || fh==0), return; end
bb(:,1:4)=intersect(bb(:,1:4),[1 1 w h]);
for b=1:n
  M=char2img(sprintf('%.4g',bb(b,5)),fh); M=M{1}==0; [h,w]=size(M);
  y0=bb(b,2); y1=y0+h-1; x0=bb(b,1); x1=x0+w-1;
  if( x0>=1 && y0>=1 && x1<=size(I,2) && y1<=size(I,1))
    Ir=I(y0:y1,x0:x1,1); Ig=I(y0:y1,x0:x1,2); Ib=I(y0:y1,x0:x1,3);
    Ir(M)=fcol(b,1); Ig(M)=fcol(b,2); Ib(M)=fcol(b,3);
    I(y0:y1,x0:x1,:)=cat(3,Ir,Ig,Ib);
  end
end
end

function [patches, bbs] = crop( I, bbs, padEl, dims )
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
%  [patches, bbs] = bbApply('crop',I,bb,[padEl],[dims])
%
% INPUTS
%  I        - image from which to crop patches
%  bbs      - bbs that indicate regions to crop
%  padEl    - [0] value to pad I or [] to indicate no padding (see above)
%  dims     - [] if specified resize each cropped patch to [w h]
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
% See also bbApply, ARRAYCROP, PADARRAY, IMRESAMPLE

% get padEl, bound bb to visible region if empty
if( nargin<3 ), padEl=0; end; h=size(I,1); w=size(I,2);
if( nargin<4 ), dims=[]; end;
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
        lcsS1=max(1,lcsS); lcsE1=min(lcsE,[h w]);
        patch = I(lcsS1(1):lcsE1(1),lcsS1(2):lcsE1(2),:);
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
    if(~isempty(dims)), patch=imResample(patch,[dims(2),dims(1)]); end
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

function bbs = random( varargin )
% Randomly generate bbs that fall in a specified region.
%
% The vector dims defines the region in which bbs are generated. Specify
% dims=[height width] to generate bbs=[x y w h] such that: 1<=x<=width,
% 1<=y<=height, x+w-1<=width, y+h-1<=height. The biggest bb generated can
% be bb=[1 1 width height]. If dims is a three element vector the third
% coordinate is the depth, in this case bbs=[x y w h d] where 1<=d<=depth.
%
% A number of constraints can be specified that control the size and other
% characteristics of the generated bbs. Note that if incompatible
% constraints are specified (e.g. if the maximum width and height are both
% 5 while the minimum area is 100) no bbs will be generated. More
% generally, if fewer than n bbs are generated a warning is displayed.
%
% USAGE
%  bbs =  bbApply( 'random', pRandom )
%
% INPUTS
%  pRandom    - parameters (struct or name/value pairs)
%   .n          - ['REQ'] number of bbs to generate
%   .dims       - ['REQ'] region in which to generate bbs [height,width]
%   .wRng       - [1 inf] range for width of bbs (or scalar value)
%   .hRng       - [1 inf] range for height of bbs (or scalar value)
%   .aRng       - [1 inf] range for area of bbs
%   .arRng      - [0 inf] range for aspect ratio (width/height) of bbs
%   .unique     - [1] if true generate unique bbs
%   .maxOverlap - [1] max overlap (intersection/union) between bbs
%   .maxIter    - [100] max iterations to go w/o changes before giving up
%   .show       - [0] if true show sample generated bbs
%
% OUTPUTS
%  bbs        - [nx4] array of randomly generated integer bbs
%
% EXAMPLE
%  bbs=bbApply('random','n',50,'dims',[20 20],'arRng',[.5 .5],'show',1);
%
% See also bbApply

% get parameters
rng=[1 inf]; dfs={ 'n','REQ', 'dims','REQ', 'wRng',rng, 'hRng',rng, ...
  'aRng',rng, 'arRng',[0 inf], 'unique',1, 'maxOverlap',1, ...
  'maxIter',100, 'show',0 };
[n,dims,wRng,hRng,aRng,arRng,uniqueOnly,maxOverlap,maxIter,show] ...
  = getPrmDflt(varargin,dfs,1);
if(length(hRng)==1), hRng=[hRng hRng]; end
if(length(wRng)==1), wRng=[wRng wRng]; end
if(length(dims)==3), d=5; else d=4; end

% generate random bbs satisfying constraints
bbs=zeros(0,d); ids=zeros(0,1); n1=min(n*10,1000);
M=max(dims)+1; M=M.^(0:d-1); iter=0; k=0;
tid=ticStatus('generating random bbs',1,2);
while( k<n && iter<maxIter )
  ys=1+floor(rand(2,n1)*dims(1)); ys0=min(ys); ys1=max(ys); hs=ys1-ys0+1;
  xs=1+floor(rand(2,n1)*dims(2)); xs0=min(xs); xs1=max(xs); ws=xs1-xs0+1;
  if(d==5), ds=1+floor(rand(1,n1)*dims(3)); else ds=zeros(0,n1); end
  if(arRng(1)==arRng(2)), ws=hs.*arRng(1); end
  ars=ws./hs; ws=round(ws); xs1=xs0+ws-1; as=ws.*hs;
  kp = ys0>0 & xs0>0 & ys1<=dims(1) & xs1<=dims(2) & ...
    hs>=hRng(1) & hs<=hRng(2) & ws>=wRng(1) & ws<=wRng(2) & ...
    as>=aRng(1) & as<=aRng(2) & ars>=arRng(1) & ars<=arRng(2);
  bbs1=[xs0' ys0' ws' hs' ds']; bbs1=bbs1(kp,:);
  k0=k; bbs=[bbs; bbs1]; k=size(bbs,1); %#ok<AGROW>
  if( maxOverlap<1 && k ), bbs=bbs(1:k0,:);
    for j=1:size(bbs1,1), bbs0=bbs; bb=bbs1(j,:);
      if(d==5), bbs=bbs(bbs(:,5)==bb(5),:); end
      if(isempty(bbs)), bbs=[bbs0; bb]; continue; end
      ws1=min(bbs(:,1)+bbs(:,3),bb(1)+bb(3))-max(bbs(:,1),bb(1));
      hs1=min(bbs(:,2)+bbs(:,4),bb(2)+bb(4))-max(bbs(:,2),bb(2));
      o=max(0,ws1).*max(0,hs1); o=o./(bbs(:,3).*bbs(:,4)+bb(3).*bb(4)-o);
      if(max(o)<=maxOverlap), bbs=[bbs0; bb]; else bbs=bbs0; end
    end
  elseif( uniqueOnly && k )
    ids=[ids; sum(bbs1.*M(ones(1,size(bbs1,1)),:),2)]; %#ok<AGROW>
    [ids,o]=sort(ids); bbs=bbs(o,:); kp=[ids(1:end-1)~=ids(2:end); true];
    bbs=bbs(kp,:); ids=ids(kp,:);
  end
  k=size(bbs,1); if(k0==k), iter=iter+1; else iter=0; end
  if(k>n), bbs=bbs(randSample(k,n),:); k=n; end;
  tocStatus(tid,max(k/n,iter/maxIter));
end
if( k<n ), warning('only generated %i of %i bbs',k,n); n=k; end %#ok<WNTAG>

% optionally display a few bbs
if( show )
  k=8; figure(show); im(zeros(dims)); cs=uniqueColors(1,k,0,0);
  if(n>k), bbs1=bbs(randsample(n,k),:); else bbs1=bbs; end
  bbs1(:,1:2)=bbs1(:,1:2)-.5;
  for i=1:min(k,n), rectangle('Position',bbs1(i,:),...
      'EdgeColor',cs(i,:),'LineStyle','--'); end
end

end

function bbs = frMask( M, bbw, bbh, thr )
% Convert weighted mask to bbs.
%
% Pixels in mask above given threshold (thr) indicate bb centers.
%
% USAGE
%  bbs = bbApply('frMask',M,bbw,bbh,[thr])
%
% INPUTS
%  M      - mask
%  bbw    - bb target width
%  bbh    - bb target height
%  thr    - [0] mask threshold
%
% OUTPUTS
%  bbs    - bounding boxes
%
% EXAMPLE
%  w=20; h=10; bbw=5; bbh=8; M=double(rand(h,w)); M(M<.95)=0;
%  bbs=bbApply('frMask',M,bbw,bbh); M2=bbApply('toMask',bbs,w,h);
%  sum(abs(M(:)-M2(:)))
%
% See also bbApply, bbApply>toMask
if(nargin<4), thr=0; end
ids=find(M>thr); ids=ids(:); h=size(M,1);
if(isempty(ids)), bbs=zeros(0,5); return; end
xs=floor((ids-1)/h); ys=ids-xs*h; xs=xs+1;
bbs=[xs-floor(bbw/2) ys-floor(bbh/2)];
bbs(:,3)=bbw; bbs(:,4)=bbh; bbs(:,5)=M(ids);
end

function M = toMask( bbs, w, h, fill, bgrd )
% Create weighted mask encoding bb centers (or extent).
%
% USAGE
%  M = bbApply('toMask',bbs,w,h,[fill],[bgrd])
%
% INPUTS
%  bbs    - bounding boxes
%  w      - mask target width
%  h      - mask target height
%  fill   - [0] if 1 encodes extent of bbs
%  bgrd   - [0] default value for background pixels
%
% OUTPUTS
%  M      - hxw mask
%
% EXAMPLE
%
% See also bbApply, bbApply>frMask
if(nargin<4||isempty(fill)), fill=0; end
if(nargin<5||isempty(bgrd)), bgrd=0; end
if(size(bbs,2)==4), bbs(:,5)=1; end
M=zeros(h,w); B=true(h,w); n=size(bbs,1);
if( fill==0 )
  p=floor(getCenter(bbs)); p=sub2ind([h w],p(:,2),p(:,1));
  for i=1:n, M(p(i))=M(p(i))+bbs(i,5); end
  if(bgrd~=0), B(p)=0; end
else
  bbs=[intersect(round(bbs),[1 1 w h]) bbs(:,5)]; n=size(bbs,1);
  x0=bbs(:,1); x1=x0+bbs(:,3)-1; y0=bbs(:,2); y1=y0+bbs(:,4)-1;
  for i=1:n, y=y0(i):y1(i); x=x0(i):x1(i);
    M(y,x)=M(y,x)+bbs(i,5); B(y,x)=0; end
end
if(bgrd~=0), M(B)=bgrd; end
end
