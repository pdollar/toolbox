function [hPatch,api] = imRectRot( varargin )

% global variables (shared by all functions below)
[hParent,pos,lims,ellipse,linePrp,ellPrp,circProp,...
  crXs,crYs,posChnCb,posSetCb,hAx,hFig,hPatch,hBnds,hCntr,hEll,...
  posLock,sizLock] = deal([]);

% intitialize
intitialize( varargin{:} );

% create api
api = struct('getPos',@getPos, 'setPos',@setPos, ...
  'setPosChnCb',@setPosChnCb, 'setPosSetCb',@setPosSetCb, ...
  'setPosLock',@setPosLock, 'setSizLock',@setSizLock, ...
  'setAr',@setAr, 'uistack',@uistack1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function intitialize( varargin )
    % get default arguments
    dfs={ 'hParent',gca, 'pos',[], 'lims',[], 'showLims',0, 'ellipse',1,...
      'linePrp',{'color',[.7 .7 .7],'LineWidth',1}, ...
      'ellPrp',{'color','g','LineWidth',2}, ...
      'circProp',{'Curvature',[1 1],'FaceColor','g','EdgeColor','g'} };
    [hParent,pos,lims,showLims,ellipse,linePrp,ellPrp,circProp] = ...
      getPrmDflt(varargin,dfs,1);
    if(length(lims)==4), lims=[lims 0]; end
    
    % get figure and axes handles
    hAx = ancestor(hParent,'axes'); assert(~isempty(hAx));
    hFig = ancestor(hAx,'figure'); assert(~isempty(hFig));
    set( hFig, 'CurrentAxes', hAx );
    
    % optionally display limits
    if( showLims ), [disc,xs,ys]=rectToCorners(lims);
      for j=1:4, ids=mod([j-1 j],4)+1; line(xs(ids),ys(ids)); end
    end
    
    % create objects for display / interface
    if(isempty(pos)); vis='off'; else vis='on'; end; hold on;
    hPatch=patch('FaceColor','none','EdgeColor','none'); hBnds=[0 0 0 0];
    for i=1:4, hBnds(i)=line(linePrp{:},'Visible',vis); end
    hCntr=rectangle(circProp{:},'Visible',vis);
    ts=linspace(-180,180,50); crXs=cosd(ts); crYs=sind(ts);
    hEll=plot(crXs,crYs,ellPrp{:},'Visible',vis);
    hs=[hPatch hBnds hCntr hEll]; hold off;
    set(hs,'ButtonDownFcn',{@btnDwn,0},'DeleteFcn',@deleteFcn);
    
    % set or query initial position
    posLock=0; sizLock=0;
    if(length(pos)==5), setPos(pos); else
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
    [pc,rs,R] = rectInfo( pos0 );
    p0=[x0 y0]*R'+pc; p1=[x1 y1]*R'+pc;
    pc=(p1+p0)/2; p0=(p0-pc)*R; p1=(p1-pc)*R;
    pos1 = [pc+p0 p1-p0 pos0(5)];
  end

  function setPos( posNew )
    if(isempty(hBnds) || isempty(hPatch)); return; end; L=lims;
    % if corners fall outside lims don't use posNew
    if( ~isempty(L) )
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
    pos=posNew; [pts,xs,ys]=rectToCorners(pos);
    vert=[xs ys ones(4,1)]; face=1:4;
    set(hPatch,'Faces',face,'Vertices',vert);
    % draw ellipse
    if(ellipse), [pc,rs]=rectInfo(posNew); th=pos(5);
      xsEll = rs(1)*crXs*cosd(-th)+rs(2)*crYs*sind(-th)+pc(1);
      ysEll = rs(2)*crYs*cosd(-th)-rs(1)*crXs*sind(-th)+pc(2);
      set(hEll,'XData',xsEll,'YData',ysEll);
    end
    % draw rectangle boundaries and control circles
    for i=1:4, ids=mod([i-1 i],4)+1;
      set(hBnds(i),'Xdata',xs(ids),'Ydata',ys(ids));
    end
    x=mean(xs([1 2]),1); y=mean(ys([1 2]),1);
    r=max(2,min([axisUnitsPerCentimeter()*.15,5,pos(3)/4,pos(4)/4]));
    set(hCntr,'Position',[x-r y-r 2*r 2*r]);
    drawnow
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
    t = axisUnitsPerCentimeter()*.15; side=[0 0]; flag=0;
    for i=1:2
      ti = min(t,rs(i)/3);
      if( abs(pnt(i))<ti ), side(i)=2; % near center
      elseif( pnt(i)<-rs(i)+ti ), side(i)=-1; % near lf/tp boundary
      elseif( pnt(i)>rs(i)-ti), side(i)=1; % near rt/bt boundary
      end
    end
    if(any(side==0) || all(side==2)), side(side==2)=0; end
    if(any(side==2) && any(side~=[2 -1])), side(side==2)=0; end
    if(all(side==0)), flag=1; side=pnt0; cursor='fleur'; return; end
    if(any(side==2)), flag=2; cursor='crosshair'; return; end
    % select cursor based on position
    cs={'bottom','botr','right','topr','top','topl','left','botl'};
    a=mod(round((atan2(side(1),side(2))/pi-th/180)*4),8)+1; cursor=cs{a};
  end

  function btnDwn( h, evnt, flag ) %#ok<INUSL>
    if(isempty(hBnds) || isempty(hPatch)); return; end;
    if(posLock); return; end; if(sizLock); flag=1; end;
    if( flag==-1 ) % create new rectangle
      if(isempty(pos)), anchor=ginput(1); else anchor=pos(1:2); end
      setPos( [anchor 1 1 0] );
      set([hBnds hCntr hEll],'Visible','on'); cursor='botr'; flag=0;
    else % resize, rotate or drag rectangle
      pnt=getCurPnt(); [anchor,cursor,flag]=getSide( pnt );
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
    elseif( flag==0 ) % resize in rectangle coordinate frame
      [pc,rs,R]=rectInfo(pos0); p0=-rs; p1=rs; del=(pnt-pc)*R;
      for i=1:2, if(anchor(i)>0), p1(i)=del(i); end; end
      for i=1:2, if(anchor(i)<0), p0(i)=del(i); end; end
      p0a=min(p0,p1); p1=max(p0,p1); p0=p0a;
      setPos(cornersToRect(pos0,p0(1),p0(2),p1(1),p1(2)));
    else % rotate rectangle
      [pts,xs,ys]=rectToCorners(pos0);
      p0=mean([xs([3 4]) ys([3 4])]); pc=(p0+pnt)/2; d=pnt-p0;
      w=pos(3); h=sqrt(sum(d.^2)); th=atan2(d(1),-d(2))/pi*180;
      setPos([pc(1)-w/2 pc(2)-h/2 w h th]);
    end
    if(~isempty(posChnCb)); posChnCb(pos); end;
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

  function uistack1( varargin )
    if(isempty(hBnds) || isempty(hPatch)); return; end;
    uistack( [hBnds hPatch], varargin{:} );
  end

end
