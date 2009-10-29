function poseLabeler( imgDir, resDir )
% Pose labeler for static images.
%
% Launch and click "?" icon for more info. Note: initial ground truth
% images (possibly containing a default pose) must be supplied.
%
% USAGE
%  poseLabeler( [imgDir], [resDir] )
%
% INPUTS
%  imgDir     - [pwd] directory with images
%  resDir     - [imgDir] directory with annotations
%
% OUTPUTS
%
% EXAMPLE
%  poseLabeler
%
% See also poseGt
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

%#ok<*INUSL,*INUSD>
if(nargin<1 || isempty(imgDir)), imgDir=pwd; end
if(nargin<2 || isempty(resDir)), resDir=imgDir; end
if(~exist(resDir,'dir')), mkdir(resDir); end
[hFig,hAx,pTop,imgInd,imgFiles] = deal([]);
makeLayout(); imgApi=imgMakeApi(); objApi=objMakeApi();
imgApi.setImgDir(imgDir);

  function makeLayout()
    % common properties
    name = 'pose labeler';
    bg='BackgroundColor'; fg='ForegroundColor'; ha='HorizontalAlignment';
    units = {'Units','pixels'}; st='String'; ps='Position'; fs='FontSize';
    
    % initial figures size / pos
    set(0,'Units','pixels');  ss = get(0,'ScreenSize');
    if( ss(3)<640 || ss(4)<480 ); error('screen too small'); end;
    figPos = [(ss(3)-400)/2 (ss(4)-430)/2 400 430];
    
    % create main figure
    hFig = figure('NumberTitle','off', 'Toolbar','auto', 'Color','k', ...
      'MenuBar','none', 'Visible','off', ps,figPos, 'Name',name );
    set(hFig,'DeleteFcn',@exitProg,'ResizeFcn',@figResized);
    
    % display axes
    hAx = axes(units{:},'Parent',hFig,'XTick',[],'YTick',[]); imshow(0);
    
    % top panel
    pnlProp = [units {bg,[.1 .1 .1],'BorderType','none'}];
    edtPrp = {'Style','edit',bg,[.1 .1 .1],fs,8,fg,'w',ha};
    btnPrp = [units,{'Style','pushbutton','FontWeight','bold',...
      bg,[.7 .7 .7],fs,10}];
    pTop.h = uipanel(pnlProp{:},'Parent',hFig);
    pTop.hImgInd=uicontrol(pTop.h,edtPrp{:},'Right',st,'0');
    pTop.hImgNum=uicontrol(pTop.h,edtPrp{:},'Left',st,'/0',...
      'Enable','inactive');
    pTop.hHelp=uicontrol(pTop.h,btnPrp{:},fs,12,st,'?');
    
    % set the keyPressFcn for all focusable components (except popupmenus)
    set( hFig, 'keyPressFcn',@keyPress );
    set( hFig, 'ButtonDownFcn',@mousePress );
    set( pTop.hHelp,'CallBack',@helpWindow );
    
    % set hFig to visible upon completion
    set(hFig,'Visible','on'); drawnow;
    
    function figResized( h, evnt )
      % overall layout
      pos=get(hFig,ps); pad=8; htTop=30; wdTop=420;
      wd=pos(3)-2*pad; ht=pos(4)-2*pad-htTop;
      x=(pos(3)-wd)/2; y=pad;
      set(hAx,ps,[x y wd ht]); y=y+ht;
      set(pTop.h,ps,[x y wd htTop]);
      % position stuff in top panel
      x=max(0,(wd-wdTop)/2);
      set(pTop.hImgInd,ps,[x 4 40 22]); x=x+40;
      set(pTop.hImgNum,ps,[x 4 40 22]); x=x+50; x=max(x,wd-25);
      set(pTop.hHelp,ps,[x 5 20 20]);
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
        ' * click on part: select part'
        ' * click/drag center of part: move part'
        ' * click/drag edge of bb: resize part'
        ' * clck/drag control points: rotate/resize part'
        ''
        'Other controls:'
        ' * left-arrow: select previous part'
        ' * right-arrow: select next part' };
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
    if(char==32 && ctrl), imgApi.setImg(imgInd-1); end % ctrl-spacebar
    if(char==32 && ~ctrl), imgApi.setImg(imgInd+1); end % spacebar
    if(char==28), objApi.objToggle(-1); end  % left arrow key
    if(char==29), objApi.objToggle(+1); end  % right arrow key
  end

  function mousePress( h, evnt )
    sType = get(hFig,'SelectionType');
    if( strcmp(sType,'open') )
      imgApi.setImg(imgInd+1); % double click
    end
  end

  function api = objMakeApi()
    % create shared variables and api
    [resNm,parts,partCur,hsObj,bbCur,rectApis] = deal([]);
    api = struct( 'closeAnn',@closeAnn, 'openAnn',@openAnn,...
      'objToggle',@objToggle );
    
    function closeAnn()
      % save annotation and then clear (also use to init)
      if(isempty(resNm)), assert(isempty(parts)); return; end
      poseGt('objSave',parts,resNm); delete(hsObj);
      [resNm,parts,partCur,hsObj,bbCur,rectApis] = deal([]);
    end
    
    function openAnn()
      % try to load annotation, prepare for new image
      assert(isempty(parts)); resNm=[resDir '/' imgFiles{imgInd} '.txt'];
      if(~exist(resNm,'file')), error('missing object file %s',resNm); end
      parts=poseGt('objLoad',resNm);
      % create interactive ellipses for each part
      n=length(parts); hsObj=zeros(1,n); rectApis=cell(1,n);
      W=diff(get(gca,'xLim')); H=diff(get(gca,'yLim'));
      bbCur=poseGt('getAbsPos',parts,W,H);
      for i=1:n
        rp=struct('ellipse',1,'rotate',1,'hParent',hAx,'pos',bbCur(i,:));
        [hsObj(i),rectApis{i}]=imRectRot(rp);
        rectApis{i}.setPosSetCb(@(bb) objSetBb(bb,i,W,H));
        rectApis{i}.setPosChnCb(@(bb) objSetBb(bb,i,W,H));
        if(i>1), btLk=1; else btLk=0; end; aspLk=parts(i).aspLk;
        rectApis{i}.setSidLock([0 aspLk btLk aspLk]);
      end
      partCur=1; objDraw();
    end
    
    function objSetBb( bb, partId, W, H )
      parts=poseGt('setAbsPos',parts,partId,bb,W,H);
      bbCur=poseGt('getAbsPos',parts,W,H);
      partCur=partId; objDraw();
    end
    
    function objDraw()
      rectApis{partCur}.uistack('top');
      for i=1:length(parts)
        rectApis{i}.setPos( bbCur(i,:) );
        if(i==partCur), ls=':'; else ls='-'; end
        if(i==1), c1=[.5 1 .75]; c2=[.8 1 1]; else
          c1='g'; c2=[.8 1 .9]; end
        rectApis{i}.setStyle(ls,2,c1,c2);
      end
    end
    
    function objToggle( del )
      partCur=mod(partCur+del-1,length(parts))+1; objDraw();
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
