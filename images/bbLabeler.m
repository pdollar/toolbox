function bbLabeler( imgDir, resDir )
% Bounding box labeler for static images.
%
% USAGE
%  bbLabeler( [imgDir], [resDir] )
%
% INPUTS
%  imgDir   - [pwd] directory with images
%  resDir   - [imgDir] directory with annotations
%
% OUTPUTS
%
% EXAMPLE
%  bbLabeler
%
% See also
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

%#ok<*INUSL,*INUSD>
if(nargin<1 || isempty(imgDir)), imgDir=pwd; end
if(nargin<2 || isempty(resDir)), resDir=imgDir; end
if(~exist(resDir,'dir')), mkdir(resDir); end
objTypes={'person','ignore'}; colors={'g','k'}; minSiz=[8 16];
[hFig,hAx,pTop,imgInd,imgFiles] = deal([]);
makeLayout(); imgApi=imgMakeApi(); objApi=objMakeApi();
imgApi.setImgDir(imgDir);

  function makeLayout()
    % common properties
    name = 'bounding box labeler';
    bg='BackgroundColor'; fg='ForegroundColor'; ha='HorizontalAlignment';
    units = {'Units','pixels'}; st='String'; ps='Position'; fs='FontSize';
    
    % initial figures size / pos
    set(0,'Units','pixels');  ss = get(0,'ScreenSize');
    if( ss(3)<800 || ss(4)<600 ); error('screen too small'); end;
    figPos = [(ss(3)-600)/2 (ss(4)-500)/2 600 500];
    
    % create main figure
    hFig = figure('NumberTitle','off', 'Toolbar','auto', 'Color','k', ...
      'MenuBar','none', 'Visible','off', ps,figPos, 'Name',name );
    set(hFig,'DeleteFcn',@exitProg,'ResizeFcn',@figResized);
    
    % display axes
    hAx = axes(units{:},'Parent',hFig,'XTick',[],'YTick',[]); imshow(0);
    
    % top panel
    pnlProp = [units {bg,[.1 .1 .1],'BorderType','none'}];
    txtPrp = {'Style','text',bg,[.1 .1 .1],fg,'w',ha};
    edtPrp = {'Style','edit',bg,[.1 .1 .1],fg,'w',ha};
    btnPrp = [units,{'Style','pushbutton','FontWeight','bold',...
      bg,[.7 .7 .7],fs,10}];
    chbPrp = {'Style','checkbox',bg,[.1 .1 .1],fg,'w'};
    pTop.h = uipanel(pnlProp{:},'Parent',hFig);
    pTop.hImgLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'image:');
    pTop.hImgInd=uicontrol(pTop.h,edtPrp{:},'Right',st,'0');
    pTop.hImgNum=uicontrol(pTop.h,txtPrp{:},'Left',st,'/0');
    pTop.hLbl = uicontrol( pTop.h,'Style','popupmenu',units{:},...
      st,objTypes,'Value',1);
    pTop.hDel=uicontrol(pTop.h,btnPrp{:},fs,11,fg,[.5 0 0],st,'X');
    pTop.hPrv=uicontrol(pTop.h,btnPrp{:},st,'<<');
    pTop.hNxt=uicontrol(pTop.h,btnPrp{:},st,'>>');
    pTop.hOcc=uicontrol(pTop.h,chbPrp{:},st,'occ');
    pTop.hIgn=uicontrol(pTop.h,chbPrp{:},st,'ign');
    pTop.hDims=uicontrol(pTop.h,txtPrp{:},'Center',st,'');
    pTop.hNum=uicontrol(pTop.h,txtPrp{:},'Center',st,'n=0');
    pTop.hHelp=uicontrol(pTop.h,btnPrp{:},fs,12,st,'?');
    
    % set the keyPressFcn for all focusable components (except popupmenus)
    set( hFig, 'keyPressFcn',@keyPress );
    set( hFig, 'ButtonDownFcn',@mousePress );
    set( pTop.hHelp,'CallBack',@helpWindow );
    
    % set hFig to visible upon completion
    set(hFig,'Visible','on'); drawnow;
    
    function figResized( h, evnt )
      % overall layout
      pos=get(hFig,ps); pad=8; htTop=24; wdTop=590;
      wd=pos(3)-2*pad; ht=pos(4)-2*pad-htTop;
      x=(pos(3)-wd)/2; y=pad;
      set(hAx,ps,[x y wd ht]); y=y+ht;
      set(pTop.h,ps,[x y wd htTop]);
      % position stuff in top panel
      x=max(0,(wd-wdTop)/2);
      set(pTop.hImgLbl,ps,[x 5 35 14]); x=x+35;
      set(pTop.hImgInd,ps,[x 5 40 15]); x=x+40;
      set(pTop.hImgNum,ps,[x 5 40 14]); x=x+60;
      set(pTop.hDel,ps,[x 2 20 20]); x=x+20+5;
      set(pTop.hPrv,ps,[x 2 24 20]); x=x+24;
      set(pTop.hLbl,ps,[x 2 80 21]); x=x+80;
      set(pTop.hNxt,ps,[x 2 24 20]); x=x+24+5;
      set(pTop.hDims,ps,[x 5 60 14]); x=x+60;
      set(pTop.hOcc,ps,[x 12 50 12]);
      set(pTop.hIgn,ps,[x 0 50 12]); x=x+55;
      set(pTop.hNum,ps,[x 5 20 14]); x=x+20+100;
      set(pTop.hHelp,ps,[x 2 20 20]);
    end
    
    function helpWindow( h, evnt )
      helpTxt = {
        'Image Selection:'
        ' * spacebar: advance one image'
        ' * ctrl-spacebar: go back one image'
        ' * double-click: advance one image'
        ' * can also directly enter image index'
        ''
        'bb modification with mouse:'
        ' * click/drag in blank region: create new bb'
        ' * click on existing bb: select bb'
        ' * click/drag center of existing bb: move bb'
        ' * click/drag edge of existing bb: resize bb'
        ''
        'Other controls:'
        ' * d-key or del-key or X-icon: delete selected bb'
        ' * o-key or occ-icon: toggle occlusion for bb'
        ' * i-key or ign-icon: toggle ignore for bb'
        ' * left-arrow or <<-icon: toggle selected bb'
        ' * right-arrow or >>-icon: toggle selected bb'
        ' * up/down-arrow a-key/z-key or dropbox: select bb label' };
      hHelp = figure('NumberTitle','off', 'Toolbar','auto', ...
        'Color','k', 'MenuBar','none', 'Visible','on', ...
        'Name',[name ' help'], 'Resize','off');
      pos=get(hHelp,ps); pos(1:2)=0;
      uicontrol( hHelp, 'Style','text', ha,'Left', fs,10, bg,'w', ...
        ps,pos, st,helpTxt );
    end
    
    function exitProg(h,evnt), objApi.closeAnn(); end
  end

  function keyPress( h, evnt )
    char=int8(evnt.Character); if(isempty(char)), char=0; end;
    ctrl=strcmp(evnt.Modifier,'control'); if(isempty(ctrl)),ctrl=0; end
    if(char==127 || char==100), objApi.objDel(); end % 'del' or 'd'
    if(char==32 && ctrl), imgApi.setImg(imgInd-1); end % ctrl-spacebar
    if(char==32 && ~ctrl), imgApi.setImg(imgInd+1); end % spacebar
    if(char==28), objApi.objToggle(-1); end  % left arrow key
    if(char==29), objApi.objToggle(+1); end  % right arrow key
    if(char==30 || char==97), objApi.objChangeType(-1); end  % up or a
    if(char==31 || char==122), objApi.objChangeType(+1); end  % down or z
    if(char==111), objApi.objSetVal('occ',0); end  % 'o'
    if(char==105), objApi.objSetVal('ign',0); end  % 'i'
  end

  function mousePress( h, evnt )
    sType = get(hFig,'SelectionType');
    %disp(['mouse pressed: ' sType]);
    if( strcmp(sType,'open') )
      imgApi.setImg(imgInd+1); % double click
    elseif( strcmp(sType,'normal') )
      objApi.objNew(); % single click
    end
  end

  function api = objMakeApi()
    % variables
    [resNm,objs,nObj,hsObj,curObj,lims] = deal([]);
    
    % default display properties for rectangles
    rpDef=struct('ellipse',0,'rotate',0,'hParent',hAx,'lw',2,'ls','-');
    
    % callbacks
    set(pTop.hDel,'Callback',@(h,evnt) objDel());
    set(pTop.hPrv,'Callback',@(h,evnt) objToggle(-1));
    set(pTop.hNxt,'Callback',@(h,evnt) objToggle(+1));
    set(pTop.hLbl,'Callback',@(h,evnt) objSetType());
    set(pTop.hOcc,'Callback',@(h,evnt) objSetVal('occ',1));
    set(pTop.hIgn,'Callback',@(h,evnt) objSetVal('ign',1));
    
    % create api
    api = struct( 'closeAnn',@closeAnn, 'openAnn',@openAnn, ...
      'objNew',@objNew, 'objDel',@objDel, 'objToggle',@objToggle, ...
      'objChangeType',@objChangeType, 'objSetVal',@objSetVal );
    
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
      nObj=length(objs); objsDraw();
    end
    
    function objsDraw()
      delete(hsObj); hsObj=zeros(1,nObj);
      % display regular bbs
      for id=1:nObj
        o=objs(id); rp=rpDef; rp.color=colors{strcmp(o.lbl,objTypes)};
        if(o.ign), rp.cross=2; end; rp.pos=[o.bb o.ang]; rp.lims=lims;
        if(curObj==id), rp.ls=':'; end; [hsObj(id),rectApi]=imRectRot(rp);
        rectApi.setPosSetCb(@(bb) objSetBb(bb,id));
        rectApi.setPosChnCb(@(bb) objChnBb(bb,id));
        if(id==curObj), rectApiCur=rectApi; end
      end
      if(curObj>0), rectApiCur.uistack('top'); end
      % display occluded bbs
      for id=1:nObj
        o=objs(id); ang=o.ang; if(~o.occ), continue; end; rp=rpDef;
        rp.color='y'; rp.lw=1; rp.pos=[o.bbv ang]; rp.lims=[o.bb ang];
        rp.rotate=0; [hObj,rectApi] = imRectRot( rp );
        rectApi.setPosSetCb(@(bbv) objSetBbv(bbv,id));
        hsObj=[hsObj hObj]; %#ok<AGROW>
      end
      % update gui info
      if(curObj==0), lblId=1; dimsStr=''; occ=0; ign=0; en='off'; else
        o=objs(curObj); occ=o.occ; ign=o.ign; en='on';
        lblId=find(strcmp(o.lbl,objTypes));
        dimsStr=sprintf('%i x %i',round(o.bb(3)),round(o.bb(4)));
      end
      set([pTop.hIgn pTop.hOcc pTop.hLbl],'Enable',en);
      set(pTop.hDims,'String',dimsStr); set(pTop.hIgn,'Value',ign);
      set(pTop.hOcc,'Value',occ); set(pTop.hLbl,'Value',lblId);
      set(pTop.hNum,'String', ['n=' int2str(nObj)] );
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
    
    function objChnBb( bb, objId )
      dimsStr=sprintf('%i x %i',round(bb(3)),round(bb(4)));
      set( pTop.hDims, 'String', dimsStr );
    end
    
    function objNew()
      curObj=0; objsDraw();
      pnt=get(hAx,'CurrentPoint'); pnt=pnt([1,3]); curObj=0;
      lblId=get(pTop.hLbl,'Value'); rp=rpDef; rp.color=colors{lblId};
      rp.ls=':'; rp.pos=pnt; rp.lims=lims; [hObj,rectApi]=imRectRot(rp);
      lbl=objTypes{lblId}; bb=round(rectApi.getPos());
      if( ~isempty(bb) && all(bb(3:4)>=minSiz) )
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
    
    function objSetType()
      if(curObj==0), return; end
      val = get(pTop.hLbl,'Value');
      objs(curObj).lbl=objTypes{val}; objsDraw();
    end
    
    function objChangeType( del )
      val = get(pTop.hLbl,'Value');
      val = max(1,min(val+del,length(objTypes)));
      set(pTop.hLbl,'Value',val); objSetType();
    end
    
    function objSetVal( type, flag )
      if(curObj==0), return; end
      if(strcmp(type,'occ'))
        if( flag )
          objs(curObj).occ=get(pTop.hOcc,'Value');
        else
          objs(curObj).occ=1-objs(curObj).occ;
        end
        objSetBbv(objs(curObj).bb,curObj);
      elseif(strcmp(type,'ign'))
        if( flag )
          objs(curObj).ign=get(pTop.hIgn,'Value');
        else
          objs(curObj).ign=1-objs(curObj).ign;
        end
        objsDraw();
      end
    end
  end

  function api = imgMakeApi()
    nImg=deal([]);
    set(pTop.hImgInd,'Callback',@(h,evnt) setImgCb());
    api = struct( 'setImgDir',@setImgDir, 'setImg',@setImg );
    
    function setImgDir( imgDir1 )
      objApi.closeAnn(); imgDir=imgDir1;
      imgFiles=[dir([imgDir '/*.jpg']); dir([imgDir '/*.png'])];
      imgFiles={imgFiles.name}; nImg=length(imgFiles); setImg(1);
      set(pTop.hImgNum,'String',['/' int2str(nImg)]);
    end
    
    function setImg( imgInd1 )
      if(nImg==0), return; end; objApi.closeAnn(); imgInd=imgInd1;
      if(imgInd<1), imgInd=1; end; if(imgInd>nImg), imgInd=nImg; end
      I=imread([imgDir '/' imgFiles{imgInd}]); hImg=imshow(I);
      set(pTop.hImgInd,'String',int2str(imgInd));
      set(hImg,'ButtonDownFcn',@mousePress); objApi.openAnn();
    end
    
    function setImgCb()
      imgInd1=str2double(get(pTop.hImgInd,'String'));
      if(isnan(imgInd1)), setImg(imgInd); else setImg(imgInd1); end
    end
  end

end
