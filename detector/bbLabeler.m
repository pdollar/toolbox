function bbLabeler( objTypes, imgDir, resDir )
% Bounding box or ellipse labeler for static images.
%
% Launch and click "?" icon for more info.
%
% USAGE
%  bbLabeler( [objTypes], [imgDir], [resDir] )
%
% INPUTS
%  objTypes - [{'object'}] list of object types to annotate
%  imgDir   - [pwd] directory with images
%  resDir   - [imgDir] directory with annotations
%
% OUTPUTS
%
% EXAMPLE
%  bbLabeler
%
% See also bbGt, imRectRot
%
% Piotr's Image&Video Toolbox      Version 2.66
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<1 || isempty(objTypes)), objTypes={'object'}; end
if(nargin<2 || isempty(imgDir)), imgDir=pwd; end
if(nargin<3 || isempty(resDir)), resDir=imgDir; end
if(~exist(resDir,'dir')), mkdir(resDir); end
colors='gcmrkgcmrkgcmrkgcmrkgcmrkgcmrkgcmrk'; minSiz=[12 12];
[hFig,hPan,hAx,pTop,imgInd,imgFiles,usePnts] = deal([]);
makeLayout(); imgApi=imgMakeApi(); objApi=objMakeApi();
usePnts=0; imgApi.setImgDir(imgDir);

  function makeLayout()
    % common properties
    name = 'bounding box labeler';
    bg='BackgroundColor'; fg='ForegroundColor'; ha='HorizontalAlignment';
    units = {'Units','pixels'}; st='String'; ps='Position'; fs='FontSize';
    
    % initial figures size / pos
    set(0,'Units','pixels');  ss = get(0,'ScreenSize');
    if( ss(3)<800 || ss(4)<600 ); error('screen too small'); end;
    figPos = [(ss(3)-620)/2 (ss(4)-500)/2 620 500];
    
    % create main figure
    hFig = figure('NumberTitle','off', 'Toolbar','none', 'Color','k', ...
      'MenuBar','none', 'Visible','off', ps,figPos, 'Name',[name resDir]);
    set(hFig,'DeleteFcn',@(h,e) exitProg,'ResizeFcn',@(h,e) figResized );
    
    % display axes
    hAx = axes(units{:},'Parent',hFig,'XTick',[],'YTick',[]); imshow(0);
    
    % top panel
    pnlProp = [units {bg,[.1 .1 .1],'BorderType','none'}];
    txtPrp = {'Style','text',bg,[.1 .1 .1],fs,8,fg,'w',ha};
    edtPrp = {'Style','edit',bg,[.1 .1 .1],fs,8,fg,'w',ha};
    btnPrp = [units,{'Style','pushbutton','FontWeight','bold',...
      bg,[.7 .7 .7],fs,10}];
    chbPrp = {'Style','checkbox',bg,[.1 .1 .1],fs,8,fg,'w'};
    pTop.h = uipanel(pnlProp{:},'Parent',hFig);
    pTop.hImgInd=uicontrol(pTop.h,edtPrp{:},'Right',st,'0');
    pTop.hImgNum=uicontrol(pTop.h,edtPrp{:},'Left',st,'/0',...
      'Enable','inactive');
    pTop.hLbl = uicontrol( pTop.h,'Style','popupmenu',units{:},...
      st,objTypes,fs,8,'Value',1);
    pTop.hDel=uicontrol(pTop.h,btnPrp{:},fs,11,fg,[.5 0 0],st,'X');
    pTop.hPrv=uicontrol(pTop.h,btnPrp{:},st,'<<');
    pTop.hNxt=uicontrol(pTop.h,btnPrp{:},st,'>>');
    pTop.hOcc=uicontrol(pTop.h,chbPrp{:},st,'occ');
    pTop.hIgn=uicontrol(pTop.h,chbPrp{:},st,'ign');
    pTop.hEll=uicontrol(pTop.h,chbPrp{:},st,'ellipse');
    pTop.hRot=uicontrol(pTop.h,chbPrp{:},st,'rotate');
    pTop.hLim=uicontrol(pTop.h,chbPrp{:},st,'lims');
    pTop.hPnt=uicontrol(pTop.h,chbPrp{:},st,'pnts');
    pTop.hHid=uicontrol(pTop.h,chbPrp{:},st,'hide');
    pTop.hPan=uicontrol(pTop.h,chbPrp{:},st,'pan');
    pTop.hDims=uicontrol(pTop.h,txtPrp{:},'Center',st,'');
    pTop.hNum=uicontrol(pTop.h,txtPrp{:},'Center',st,'n=0');
    pTop.hHelp=uicontrol(pTop.h,btnPrp{:},fs,12,st,'?');
    
    % set the keyPressFcn for all focusable components (except popupmenus)
    set( hFig, 'keyPressFcn',@keyPress );
    set( hFig, 'WindowScrollWheelFcn',@(h,e) mouseWheel(e));
    set( hFig, 'ButtonDownFcn',@(h,e) mousePress );
    set( pTop.hHelp,'CallBack',@(h,e) helpWindow );
    
    % set hFig to visible upon completion
    set(hFig,'Visible','on'); drawnow;
    
    % pan controls
    hPan = pan( hFig );
    
    function figResized()
      % overall layout
      pos=get(hFig,ps); pad=8; htTop=30; wdTop=620;
      wd=pos(3)-2*pad; ht=pos(4)-2*pad-htTop;
      x=(pos(3)-wd)/2; y=pad;
      set(hAx,ps,[x y wd ht]); y=y+ht;
      set(pTop.h,ps,[x y wd htTop]);
      % position stuff in top panel
      x=max(2,(wd-wdTop)/2);
      set(pTop.hImgInd,ps,[x 4 40 22]); x=x+40;
      set(pTop.hImgNum,ps,[x 4 40 22]); x=x+50;
      set(pTop.hDel,ps,[x 5 20 20]); x=x+20+5;
      set(pTop.hPrv,ps,[x 5 24 20]); x=x+25;
      set(pTop.hLbl,ps,[x 5 80 21]); x=x+81;
      set(pTop.hNxt,ps,[x 5 24 20]); x=x+25+5;
      set(pTop.hDims,ps,[x 5 60 20]); x=x+62;
      set(pTop.hOcc,ps,[x 15 45 13]);
      set(pTop.hIgn,ps,[x 2 45 13]); x=x+50;
      set(pTop.hEll,ps,[x 15 55 13]);
      set(pTop.hRot,ps,[x 2 55 13]); x=x+60;
      set(pTop.hLim,ps,[x 15 45 13]);
      set(pTop.hPnt,ps,[x 2 45 13]); x=x+50;
      set(pTop.hHid,ps,[x 15 55 13]);
      set(pTop.hPan,ps,[x 2 55 13]); x=x+60;
      set(pTop.hNum,ps,[x 5 30 20]); x=x+30+20;
      set(pTop.hHelp,ps,[x 5 20 20]);
    end
    
    function helpWindow()
      helpTxt = {
        'Image Selection:'
        ' * spacebar: advance one image'
        ' * ctrl-spacebar: go back one image'
        ' * double-click: advance one image'
        ' * can also directly enter image index'
        ''
        'Zoom and Pan controls:'
        ' * mouse wheel or +/- keys: zoom in and out'
        ' * q-key or pan-icon: toggle pan mode'
        ' * click/drag: pans image (while in pan mode)'
        ''
        'bb modification with mouse:'
        ' * click/drag in blank region: create new bb'
        ' * click on existing bb: select bb'
        ' * click/drag center of existing bb: move bb'
        ' * click/drag edge of existing bb: resize bb'
        ' * clck/drag control points: rotate/resize bb'
        ' * ctrl+arrow keys: shift selected bb'
        ''
        'Other controls:'
        ' * d-key or del-key or X-icon: delete selected bb'
        ' * o-key or occ-icon: toggle occlusion for bb'
        ' * i-key or ign-icon: toggle ignore for bb'
        ' * e-key or ellipse-icon: toggle bb ellipse/rect display'
        ' * r-key or rotation-icon: toggle bb rotation control'
        ' * l-key or lims-icon: toggle bb limits on/off'
        ' * p-key or pnts-icon: toggle pnt creation on/off'
        ' * left-arrow or <<-icon: select previous bb'
        ' * right-arrow or >>-icon: select next bb'
        ' * up/down-arrow a-key/z-key or dropbox: select bb label'
        ' * ctrl and +/- keys: increase/decrease contrast' };
      pos=get(0,'ScreenSize'); pos=[(pos(3)-400)/2 (pos(4)-520)/2 400 520];
      hHelp = figure('NumberTitle','off', 'Toolbar','auto', ...
        'Color','k', 'MenuBar','none', 'Visible','on', ...
        'Name',[name ' help'], 'Resize','on', ps, pos ); pos(1:2)=0;
      uicontrol( hHelp, 'Style','text', ha,'Left', fs,10, bg,'w', ...
        ps,pos, st,helpTxt );
    end
    
    function exitProg(), objApi.closeAnn(); end
  end

  function keyPress( h, evnt ) %#ok<INUSL>
    c=int8(evnt.Character); if(isempty(c)), c=0; end;
    ctrl=strcmp(evnt.Modifier,'control'); if(isempty(ctrl)),ctrl=0; end
    if(c==127 || c==100), objApi.objDel(); end % 'del' or 'd'
    if(c==32 && ctrl ), imgApi.setImg(imgInd-1); end % ctrl-spacebar
    if(c==32 && ~ctrl), imgApi.setImg(imgInd+1); end % spacebar
    if(c==28 && ctrl), objApi.objShift(-1,0); end   % ctrl-lf
    if(c==29 && ctrl), objApi.objShift(+1,0); end   % ctrl-rt
    if(c==30 && ctrl), objApi.objShift(0,-1); end   % ctrl-up
    if(c==31 && ctrl), objApi.objShift(0,+1); end   % ctrl-dn
    if(c==28 && ~ctrl), objApi.objToggle(-1); end  % lf
    if(c==29 && ~ctrl), objApi.objToggle(+1); end  % rt
    if((c==30 && ~ctrl) || c==97),  objApi.objSetType(-1); end  % up or 'a'
    if((c==31 && ~ctrl) || c==122), objApi.objSetType(+1); end  % dn or 'z'
    if(c==111), objApi.objSetVal('occ',0); end  % 'o'
    if(c==105), objApi.objSetVal('ign',0); end  % 'i'
    if(c==101), objApi.objSetVal('ell',0); end  % 'e'
    if(c==114), objApi.objSetVal('rot',0); end  % 'r'
    if(c==108), objApi.objSetVal('lim',0); end  % 'l'
    if(c==112), objApi.objSetVal('pnt',0); end  % 'p'
    if(c==104), objApi.objSetVal('hid',0); end  % 'h'
    if(c==113), objApi.objSetVal('pan',0); end  % 'q'
    if(c==43 && ~ctrl), zoom(1.1);   end % '+' key, zoom in
    if(c==45 && ~ctrl), zoom(1/1.1); end % '-' key, zoom out
    if(c==43 && ctrl), imgApi.adjContrast(+1); end % ctrl-'+', inc contrast
    if(c==45 && ctrl), imgApi.adjContrast(-1); end % ctrl-'-', dec contrast
  end

  function mousePress()
    sType = get(hFig,'SelectionType');
    %disp(['mouse pressed: ' sType]);
    if( strcmp(sType,'open') )
      if( usePnts ), return; end
      imgApi.setImg(imgInd+1); % double click
    elseif( strcmp(sType,'normal') )
      objApi.objNew(); % single click
    end
  end

  function mouseWheel( evnt )
    if( evnt.VerticalScrollCount>0 ), zoom(1/1.1); else zoom(1.1); end
  end

  function mouseDrag()
    if(isempty(imgInd)), return; end
    persistent h; if(~all(ishandle(h))), h=[]; end
    xs=get(gca,'xLim'); ys=get(gca,'yLim');
    p=get(hAx,'CurrentPoint'); x=p(1); y=p(3);
    if( x<xs(1)||x>xs(2)||y<ys(1)||y>ys(2) ), delete(h); return; end
    if(isempty(h)), h=[line line];
      set(h,'ButtonDownFcn',@(h,e) mousePress,'Color','k'); end
    set(h,{'Xdata'},{[x x];xs},{'YData'},{ys,[y y]}');
  end

  function api = objMakeApi()
    % variables
    [resNm,objs,nObj,hsObj,curObj,lims] = deal([]);
    ellipse=0; rotate=0; useLims=0; hide=0;
    
    % callbacks
    set(pTop.hDel,'Callback',@(h,evnt) objDel());
    set(pTop.hPrv,'Callback',@(h,evnt) objToggle(-1));
    set(pTop.hNxt,'Callback',@(h,evnt) objToggle(+1));
    set(pTop.hLbl,'Callback',@(h,evnt) objSetType());
    set(pTop.hOcc,'Callback',@(h,evnt) objSetVal('occ',1));
    set(pTop.hIgn,'Callback',@(h,evnt) objSetVal('ign',1));
    set(pTop.hEll,'Callback',@(h,evnt) objSetVal('ell',1));
    set(pTop.hRot,'Callback',@(h,evnt) objSetVal('rot',1));
    set(pTop.hLim,'Callback',@(h,evnt) objSetVal('lim',1));
    set(pTop.hPnt,'Callback',@(h,evnt) objSetVal('pnt',1));
    set(pTop.hHid,'Callback',@(h,evnt) objSetVal('hid',1));
    set(pTop.hPan,'Callback',@(h,evnt) objSetVal('pan',1));
    
    % create api
    api = struct( 'closeAnn',@closeAnn, 'openAnn',@openAnn, ...
      'objNew',@objNew, 'objDel',@objDel, 'objToggle',@objToggle, ...
      'objSetType',@objSetType, 'objSetVal',@objSetVal, ...
      'objShift',@objShift );
    
    function closeAnn()
      % save annotation and then clear (also use to init)
      if(~isempty(nObj)&&~isempty(resNm)), bbGt('bbSave',objs,resNm); end
      delete(hsObj); hsObj=[]; nObj=0; resNm=''; curObj=0; objs=[];
      objsDraw();
    end
    
    function openAnn()
      % try to load annotation, prepare for new image
      assert(nObj==0); lims=[get(gca,'xLim'); get(gca,'yLim')];
      lims=[lims(:); 0]'; lims(3:4)=lims(3:4)-lims(1:2);
      resNm=[resDir '/' imgFiles{imgInd} '.txt'];
      if(exist(resNm,'file')), objs=bbGt('bbLoad',resNm); end
      objTypes=unique([objTypes bbGt('get',objs,'lbl')']);
      set(pTop.hLbl,'String',objTypes); nObj=length(objs); objsDraw();
    end
    
    function objsDraw()
      delete(hsObj); if(hide), hsObj=[]; return; end; hsObj=zeros(1,nObj);
      % display regular bbs
      for id=1:nObj
        o=objs(id); color=colors(strcmp(o.lbl,objTypes));
        rp=struct('ellipse',ellipse,'rotate',rotate,'hParent',hAx,...
          'lw',2,'ls','-','pos',[o.bb o.ang],'color',color);
        if(~useLims), rp.lims=[]; else rp.lims=lims; end
        if(o.ign), rp.cross=2; end; if(curObj==id), rp.ls=':'; end
        [hsObj(id),rectApi]=imRectRot(rp);
        rectApi.setPosSetCb(@(bb) objSetBb(bb,id));
        rectApi.setPosChnCb(@(bb) objChnBb(bb,id));
        if(id==curObj), rectApiCur=rectApi; end
      end
      if(curObj>0), rectApiCur.uistack('top'); end
      % display occluded bbs
      for id=1:nObj
        o=objs(id); ang=o.ang; if(~o.occ), continue; end
        rp=struct('ellipse',ellipse,'rotate',0,'hParent',hAx,'lw',1,...
          'ls','-','pos',[o.bbv ang],'lims',[o.bb ang],'color','y');
        [hObj,rectApi] = imRectRot( rp );
        rectApi.setPosSetCb(@(bbv) objSetBbv(bbv,id));
        hsObj=[hsObj hObj]; %#ok<AGROW>
      end
      % update gui info
      if(curObj==0), dimsStr=''; occ=0; ign=0; en='off'; else
        o=objs(curObj); occ=o.occ; ign=o.ign; en='on';
        set(pTop.hLbl,'Value',find(strcmp(o.lbl,objTypes)));
        dimsStr=sprintf('%i x %i',round(o.bb(3)),round(o.bb(4)));
      end
      set([pTop.hIgn pTop.hOcc],'Enable',en); set(pTop.hOcc,'Value',occ);
      set(pTop.hDims,'String',dimsStr); set(pTop.hIgn,'Value',ign);
      set(pTop.hNum,'String', ['n=' int2str(nObj)] );
      set(hFig,'WindowButtonMotionFcn',@(h,e) mouseDrag); mouseDrag();
    end
    
    function objSetBb( bb, objId )
      curObj=objId; o=objs(objId); bb=round(bb); bbv=o.bbv;
      if(any(bb(3:4)<minSiz)), objDel(); return; end;
      objs(objId).bb=bb(1:4); objs(objId).ang=bb(5);
      if(~o.occ), objsDraw(); return; end
      if( objs(objId).ang~=o.ang ), bbv=[0 0 0 0]; else
        bbv=[(bbv(1:2)-o.bb(1:2))./o.bb(3:4) bbv(3:4)./o.bb(3:4)];
        bbv=[(bbv(1:2).*bb(3:4))+bb(1:2) bbv(3:4).*bb(3:4)];
      end; objSetBbv(bbv,objId);
    end
    
    function objSetBbv( bbv, objId )
      curObj=objId; o=objs(objId); bbv=round(bbv(1:4));
      if(~o.occ), objs(objId).bbv=[0 0 0 0]; objsDraw(); return; end
      if(any(bbv(3:4)<minSiz)), bbv=o.bb; end
      objs(objId).bbv=bbv; objsDraw();
    end
    
    function objChnBb( bb, objId ) %#ok<INUSD>
      dimsStr=sprintf('%i x %i',round(bb(3)),round(bb(4)));
      set( pTop.hDims, 'String', dimsStr );
    end
    
    function objNew()
      if(hide), return; end; curObj=0; objsDraw();
      pnt=get(hAx,'CurrentPoint'); pnt=pnt([1,3]);
      if( pnt(1)<lims(1) || pnt(1)>lims(3) || ...
          pnt(2)<lims(2) || pnt(2)>lims(4)), return; end
      lblId=get(pTop.hLbl,'Value'); color=colors(lblId);
      rp=struct('ellipse',ellipse,'rotate',rotate/2,'hParent',hAx,...
        'lw',2,'ls',':','pos',pnt,'color',color);
      if(~useLims), rp.lims=[]; else rp.lims=lims; end
      [hObj,rectApi]=imRectRot(rp);
      lbl=objTypes{lblId}; bb=round(rectApi.getPos());
      if( usePnts && all(bb(3:4)<minSiz) )
        bb(1:2)=bb(:,1:2)+bb(:,3:4)/2-minSiz/2; bb(3:4)=minSiz;
      end
      if( usePnts || all(bb(3:4)>=minSiz) )
        obj=bbGt('create'); obj.lbl=lbl; obj.bb=bb(1:4); obj.ang=bb(5);
        objs=[objs; obj]; nObj=nObj+1; curObj=nObj;
      end; delete(hObj); objsDraw();
    end
    
    function objDel()
      if(curObj==0), return; end
      objs(curObj)=[]; curObj=0; nObj=nObj-1; objsDraw();
    end
    
    function objToggle( del )
      curObj=mod(curObj+del,nObj+1); objsDraw();
    end
    
    function objSetType( del )
      val = get(pTop.hLbl,'Value');
      if( nargin>0 && del~=0 )
        val = max(1,min(val+del,length(objTypes)));
        set(pTop.hLbl,'Value',val);
      end
      if(curObj), objs(curObj).lbl=objTypes{val}; objsDraw(); end
    end
    
    function objSetVal( type, flag )
      if(strcmp(type,'occ'))
        if(curObj==0), return; end
        occ = get(pTop.hOcc,'Value'); if(~flag), occ=1-occ; end
        objs(curObj).occ=occ; objSetBbv(objs(curObj).bb,curObj); return;
      elseif(strcmp(type,'ign'))
        if(curObj==0), return; end
        ign = get(pTop.hIgn,'Value'); if(~flag), ign=1-ign; end
        objs(curObj).ign=ign;
      elseif(strcmp(type,'ell'))
        ellipse = get(pTop.hEll,'Value');
        if(~flag), ellipse=1-ellipse; set(pTop.hEll,'Value',ellipse); end
      elseif(strcmp(type,'rot'))
        rotate = get(pTop.hRot,'Value');
        if(~flag), rotate=1-rotate; set(pTop.hRot,'Value',rotate); end
      elseif(strcmp(type,'lim'))
        useLims = get(pTop.hLim,'Value');
        if(~flag), useLims=1-useLims; set(pTop.hLim,'Value',useLims); end
      elseif(strcmp(type,'pnt'))
        usePnts = get(pTop.hPnt,'Value');
        if(~flag), usePnts=1-usePnts; set(pTop.hPnt,'Value',usePnts); end
      elseif(strcmp(type,'hid'))
        hide = get(pTop.hHid,'Value');
        if(~flag), hide=1-hide; set(pTop.hHid,'Value',hide); end
        if( hide ), curObj=0; end
      elseif(strcmp(type,'pan'))
        enabled = get(pTop.hPan,'Value');
        if(~flag), enabled=1-enabled; set(pTop.hPan,'Value',enabled); end
        if(~enabled), set(hPan,'Enable','off'); else
          set(hPan,'Enable','on'); hM=uigetmodemanager(hFig);
          set(hM.WindowListenerHandles,'Enable','off');
          set( hFig, 'keyPressFcn',@keyPress);
          set( hFig, 'WindowScrollWheelFcn',@(h,e) mouseWheel(e));
          setptr(hFig,'hand'); %set(hFig,'Pointer','hand');
        end
      end
      objsDraw();
    end
    
    function objShift( x, y )
      if(curObj==0), return; end
      objs(curObj).bb(1:2)=objs(curObj).bb(1:2)+[x y];
      objsDraw();
    end
  end

  function api = imgMakeApi()
    [nImg,hImg,contrast,I]=deal([]);
    set(pTop.hImgInd,'Callback',@(h,evnt) setImgCb());
    api = struct( 'setImgDir',@setImgDir, 'setImg',@setImg, ...
      'adjContrast',@adjContrast );
    
    function setImgDir( imgDir1 )
      objApi.closeAnn(); imgDir=imgDir1;
      imgFiles=[dir([imgDir '/*.jpg']); dir([imgDir '/*.jpeg']); ...
        dir([imgDir '/*.png']); dir([imgDir '/*.tif'])];
      imgFiles={imgFiles.name}; nImg=length(imgFiles); setImg(1);
      set(pTop.hImgNum,'String',['/' int2str(nImg)]);
    end
    
    function adjContrast( del )
      if(isempty(I)), return; end
      contrast=max(.1,contrast+del/10);
      set(hImg,'CData',I*contrast);
    end
    
    function setImg( imgInd1 )
      if(nImg==0), return; end; objApi.closeAnn(); imgInd=imgInd1;
      if(imgInd<1), imgInd=1; end; if(imgInd>nImg), imgInd=nImg; end
      I=imread([imgDir '/' imgFiles{imgInd}]); hImg=imshow(I);
      set(pTop.hImgInd,'String',int2str(imgInd)); contrast=1;
      set(hImg,'ButtonDownFcn',@(h,e) mousePress); objApi.openAnn();
    end
    
    function setImgCb()
      imgInd1=str2double(get(pTop.hImgInd,'String'));
      if(isnan(imgInd1)), setImg(imgInd); else setImg(imgInd1); end
    end
  end

end
