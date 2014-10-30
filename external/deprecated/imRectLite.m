function [hRect,api] = imrectLite( hParent, pos, lims, ar, varargin )
% A 'lite' version of imrect [OBSOLETE: use imrectRot].
%
% There are significant problems using imrect in a larger GUI, mostly
% due to the fact that imrect is such a heavy object.  This creates a
% simple, fast, and in some ways nicer version of imrect.
%
% The implementation uses two graphics object: a rectangle and a patch.
% The patch is just there to catch mouse clicks in case the rectangle does
% not have a face color.  Any valid property of the rectangle may be
% altered (such as 'FaceColor', 'Curvature', ... ), EXCEPT for its
% 'ButtonDownFcn', 'DeleteFcn' and 'Position' properties.  To change the
% 'Position' of the rectangle, use the output structure 'api' (described
% below).
%
% USAGE
%  [hRect,api] = imrectLite( [hParent],[pos],[lims],[ar],[varargin] )
%
% INPUTS
%  hParent    - [gca] object parent, typically an axes object (gca)
%  pos        - [] initial pos vector [x y w h] or [] or [x0 y0]
%  lims       - [] 2x2 matrix of [xMin xMax; yMin yMax]
%  ar         - [0] aspect ratio (if positive w/h is constrained to ar)
%  varargin   - [] parameters to RECTANGLE graphics object
%
% OUTPUTS
%  hRect      - handle to rectangle, use to alter color etc.
%  api        - interface allowing access to created object
%  .getPos()       - get position - returns 4 elt pos
%  .setPos(pos)    - set position (while respecting constraints)
%  .setAr(ar)      - set aspect ratio to fixed value
%  .setPosLock(b)  - if lock set (b==true), rectangle cannot change
%  .setSizLock(b)  - if lock set (b==true), rectangle cannot change size
%  .setPosChnCb(f) - whenever pos changes (even slightly), calls f(pos)
%  .setPosSetCb(f) - whenever pos finished changing, calls f(pos)
%  .uistack(...)   - calls 'uistack( [hRect hPatch], ... )', see uistack
%
% EXAMPLE
%  figure(1), imshow cameraman.tif
%  rectProp = {'EdgeColor','g','LineWidth',4,'Curvature',[.1 .1]};
%  lims = [get(gca,'xLim'); get(gca,'yLim')];
%  [h,api] = imrectLite( gca, [], lims, [],  rectProp{:} );
%  api.setPosChnCb( @(pos) disp(['        ' num2str(pos)]) );
%  api.setPosSetCb( @(pos) disp(['FINAL = ' num2str(pos)]) );
%
% See also IMRECT, RECTANGLE, PATCH
%
% Piotr's Image&Video Toolbox      Version 2.35
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% default arguments / globals
if( nargin<1 || isempty(hParent) ); hParent=gca; end
if( nargin<2 ); pos=[]; end
if( nargin<3 ); lims=[]; end
if( nargin<4 || isempty(ar) ); ar=0; end
[posChnCb,posSetCb]=deal([]);
posLock=false; sizLock=false; minSiz=1;

% get figure and axes handles
hAx = ancestor(hParent,'axes'); assert(~isempty(hAx));
hFig = ancestor(hAx,'figure'); assert(~isempty(hFig));
set( hFig, 'CurrentAxes', hAx );

% create rectangle as well as patch objects
if(isempty(pos)); vis='off'; else vis='on'; end
hPatch = patch('FaceColor','none','EdgeColor','none');
hRect = rectangle(varargin{:},'Visible',vis);
set([hRect hPatch],'ButtonDownFcn',{@btnDwn,0},'DeleteFcn',@deleteFcn);

% set / get position
if(length(pos)==4), setPos(pos); else
  btnDwn([],[],-1); waitfor(hFig,'WindowButtonUpFcn','');
end

% create api
api = struct('getPos',@getPos, 'setPos',@setPos, ...
  'setPosChnCb',@setPosChnCb, 'setPosSetCb',@setPosSetCb, ...
  'setPosLock',@setPosLock, 'setSizLock',@setSizLock, ...
  'setAr',@setAr, 'uistack',@uistack1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function setPos( posNew, varargin )
    if(isempty(hRect) || isempty(hPatch)); return; end
    % constrain position to fall within lims
    pos = constrainPos( posNew, varargin{:} );
    % compute rectangle vertices
    xs = pos([1 1 1 1]); xs(2:3)=xs(2:3)+pos(3);
    ys = pos([2 2 2 2]); ys(3:4)=ys(3:4)+pos(4);
    vert = [xs' ys' [1;1;1;1]]; face=1:4;
    % draw objects
    set(hPatch,'Faces',face,'Vertices',vert);
    set(hRect,'Position',pos);
  end

  function pos = constrainPos( pos, anchor, pos0 )
    % constrain position to fall within lims
    if( ~isempty(lims) )
      posStr=pos(1:2);  posEnd=pos(1:2)+pos(3:4);
      posStr = min( max(posStr,lims(1:2)), lims(3:4)-minSiz );
      posEnd = max( min(posEnd,lims(3:4)), posStr+minSiz );
      pos = [posStr posEnd-posStr];
    end
    
    % now constrain for aspect ratio
    if( ar<=0 ); return; end;
    w=pos(3); h=pos(4);
    if( nargin<3 )
      w = min( w, h*ar );
      h = min( h, w/ar );
      pos(3:4) = [w h];
    else
      if( isempty(lims) )
        if( anchor(1)==0 ); w=h*ar; else h=w/ar; end;
      else
        mid = pos(1:2) + pos(3:4)/2;
        lr='MRL'; lr=lr(sign(anchor(1)-pos(1))+2);
        tb='MBT'; tb=tb(sign(anchor(2)-pos(2))+2);
        if( strcmp(tb,'M') )
          maxH=min(lims(4)-mid(2), mid(2)-lims(2))*2;
          switch lr
            case 'L'; maxW=min(lims(3)-pos(1),maxH*ar);
            case 'R'; maxW=min(pos(1)+pos(3)-lims(1),maxH*ar);
          end
          w=min(w,maxW); h=w/ar;
        else
          switch lr
            case 'L'; maxW=pos(1)+pos(3)-lims(1);
            case 'M'; maxW=min(lims(3)-mid(1), mid(1)-lims(1))*2;
            case 'R'; maxW=lims(3)-pos(1);
          end
          maxH=min(pos(2)+pos(4)-lims(2),maxW/ar);
        end
        h=min(h,maxH); w=h*ar;
      end
      if( strcmp(lr,'M') )
        pos0(1)=pos0(1)-(w-pos0(3))/2; pos0(3)=w;
      elseif( strcmp(tb,'M') )
        pos0(2)=pos0(2)-(h-pos0(4))/2; pos0(4)=h;
      end
      sgnSiz = [w h] .* (2*(pos(1:2)==anchor)-1);
      pos = shiftPos( anchor, pos0, sgnSiz );
    end
  end

  function pos = shiftPos( anchor, pos0, del )
    % shift pos by del unless anchor(i)==0
    pos = pos0;
    for i=1:2, if(anchor(i)==0), continue; end
      pos(i)=anchor(i); pos(i+2)=max(minSiz,abs(del(i)));
      if(del(i)<0); pos(i)=pos(i)-pos(i+2); end;
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

  function [anchor,cursor] = getSide( pnt )
    % get pnt in coordintates of center of rectangle
    rs=pos(3:4)/2; pnt=pnt-pos(1:2)-rs;
    % side(i) -1=near lf/tp bnd; 0=in center; +1:near rt/bt bnd
    t = axisUnitsPerCentimeter()*.15; side=[0 0];
    for i=1:2
      ti = min(t,rs(i)/2);
      if( pnt(i)<-rs(i)+ti ), side(i)=-1; % near lf/tp boundary
      elseif( pnt(i)>rs(i)-ti), side(i)=1; % near rt/bt boundary
      end
    end
    % compute anchor in orig coord system(opposite of selected side)
    anchor=-side.*rs+pos(1:2)+rs; anchor(side==0)=0;
    % select cursor based on position
    cs={'bottom','botr','right','topr','top','topl','left','botl'};
    a=mod(round((atan2(side(1),side(2))/pi)*4),8)+1; cursor=cs{a};
  end

  function btnDwn( h, evnt, flag )
    if(isempty(hRect) || isempty(hPatch)); return; end;
    if(posLock); return; end; if(sizLock); flag=1; end;
    if( flag==-1 ) % create new rectangle
      if(isempty(pos)), anchor=ginput(1); else anchor=pos(1:2); end
      setPos( [anchor 1 1] );
      set(hRect,'Visible','on'); cursor='botr'; flag=0;
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
    if(isempty(hRect) || isempty(hPatch)); return; end;
    pnt = getCurPnt(); del = pnt-anchor;
    if( flag==1 ) % shift rectangle by del
      setPos( [pos0(1:2)+del pos0(3:4)] );
    else % resize rectangle
      setPos(shiftPos(anchor,pos0,del),anchor,pos0);
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
    [posChnCb,posSetCb]=deal([]); hs=[hPatch hRect];
    for i=1:length(hs), if(ishandle(hs(i))); delete(hs(i)); end; end
    [hRect,hPatch]=deal([]);
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function pos0 = getPos(), pos0=pos; end

  function setAr( ar1 ), ar=ar1; setPos(pos); end

  function setPosChnCb( f ), posChnCb=f; end

  function setPosSetCb( f ), posSetCb=f; end

  function setPosLock( b ), posLock=b; end

  function setSizLock( b ), sizLock=b; end

  function uistack1( varargin )
    if(isempty(hRect) || isempty(hPatch)); return; end;
    uistack( [hRect hPatch], varargin{:} );
  end

end
