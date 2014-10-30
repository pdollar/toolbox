function [hPatch,api] = imRectRot( varargin )
% Create a draggable, resizable, rotatable rectangle or ellipse.
%
% The 'ellipse' param determines if the displayed object is a rectangle or
% ellipse. The object is identical in both cases, only the display changes.
% The created object may be queried or controlled programatically by using
% the returned api.
%
% The 'rotate' param determines overall behavior of the created object. If
% rotate=0, the resulting object (rect or ellipse) is axis aligned. In
% terms of the graphical interface it is identical to Matlab's imrect (can
% drag by clicking in interior or resize by clicking on edges), although it
% is much less cpu intensive. If rotate>0, the resulting object is
% rotatable. In addition to the interface for a non-rotatable object, four
% control points are present, one at the center of each edge. Three of
% these have color given by the 'color' flag, the last has color 'colorc'.
% The odd colored control point is used to display orientation. Dragging
% this control point or the one opposite changes orientation, dragging the
% remaining two resizes the object symmetrically. Finally, when creating a
% rotatable object, the first drag determines the major axes (height) of
% the object, with the width set to height*rotate (hence the rotate param
% also determines aspect ratio of newly created objects). Using this
% control scheme, an object can be naturally specified with two drags: the
% first is used to draw the major axes, the second to adjust the width.
%
% Position is represented by [x y w h theta], where [x,y] give the top/left
% corner of the rect PRIOR to rotation, [w,h] are the width and height, and
% theta is the angle in degrees. The final rect is given by first placing
% the rect at [x,y], then rotating it by theta around it's center. The
% advantage of this is that if theta=0, the first four elements are
% identical to the standard rect representation. The disadvantage is that
% [x,y] need not lie in the interior of the rect after rotation.
%
% USAGE
%  [h,api] = imRectRot( varargin )
%
% INPUTS
%  varargin   - parameters (struct or name/value pairs)
%   .hParent    - [gca] object parent, typically an axes object
%   .ellipse    - [0] if true display ellipse otherwise display rectangle
%   .rotate     - [1] determines if object is axis aligned
%   .pos        - [] initial pos vector [x y w h theta] or [] or [x y]
%   .lims       - [] rectangle defining valid region for object placement
%   .showLims   - [0] draw rectangle representing lims
%   .color      - ['g'] color for the displayed object
%   .colorc     - ['b'] color for the control point displaying orientation
%   .lw         - [2] 'LineWidth' property for the displayed object
%   .ls         - ['-'] 'LineStyle' property for the displayed object
%   .cross      - [0] if 1 show diagonal, if 2 show cross
%
% OUTPUTS
%  h          - handle used to delete object
%  api        - interface allowing access to created object
%  .getPos()       - get position - returns 5 elt pos
%  .setPos(pos)    - set position (while respecting constraints)
%  .setPosLock(b)  - if lock set (b==true), object cannot change
%  .setSizLock(b)  - if lock set (b==true), object cannot change size
%  .setDrgLock(b)  - if lock set (b==true), object cannot be dragged
%  .setSidLock(lk) - [4x1] set locks for each side (tp/rt/bt/lf)
%  .setPosChnCb(f) - whenever pos changes (even slightly), calls f(pos)
%  .setPosSetCb(f) - whenever pos finished changing, calls f(pos)
%  .uistack(...)   - calls 'uistack( [objectHandles], ... )', see uistack
%  .setStyle(...)  - set line style (ls), width (lw), color and colorc
%
% EXAMPLE - interactively place simple axis aligned rectangle
%  figure(1), imshow peppers.png;
%  [h,api]=imRectRot('rotate',0);
%  api.setPosChnCb( @(pos) disp(num2str(pos)) );
%
% EXAMPLE - create rotatable ellpise that falls inside image
%  figure(1); I=imread('cameraman.tif'); imshow(I); siz=size(I);
%  [h,api]=imRectRot('pos',[60 60 40 40 45],'lims',[1 1 siz(1:2)-2 0],...
%    'showLims',1,'ellipse',1,'rotate',1,'color','w','colorc','y'  );
%  api.setPosSetCb( @(pos) disp(num2str(pos)) );
%
% See also IMRECT, RECTANGLE, PATCH
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.51
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% global variables (shared by all functions below)
[hParent,pos,lims,rotate,crXs,crYs,posChnCb,posSetCb,posLock,sizLock,...
  dgrLock,sidLock,hAx,hFig,hPatch,hBnds,hCntr,hEll] = deal([]);

% intitialize
intitialize( varargin{:} );

% create api
api = struct('getPos',@getPos, 'setPos',@setPos, 'uistack',@uistack1, ...
  'setPosChnCb',@setPosChnCb, 'setPosSetCb',@setPosSetCb, ...
  'setPosLock',@setPosLock, 'setSizLock',@setSizLock, ...
  'setDrgLock',@setDrgLock, 'setSidLock',@setSidLock, ...
  'setStyle',@setStyle );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function intitialize( varargin )
    % get default arguments
    dfs={'hParent',gca, 'ellipse',0, 'rotate',1, 'pos',[], 'lims',[], ...
      'showLims',0,'color','g','colorc','b','lw',2,'ls','-','cross',0};
    [hParent,ellipse,rotate,pos,lims,showLims,color,colorc,lw,ls,cross]=...
      getPrmDflt(varargin,dfs,1);
    if(numel(pos)==4), pos=[pos(:)' 0]; end
    if(numel(lims)==4), lims=[lims(:)' 0]; end
    
    % get figure and axes handles
    hAx = ancestor(hParent,'axes'); assert(~isempty(hAx));
    hFig = ancestor(hAx,'figure'); assert(~isempty(hFig));
    set( hFig, 'CurrentAxes', hAx );
    
    % optionally display limits
    if(showLims && ~isempty(lims)), [~,xs,ys]=rectToCorners(lims);
      for j=1:4, ids=mod([j-1 j],4)+1; line(xs(ids),ys(ids)); end
    end
    
    % create objects for rectangle display/interface
    if( ellipse ), linePrp={'color',[.7 .7 .7],'LineWidth',1};
    else linePrp={'color',color,'LineWidth',lw,'LineStyle',ls}; end
    if(isempty(pos)); vis='off'; else vis='on'; end;
    assert(cross==0 || cross==1 || cross==2);
    for i=1:4+cross, hBnds(i)=line(linePrp{:},'Visible',vis); end
    
    % create transparent patch to capture clicks in object interior
    hPatch=patch('FaceColor','none','EdgeColor','none');
    
    % create objects for ellipse display/interface
    if( ellipse )
      ellPrp={'color',color,'LineWidth',lw,'LineStyle',ls};
      ts=linspace(-180,180,50); crXs=cosd(ts); crYs=sind(ts);
      hold on; hEll=plot(crXs,crYs,ellPrp{:},'Visible',vis); hold off;
    end
    
    % create objects for rotation display/interface
    if( rotate )
      circPrp={'Curvature',[1 1],'FaceColor',color,'EdgeColor',color};
      for i=1:4, hCntr(i)=rectangle(circPrp{:},'Visible',vis); end
      set(hCntr(1),'LineWidth',lw,'FaceColor',colorc);
    end
    
    % set callbacks on all objects
    hs=[hPatch hBnds hCntr hEll];
    set(hs,'ButtonDownFcn',{@btnDwn,0},'DeleteFcn',@deleteFcn);
    
    % set or query initial position
    posLock=0; sizLock=0; dgrLock=0; sidLock=[0 0 0 0];
    if(length(pos)==5), setPos(pos,1); else
      btnDwn([],[],-1); waitfor(hFig,'WindowButtonUpFcn','');
    end
  end

  function [pc,rs,R] = rectInfo( pos0 )
    % return rectangle center, radii, and rotation matrix
    t=pos0(5); c=cosd(t); s=sind(t); R=[c -s; s c];
    rs=pos0(3:4)/2; pc=pos0(1:2)+rs;
  end

  function [pts,xs,ys,pc] = rectToCorners( pos0 )
    % return 4 rect corners in real world coords
    [pc,rs,R]=rectInfo( pos0 );
    x0=-rs(1); x1=rs(1); y0=-rs(2); y1=rs(2);
    pts=[x0 y0; x1 y0; x1 y1; x0 y1]*R'+pc(ones(4,1),:);
    xs=pts(:,1); ys=pts(:,2);
  end

  function pos1 = cornersToRect( pos0, x0, y0, x1, y1 )
    % compute pos from 4 corners given in rect coords
    [pc,~,R] = rectInfo( pos0 );
    p0=[x0 y0]*R'+pc; p1=[x1 y1]*R'+pc;
    pc=(p1+p0)/2; p0=(p0-pc)*R; p1=(p1-pc)*R;
    pos1 = [pc+p0 p1-p0 pos0(5)];
  end

  function setPos( posNew, ignoreLims )
    if(isempty(hBnds) || isempty(hPatch)); return; end; L=lims;
    % if corners fall outside lims don't use posNew
    if( ~isempty(L) && (nargin<2 || ~ignoreLims) )
      if( posNew(5)==lims(5) )
        % lims and posNew at same orient (do everything in rect coords)
        [pc,rs,R]=rectInfo(posNew); p0=-rs; p1=rs;
        pts=(rectToCorners(L)-pc(ones(4,1),:))*R;
        L0=[pts(1,1) pts(1,2)]; L1=[pts(2,1) pts(3,2)];
        p0=min(max(p0,L0),L1); p1=max(min(p1,L1),p0);
        posNew=cornersToRect(posNew,p0(1),p0(2),p1(1),p1(2));
      else
        % lims and posNew at diff orient (do everything in lims coords)
        [pc,rs,R]=rectInfo(L); p0=-rs; p1=rs;
        p=(rectToCorners(posNew)-pc(ones(4,1),:))*R; xs=p(:,1); ys=p(:,2);
        valid=[xs>=p0(1) xs<=p1(1) ys>=p0(2) ys<=p1(2)];
        if(~all(valid(:))), return; end
      end
    end
    % create invisible patch to captures key presses
    pos=posNew; [~,xs,ys]=rectToCorners(pos);
    vert=[xs ys ones(4,1)]; face=1:4;
    set(hPatch,'Faces',face,'Vertices',vert);
    % draw ellipse
    if(~isempty(hEll)), [pc,rs]=rectInfo(posNew); th=pos(5);
      xsEll = rs(1)*crXs*cosd(-th)+rs(2)*crYs*sind(-th)+pc(1);
      ysEll = rs(2)*crYs*cosd(-th)-rs(1)*crXs*sind(-th)+pc(2);
      set(hEll,'XData',xsEll,'YData',ysEll);
    end
    % draw rectangle boundaries and control circles
    r=axisUnitsPerCentimeter();
    r=max( r*.1, min(mean(pos(3:4))/10,r) );
    for i=1:length(hBnds), ids=mod([i-1 i],4)+1;
      if(i==5), ids=[1 3]; elseif(i==6), ids=[2 4]; end
      set(hBnds(i),'Xdata',xs(ids),'Ydata',ys(ids));
      if(rotate && i<=4), x=mean(xs(ids)); y=mean(ys(ids));
        set(hCntr(i),'Position',[x-r y-r 2*r 2*r]);
      end
    end
  end

  function pnt = getCurPnt()
    pnt=get(hAx,'CurrentPoint'); pnt=pnt([1 3]);
  end

  function d = axisUnitsPerCentimeter()
    % approximage absolute axes size
    units=get(hAx,'units'); set(hAx,'units','centimeters');
    cm=get(hAx,'Position'); cm=max(cm(3:4));
    set(hAx,'units',units);
    % axes size in axes units
    xLim=get(gca,'xLim'); yLim=get(gca,'yLim');
    sizInner = max([xLim(2)-xLim(1),yLim(2)-yLim(1)]);
    % units per centimeter
    d = sizInner/cm;
  end

  function [side,cursor,flag] = getSide( pnt0 )
    % get pnt in coordintates of center of rectangle
    [pc,rs,R]=rectInfo(pos); pnt=(pnt0-pc)*R; th=pos(5);
    % side(i) -1=lf/tp bnd; 0=interior; +1:rt/bt bnd; 2=center
    t = axisUnitsPerCentimeter(); side=[0 0]; flag=0;
    t = max( t*.1, min(mean(pos(3:4))/5,t) );
    for i=1:2
      ti = min(t,rs(i)/3);
      if( abs(pnt(i))<ti && rotate ), side(i)=2; % near center
      elseif( pnt(i)<-rs(i)+ti ), side(i)=-1; % near lf/tp boundary
      elseif( pnt(i)>rs(i)-ti), side(i)=1; % near rt/bt boundary
      end
    end
    % flag: -1: none, 0=resize; 1=drag; 2=rotate; 3=symmetric-resize
    if((sidLock(4)&&side(1)==-1)||(sidLock(2)&&side(1)==1)), side(1)=0; end
    if((sidLock(1)&&side(2)==-1)||(sidLock(3)&&side(2)==1)), side(2)=0; end
    if(any(side==0) || all(side==2)), side(side==2)=0; end
    if(side(1)==2), flag=2; cursor='crosshair'; return; end
    if(sizLock), side=[0 0]; end
    if(all(side==0) && dgrLock), cursor=''; flag=-1; return; end
    if(all(side==0)), flag=1; side=pnt0; cursor='fleur'; return; end
    if(side(2)==2), flag=3; side(2)=0; end
    % select cursor based on position
    cs={'bottom','botr','right','topr','top','topl','left','botl'};
    a=mod(round((atan2(side(1),side(2))/pi-th/180)*4),8)+1; cursor=cs{a};
  end

  function btnDwn( h, evnt, flag ) %#ok<INUSL>
    if(isempty(hBnds) || isempty(hPatch) || posLock), return; end
    if( flag==-1 ) % create new rectangle
      if(isempty(pos)), anchor=ginput(1); else anchor=pos(1:2); end
      pos=[anchor 1 1 0]; setPos(pos);
      set([hBnds hCntr hEll],'Visible','on');
      if(rotate), cursor='crosshair'; flag=4;
      else cursor='botr'; flag=0; end
    else % resize, rotate or drag rectangle
      pnt=getCurPnt(); [anchor,cursor,flag]=getSide( pnt );
      if(flag==-1), return; end
    end
    set( hFig, 'Pointer', cursor );
    set( hFig, 'WindowButtonMotionFcn',{@drag,flag,anchor,pos} );
    set( hFig, 'WindowButtonUpFcn', @stopDrag );
  end

  function drag( h, evnt, flag, anchor, pos0 ) %#ok<INUSL>
    if(isempty(hBnds) || isempty(hPatch)); return; end;
    pnt = getCurPnt();
    if( flag==1 ) % shift rectangle by del=pnt-anchor
      setPos( [pos0(1:2)+(pnt-anchor) pos0(3:5)] );
    elseif( flag==0 || flag==3 ) % resize in rectangle coordinate frame
      [pc,rs,R]=rectInfo(pos0); p0=-rs; p1=rs; pnt=(pnt-pc)*R;
      if( flag==3 ), p0(1)=-pnt(1); p1(1)=pnt(1); else
        for i=1:2, if(anchor(i)>0), p1(i)=pnt(i); end; end
        for i=1:2, if(anchor(i)<0), p0(i)=pnt(i); end; end
      end; p0a=min(p0,p1); p1=max(p0,p1); p0=p0a;
      setPos(cornersToRect(pos0,p0(1),p0(2),p1(1),p1(2)));
    elseif( flag==2 || flag==4 ) % rotate rectangle
      [~,xs,ys]=rectToCorners(pos0);
      if(anchor(2)==-1), ids=[3 4]; else ids=[1 2]; end
      p0=mean([xs(ids) ys(ids)]); pc=(p0+pnt)/2;
      if(anchor(2)==-1), d=pnt-p0; else d=p0-pnt; end
      h=sqrt(sum(d.^2)); th=atan2(d(1),-d(2))/pi*180;
      if(flag==2), w=pos(3); else w=h*rotate; end
      setPos([pc(1)-w/2 pc(2)-h/2 w h th]);
    end
    if(~isempty(posChnCb)); posChnCb(pos); end;
    drawnow; % update display
  end

  function stopDrag( h, evnt ) %#ok<INUSD>
    set( hFig, 'WindowButtonMotionFcn','');
    set( hFig, 'WindowButtonUpFcn','');
    set( hFig, 'Pointer', 'arrow' );
    if(~isempty(posSetCb)); posSetCb(pos); end;
  end

  function deleteFcn( h, evnt ) %#ok<INUSD>
    [posChnCb,posSetCb]=deal([]); hs=[hPatch hBnds hCntr hEll];
    for i=1:length(hs), if(ishandle(hs(i))); delete(hs(i)); end; end
    [hBnds,hPatch,hCntr,hEll]=deal([]);
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function pos0 = getPos(), pos0=pos; end

  function setPosChnCb( f ), posChnCb=f; end

  function setPosSetCb( f ), posSetCb=f; end

  function setPosLock( b ), posLock=b; end

  function setSizLock( b ), sizLock=b; end

  function setDrgLock( b ), dgrLock=b; end

  function setSidLock( lk )
    sidLock=lk; vis={'off','on'};
    for i=1:4, set(hCntr(i),'Visible',vis{2-lk(i)}); end
  end

  function uistack1( varargin )
    if(isempty(hBnds) || isempty(hPatch)); return; end;
    uistack( [hBnds hPatch hCntr hEll], varargin{:} );
  end

  function setStyle( ls, lw, color, colorc )
    if(isempty(hEll)), h=hBnds; else h=hEll; end
    set(h,'LineStyle',ls,'LineWidth',lw,'color',color);
    if(~rotate), return; end; if(nargin<4), colorc='b'; end
    set(hCntr,'FaceColor',color,'EdgeColor',color);
    set(hCntr(1),'LineWidth',lw,'FaceColor',colorc);
  end
end
