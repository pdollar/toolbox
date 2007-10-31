% A 'lite' version of imrect (fast, bugfree, simple).
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
%  pos        - [] initial pos vector [xMin yMin width height] or []
%  lims       - [] 2x2 matrix of [xMin xMax; yMin yMax]
%  ar         - [0] aspect ratio (if positive w/h is constrained to ar)
%  varargin   - [] parameters to RECTANGLE graphics object
%
% OUTPUTS
%  hRect      - handle to rectangle, use to alter color etc.
%  api        - interface allowing access to created object
%  .getPos()       - get position - returns 4 elt pos
%  .setPos(pos)    - set position - returns new pos
%  .setAr(ar)      - set aspect ratio , returns new pos
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
%  api.setPosChnCb( @(pos) disp(['        ' int2str(pos)]) );
%  api.setPosSetCb( @(pos) disp(['FINAL = ' int2str(pos)]) );
%
% See also IMRECT, RECTANGLE, PATCH

% Piotr's Image&Video Toolbox      Version NEW
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Liscensed under the Lesser GPL [see external/lgpl.txt]

function [hRect,api] = imrectLite( hParent, pos, lims, ar, varargin )

% default arguments / globals
if( nargin<1 || isempty(hParent) ); hParent=gca; end
if( nargin<2 ); pos=[]; end
if( nargin<3 ); lims=[]; end
if( nargin<4 || isempty(ar) ); ar=0; end
[posChnCb,posSetCb]=deal([]);
posLock=false;  sizLock=false;

% get figure and axes handles
hAx = ancestor(hParent,'axes'); assert(~isempty(hAx));
hFig = ancestor(hAx,'figure'); assert(~isempty(hFig));
set( hFig, 'CurrentAxes', hAx );

% create rectangle as well as patch objects
if(isempty(pos)); vis='off'; else vis='on'; end
hPatch = patch('FaceColor','None','EdgeColor','none');
hRect = rectangle(varargin{:},'Visible',vis,'DeleteFcn',@deleteFcn);
set(hRect,'ButtonDownFcn',{@btnDwn,0});
set(hPatch,'ButtonDownFcn',{@btnDwn,1});

% set / get position
if( isempty(pos) )
  btnDwn( [], [], -1 );
  waitfor( hFig, 'WindowButtonUpFcn', '' );
else
  setPos( pos );
end

% create api
api = struct('hRect',hRect, 'getPos',@getPos, 'setPos',@setPos, ...
  'setPosChnCb',@setPosChnCb, 'setPosSetCb',@setPosSetCb, ...
  'setPosLock',@setPosLock, 'setSizLock',@setSizLock, ...
  'setAr',@setAr, 'uistack',@uistack1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function pos = getPos()
    pos = get(hRect,'Position');
  end

  function pos = setPos( pos, varargin )
    pos = constrainPos( pos, varargin{:} );
    xs = pos([1 1 1 1]); xs(2:3)=xs(2:3)+pos(3);
    ys = pos([2 2 2 2]); ys(3:4)=ys(3:4)+pos(4);
    vert = [xs' ys' [1;1;1;1]]; face=1:4;
    set(hPatch,'Faces',face,'Vertices',vert);
    set(hRect,'Position',pos);
  end

  function pos = constrainPos( pos, anchor, pos0 )
    % constrain position to fall within lims
    if( ~isempty(lims) )
      minSiz = 1;
      posStr=pos(1:2);  posEnd=pos(1:2)+pos(3:4)-1;
      posMin = lims(1:2);  posMax=lims(3:4);
      posStr = min( max(posStr,posMin), posMax-minSiz );
      posEnd = max( min(posEnd,posMax-1), posMin+minSiz-1 );
      pos = [posStr posEnd-posStr+1];
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
      pos = computePos( anchor, pos0, sgnSiz );
    end
  end

  function pos = computePos( anchor, pos0, sgnSiz )
    pos = zeros(1,4);
    for i=1:2
      if( anchor(i)==0 )
        pos(i)=pos0(i); pos(i+2)=pos0(i+2);
      else
        pos(i) = anchor(i);
        pos(i+2) = max(.01,abs(sgnSiz(i)));
        if(sgnSiz(i)<0); pos(i)=pos(i)-pos(i+2); end;
      end
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

  function [anchor,cursor] = getAnchor( pnt, pos )
    t = axisUnitsPerCentimeter() * .2;
    side=[0 0]; anchor=[0 0];
    posEnd = pos(1:2)+pos(3:4);
    dStr = abs(pnt-pos(1:2));
    dEnd = abs(pnt-posEnd);
    if( any(pnt<pos(1:2)) || any(pnt>posEnd) )
      t = max( t, min([dStr dEnd])*1.1 );
    end
    for i=1:2
      if( dStr(i)<t && dStr(i)<dEnd(i) )
        side(i) = -1;
        anchor(i) = posEnd(i);
      elseif( dEnd(i) < t )
        side(i) = 1;
        anchor(i) = pos(i);
      end
    end
    switch(side(1)+side(2)*10)
      case -11; cursor='topl';
      case -10; cursor='top';
      case -9;  cursor='topr';
      case -1;  cursor='left';
      case 0;   cursor='arrow';
      case 1;   cursor='right';
      case 9;   cursor='botl';
      case 10;  cursor='bottom';
      case 11;  cursor='botr';
    end
  end

  function btnDwn( h, evnt, flag )
    if( posLock ); return; end;
    if( sizLock ); flag=1; end;
    if( flag==-1 )
      % create new rectangle
      anchor = ginput(1);
      pos0 = [anchor 1 1];
      setPos( pos0 );
      set(hRect,'Visible','on');
      cursor='botr'; flag=0;
    elseif( flag==0 )
      % resize rectangle
      pos0 = getPos();  pnt = getCurPnt();
      [anchor,cursor] = getAnchor(pnt,pos0);
      if( all(anchor==0) );
        btnDwn(h,evnt,1); return;
      end
    elseif( flag==1 )
      % move rectangle
      anchor = getCurPnt();
      pos0 = getPos();
      cursor='fleur';
    else
      assert(false);
    end
    set( hFig, 'Pointer', cursor );
    set( hFig, 'WindowButtonMotionFcn',{@drag,flag,anchor,pos0} );
    set( hFig, 'WindowButtonUpFcn', @stopDrag );
  end

  function drag( h, evnt, flag, anchor, pos0 ) %#ok<INUSL>
    pnt = getCurPnt();
    del = pnt-anchor;
    if( flag==1 )
      pos = [pos0(1:2)+del pos0(3:4)];
      pos = setPos( pos );
    else
      pos = computePos( anchor, pos0, del );
      pos = setPos( pos, anchor, pos0 );
    end

    %%% can display size/pos while resizing/dragging
    % hText = -1; %global
    % if(ishandle(hText)); delete(hText); hText=-1; end
    % if(flag==1); info=pos(1:2); else info=pos(3:4); end
    % pr = max(ceil(log10(info)),2);
    % posStr = [num2str(info(1),pr(1)) ', ' num2str(info(2),pr(2))];
    % hText=text(pos(1),pos(2),posStr,'VerticalAlignment','bottom');
    % set(hText,'BackgroundColor',[.9 .9 .9],'FontSize',7);
    %if(ishandle(hText)); delete(hText); hText=-1; end %stopDrag

    drawnow
    if(~isempty(posChnCb)); posChnCb(pos); end;
  end

  function stopDrag( h, evnt ) %#ok<INUSD>
    set( hFig, 'WindowButtonMotionFcn','');
    set( hFig, 'WindowButtonUpFcn','');
    set( hFig, 'Pointer', 'arrow' );
    if(~isempty(posSetCb)); posSetCb(getPos()); end;
  end

  function deleteFcn( h, evnt ) %#ok<INUSD>
    if(ishandle(hPatch)); delete(hPatch); end;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function pos = setAr( ar1 )
    ar = ar1;
    pos = setPos(getPos());
  end

  function setPosChnCb( f )
    posChnCb=f;
  end

  function setPosSetCb( f )
    posSetCb=f;
  end

  function setPosLock( b )
    posLock = b;
  end

  function setSizLock( b )
    sizLock = b;
  end

  function uistack1( varargin )
    uistack( [hRect hPatch], varargin{:} );
  end

end
