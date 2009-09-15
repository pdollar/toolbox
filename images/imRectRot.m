function [hPatch,api] = imRectRot( hParent, pos, lims, linePrp )

% default arguments / globals
if( nargin<1 || isempty(hParent) ); hParent=gca; end
if( nargin<2 ); pos=[]; end
if( nargin<3 ); lims=[]; end
if( nargin<4 ); linePrp={}; end
[posChnCb,posSetCb]=deal([]);
posLock=false; sizLock=false; minSiz=1;

% get figure and axes handles
hAx = ancestor(hParent,'axes'); assert(~isempty(hAx));
hFig = ancestor(hAx,'figure'); assert(~isempty(hFig));
set( hFig, 'CurrentAxes', hAx );

% create patch object as well as boundaries objects
if(isempty(pos)); vis='off'; else vis='on'; end
hPatch = patch('FaceColor','none','EdgeColor','none'); hBnds=[0 0 0 0];
for j=1:4, hBnds(j)=line(linePrp{:},'Visible',vis); end
set([hBnds hPatch],'ButtonDownFcn',{@btnDwn,0},'DeleteFcn',@deleteFcn);

% set / get position
if(length(pos)==5), setPos(pos); else
  btnDwn([],[],-1); waitfor(hFig,'WindowButtonUpFcn','');
end

% create api
api = struct('getPos',@getPos, 'setPos',@setPos, ...
  'setPosChnCb',@setPosChnCb, 'setPosSetCb',@setPosSetCb, ...
  'setPosLock',@setPosLock, 'setSizLock',@setSizLock, ...
  'setAr',@setAr, 'uistack',@uistack1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function R = rotateMatrix(t), c=cosd(t); s=sind(t); R=[c -s; s c]; end

  function setPos( posNew )
    if(isempty(hBnds) || isempty(hPatch)); return; end
    pos=posNew;
    % constrain position to fall within lims
    if( ~isempty(lims) )
      posStr=pos(1:2); posEnd=pos(1:2)+pos(3:4);
      posStr = min( max(posStr,lims(1:2)), lims(3:4)-minSiz );
      posEnd = max( min(posEnd,lims(3:4)), posStr+minSiz );
      pos = [posStr posEnd-posStr pos(5)];
    end
    % compute rectangle vertices
    rx=pos(3)/2; ry=pos(4)/2; theta=pos(5);
    pts=rotateMatrix(theta)*[-rx rx rx -rx; -ry -ry ry ry];
    xs=pts(1,:)+pos(1)+rx; ys=pts(2,:)+pos(2)+ry;
    % draw objects
    vert = [xs' ys' [1;1;1;1]]; face=1:4;
    set(hPatch,'Faces',face,'Vertices',vert);
    set(hBnds(1),'Xdata',xs([1 2]),'Ydata',ys([1 2]));
    set(hBnds(2),'Xdata',xs([2 3]),'Ydata',ys([2 3]));
    set(hBnds(3),'Xdata',xs([3 4]),'Ydata',ys([3 4]));
    set(hBnds(4),'Xdata',xs([4 1]),'Ydata',ys([4 1]));
  end

  function pnt = getCurPnt()
    pnt = get(hAx,'CurrentPoint');
    pnt = pnt([1,3]);
  end

  function d = axisUnitsPerCentimeter()
    % approximage absolute axes size
    units=get(hAx,'units');
    set(hAx,'units','centimeters');
    cms = get(hAx,'Position');
    cms = max(cms(3:4));
    set(hAx,'units',units);
    % axes size in axes units
    xLim=get(gca,'xLim'); yLim=get(gca,'yLim');
    sizInner = max([xLim(2)-xLim(1),yLim(2)-yLim(1)]);
    % units per centemeter
    d = sizInner/cms;
  end

  function [side,cursor] = getSide( pnt )
    % get pnt in coordintates of center of rectangle
    th=pos(5); R=rotateMatrix(th);
    rs=pos(3:4)/2; pnt=(pnt-pos(1:2)-rs)*R;
    % side(i) -1=near lf/tp bnd; 0=in center; +1:near rt/bt bnd
    t = axisUnitsPerCentimeter()*.15; side=[0 0];
    for i=1:2
      ti = min(t,rs(i)/2);
      if( pnt(i)<-rs(i)+ti ), side(i)=-1; % near lf/tp boundary
      elseif( pnt(i)>rs(i)-ti), side(i)=1; % near rt/bt boundary
      end
    end
    % select cursor based on position
    cs={'bottom','botr','right','topr','top','topl','left','botl'};
    a=mod(round((atan2(side(1),side(2))/pi-th/180)*4),8)+1; cursor=cs{a};
  end

  function btnDwn( h, evnt, flag )
    if(isempty(hBnds) || isempty(hPatch)); return; end;
    if(posLock); return; end; if(sizLock); flag=1; end;
    if( flag==-1 ) % create new rectangle
      if(isempty(pos)), anchor=ginput(1); else anchor=pos(1:2); end
      setPos( [anchor 1 1 0] );
      set(hBnds,'Visible','on'); cursor='botr'; flag=0;
    elseif( flag==0 ) % resize (or possibly drag) rectangle
      pnt=getCurPnt(); [anchor,cursor] = getSide( pnt );
      if(all(anchor==0)), btnDwn(h,evnt,1); return; end
    elseif( flag==1 ) % move rectangle
      anchor=getCurPnt(); cursor='fleur';
    else
      assert(false);
    end
    set( hFig, 'Pointer', cursor );
    set( hFig, 'WindowButtonMotionFcn',{@drag,flag,anchor,pos} );
    set( hFig, 'WindowButtonUpFcn', @stopDrag );
  end

  function drag( h, evnt, flag, anchor, pos0 ) %#ok<INUSL>
    if(isempty(hBnds) || isempty(hPatch)); return; end;
    pnt = getCurPnt(); del = pnt-anchor;
    if( flag==1 ) % shift rectangle by del
      setPos( [pos0(1:2)+del pos0(3:5)] );
    else % resize in rectangle coordinate frame
      pos=pos0; rs=pos(3:4)/2; R=rotateMatrix(pos(5));
      pc=pos(1:2)+rs; p0=-rs; p1=rs; del=(pnt-pc)*R;
      for i=1:2, if(anchor(i)>0), p1(i)=del(i); end; end
      for i=1:2, if(anchor(i)<0), p0(i)=del(i); end; end
      p0a=min(p0,p1); p1=max(p0,p1); p0=p0a;
      p0=p0*R'+pc; p1=p1*R'+pc;
      pc=(p1+p0)/2; p0=(p0-pc)*R; p1=(p1-pc)*R;
      setPos([pc+p0 p1-p0 pos0(5)]);
    end
    drawnow
    if(~isempty(posChnCb)); posChnCb(pos); end;
  end

  function stopDrag( h, evnt ) %#ok<INUSD>
    set( hFig, 'WindowButtonMotionFcn','');
    set( hFig, 'WindowButtonUpFcn','');
    set( hFig, 'Pointer', 'arrow' );
    if(~isempty(posSetCb)); posSetCb(pos); end;
  end

  function deleteFcn( h, evnt ) %#ok<INUSD>
    [posChnCb,posSetCb]=deal([]); hs=[hPatch hBnds];
    for i=1:length(hs), if(ishandle(hs(i))); delete(hs(i)); end; end
    [hBnds,hPatch]=deal([]);
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function pos0 = getPos(), pos0=pos; end

  function setPosChnCb( f ), posChnCb=f; end

  function setPosSetCb( f ), posSetCb=f; end

  function setPosLock( b ), posLock=b; end

  function setSizLock( b ), sizLock=b; end

  function uistack1( varargin )
    if(isempty(hBnds) || isempty(hPatch)); return; end;
    uistack( [hBnds hPatch], varargin{:} );
  end

end
