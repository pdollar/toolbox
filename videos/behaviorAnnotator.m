function behaviorAnnotator( fName, aName, tName )
% Caltech Behavior Annotator.
%
% Can only be used to annotated seq files. To annotate other types of video
% files, they need to be converted to seq files first. For example, to
% convert an avi file into an seq file, use the following command:
%  seqIo([seqName],'frImgs',struct('codec','jpg'),'aviName',[aviName])
% Where [seqName] denotes the name of the seq you want to save to and
% [aviName] is the avi file. See seqIo and seqIo>frimgs for more details.
%
% Use arrow keys to play the video. Controls are as follows:
% (1) If stopped: [L] play backward, [R] play forward
% (2) If playing forward: [L] halve speed, [R] double speed, [U/D] stop
% (3) If playing backward: [L] double speed, [R] halve speed,[U/D] stop
% You can explicitly enter a frame or use the slider to jump in the video.
%
% USAGE
%  behaviorAnnotator( [fName], [aName], [tName] )
%
% INPUTS
%  fName    - optional seq file to load at start
%  aName    - optional annotation file to load or import at start
%  tName    - optional tracking or detection file to load at start
%
% OUTPUTS
%
% EXAMPLE
%  behaviorAnnotator
%
% See also behaviorData, seqIo
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.60
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% handles to gui objects / other globals
[hFig,menu,pTop,pMid,pBot,dispApi,A,trk] = deal([]);

% initialize all
makeLayout();
menuApi = menuMakeApi();
dispApi = dispMakeApi();
annApi  = annMakeApi();
menuApi.vidClose();

% open vid, annotation and tracking results if given
if(nargin>=1 && ~isempty(fName)), menuApi.vidOpen(fName); end
if(nargin>=2 && ~isempty(aName)), menuApi.annOpen(aName); end
if(nargin>=3 && ~isempty(tName)), menuApi.trkOpen(tName); end

  function makeLayout()
    % common properties
    name = 'Caltech Behavior Annotator';
    bg='BackgroundColor'; fg='ForegroundColor';
    fs='FontSize'; ha='HorizontalAlignment';
    units = {'Units','pixels'}; st='String'; ps='Position';
    
    % initial figures size / pos
    set(0,'Units','pixels');  ss = get(0,'ScreenSize');
    if( ss(3)<800 || ss(4)<600 ); error('screen too small'); end;
    figPos = [(ss(3)-600)/2 (ss(4)-500)/2 600 500];
    
    % create main figure
    figPrp = {'NumberTitle','off', 'Toolbar','auto', 'MenuBar','none', 'Color','k'};
    hFig = figure(figPrp{:},'Visible','off', ps,figPos, 'Name',name );
    set(hFig,'DeleteFcn',@exitProg,'ResizeFcn',@figResized);
    
    % mid panel
    pMid.hAx=axes(units{:},'Parent',hFig); set(pMid.hAx,'XTick',[],'YTick',[]);
    pMid.hSl=uicontrol(hFig,'Style','slider','Min',0,'Max',1,bg,'k'); imshow(0);
    pMid.hBar=uicontrol(hFig,'Style','pushbutton',units{:},'Enable','inactive');
    pMid.hAdd=uicontextmenu('Parent',hFig); pMid.hAdds=[]; pMid.hTxt=[];
    
    % top panel
    pnlProp = [units {bg,[.1 .1 .1],'BorderType','none'}];
    txtPrp = {'Style','text',bg,[.1 .1 .1],fg,'w',ha};
    edtPrp = {'Style','edit',bg,[.1 .1 .1],fg,'w',ha};
    pTop.h = uipanel(pnlProp{:},'Parent',hFig);
    pTop.hBehLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'behavior:');
    pTop.hBh=uicontrol(pTop.h,units{:},'Style','popupmenu',fg,'w',bg,'k',st,{''});
    pTop.hFrmLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'frame:');
    pTop.hFrmInd=uicontrol(pTop.h,edtPrp{:},'Right');
    pTop.hTmLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'time:');
    pTop.hTmVal=uicontrol(pTop.h,txtPrp{:},'Left');
    pTop.hFrmNum=uicontrol(pTop.h,txtPrp{:},'Left');
    pTop.hPlyLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'speed:');
    pTop.hPlySpd=uicontrol(pTop.h,txtPrp{:},'Left',st,'0x');
    
    % bottom panel
    pBot.h=uipanel(pnlProp{:},'Parent',hFig); uiPr=[pBot.h,units,'Style'];
    uiButPr=[uiPr,'pushbutton', bg,[.9 .9 .9], fs,11, 'FontWeight','bold'];
    pBot.hStrm=uicontrol(uiPr{:},'popupmenu',fg,'w',bg,'k',st,{''});
    pBot.hBh=uicontrol(uiPr{:},'popupmenu',fg,'w',bg,'k',st,{''});
    pBot.hArrL=uicontrol(uiButPr{:},fg,'k',st,'<<');
    pBot.hSl=uicontrol(uiPr{:},'slider',bg,'k');
    pBot.hBar=uicontrol(uiPr{:},'pushbutton','Enable','inactive');
    pBot.hArrR=uicontrol(uiButPr{:},fg,'k',st,'>>');
    pBot.hSetL=uicontrol(uiPr{:},'pushbutton',fg,'k',bg,[.9 .9 .9],fs,8);
    pBot.hSetR=uicontrol(uiPr{:},'pushbutton',fg,'k',bg,[.9 .9 .9],fs,8);
    pBot.hZm=uicontrol(uiPr{:},'popupmenu',fg,'w',bg,'k',...
      st,int2str2([30 60 120 250*2.^(0:5)]),'Value',5);
    pBot.hDel=uicontrol(uiButPr{:},fg,[.5 0 0],st,'X');
    
    % icons for set region button
    I=ones(20,18); I(9:15,10:16)=triu(ones(7));
    I(14:15,4:13)=0; I=repmat(I,[1 1 3]);
    set(pBot.hSetL,'CData',I(:,end:-1:1,:));
    set(pBot.hSetR,'CData',I);
    
    % set the keyPressFcn for all focusable components (except popupmenus)
    set( [hFig, pMid.hSl pBot.hArrL pBot.hSl pBot.hArrR ...
      pBot.hSetL pBot.hSetR pBot.hDel], 'keyPressFcn',@keyPress );
    
    % create menus
    menu.hVid = uimenu(hFig,'Label','Video');
    menu.hVidOpn = uimenu(menu.hVid,'Label','Open');
    menu.hVidsOpn = uimenu(menu.hVid,'Label','Open dual');
    menu.hVidExp = uimenu(menu.hVid,'Label','Export');
    menu.hVidCls = uimenu(menu.hVid,'Label','Close');
    menu.hVidInf = uimenu(menu.hVid,'Label','Info');
    menu.hVidAud = uimenu(menu.hVid,'Label','Audio');
    menu.hAnn = uimenu(hFig,'Label','Annotation');
    menu.hAnnNew = uimenu(menu.hAnn,'Label','New');
    menu.hAnnOpn = uimenu(menu.hAnn,'Label','Open');
    menu.hAnnCls = uimenu(menu.hAnn,'Label','Close');
    menu.hAnnSav = uimenu(menu.hAnn,'Label','Save');
    menu.hAnnCnf = uimenu(menu.hAnn,'Label','Config');
    menu.hAnnMrg = uimenu(menu.hAnn,'Label','Merge');
    menu.hTrk = uimenu(hFig,'Label','Tracking');
    menu.hTrkOpn = uimenu(menu.hTrk,'Label','Open');
    menu.hTrkCls = uimenu(menu.hTrk,'Label','Close');
    
    % set hFig to visible upon completion
    set(hFig,'Visible','on'); drawnow;
    
    
    function keyPress( h, evnt )
      char=int8(evnt.Character); if(isempty(char)), char=0; end;
      % arrow keys control either video, main slider, or bottom slider
      if( char>=28 && char<=31 ) % L/R/U/D = 28/29/30/31
        if( h==hFig )
          if(char>=30), flag=0; else flag=double(char-28)*2-1; end
          dispApi.setSpeedCb(flag);
        elseif( h~=pBot.hSl && h~=pMid.hSl )
          flag = mod(double(char),2)*2-1;
          annApi.setFrame(flag);
        end
        return;
      end
      % all other keys require an annotation to be loaded
      if(isempty(A)), return; end; bp=[];
      % '-'/'=' control jumps, ','/'.' control moveLeft/Right
      if(char=='-'), bp='prevBeh'; end
      if(char=='='), bp='nextBeh'; end
      if(char==','), bp='moveLeft'; end
      if(char=='.'), bp='moveRight'; end
      if(~isempty(bp)), annApi.buttonPress(bp); return; end
      % make bindings for behavior creation
      [member,type]=ismember( char, int8(A.getKeys()) );
      if(member), annApi.insertBh(type); return; end;
    end
    
    function figResized( h, evnt ) %#ok<INUSD>
      % aspect ratio of video
      if(isempty(dispApi)), info=[]; else info=dispApi.getInfo(); end
      if(isempty(info)), ar=4/3; else ar=info.width/info.height; end
      % enforce minimum size (min width=500+pad*2)
      pos=get(hFig,ps); pad=8; htBot=26; htSl=20; htTop=20;
      mWd=500+pad*2; mHt=500/ar+htBot+htSl+htTop+pad*2;
      persistent posPrv;
      if(pos(3)<mWd || pos(4)<mHt && ~isempty(posPrv))
        set(hFig,ps,[posPrv(1:2) mWd mHt]); figResized(); return;
      end; posPrv=pos;
      % overall layout
      wd=pos(3)-2*pad; ht=pos(4)-2*pad-htSl-htTop-htBot;
      wd=min(wd,ht*ar); ht=min(ht,wd/ar); x=(pos(3)-wd)/2; y=pad;
      set(pBot.h,ps,[x y wd htBot]); y=y+htBot;
      set(pMid.hSl,ps,[x y wd htSl]); y=y+htSl;
      if(~isempty(pMid.hTxt)), set(pMid.hTxt,ps,[wd/2 ht]); end
      set(pMid.hAx,ps,[x y wd ht]); y=y+ht;
      set(pTop.h,ps,[x y wd htTop]);
      % position stuff in top panel
      x=10;
      set(pTop.hBehLbl,ps,[x 3 50 14]); x=x+50;
      set(pTop.hBh,ps,[x 7 140 14]); x=wd-300;
      set(pTop.hPlyLbl,ps,[x 3 40 14]); x=x+40;
      set(pTop.hPlySpd,ps,[x 3 40 14]); x=x+40;
      set(pTop.hTmLbl,ps,[x 3 30 14]); x=x+30;
      set(pTop.hTmVal,ps,[x 3 45 14]); x=x+50;
      set(pTop.hFrmLbl,ps,[x 3 35 14]); x=x+35;
      set(pTop.hFrmInd,ps,[x 3 50 16]); x=x+50;
      set(pTop.hFrmNum,ps,[x 3 60 14]);
      % position stuff in bottom panel
      x=5; wd0=wd-325;
      set(pBot.hStrm,ps,[x 5 35 20]); x=x+40;
      set(pBot.hBh,  ps,[x 5 85 20]); x=x+95;
      set(pBot.hArrL,ps,[x 4 25 20]); x=x+25;
      set(pBot.hSl, ps,[x 4 wd0 20]); x=x+wd0;
      set(pBot.hArrR,ps,[x 4 25 20]); x=x+30;
      set(pBot.hSetL,ps,[x 4 20 20]); x=x+20;
      set(pBot.hSetR,ps,[x 4 20 20]); x=x+25;
      set(pBot.hZm,  ps,[x 5 50 20]); x=x+60;
      set(pBot.hDel, ps,[x 4 20 20]);
      % update display
      if(~isempty(dispApi)); dispApi.requestUpdate(); end;
    end
    
    function exitProg( h, evnt ) %#ok<INUSD>
      menuApi.vidClose();
    end
  end

  function api = annMakeApi()
    % create api
    clrs=[]; fM=0;
    api = struct( 'updateDisp',@updateDisp, 'updateAnn',@updateAnn, ...
      'setFrame',@setFrame, 'buttonPress',@buttonPress, ...
      'insertBh',@insertBh,'setCenter',@setCenter,'dispTrack',@dispTrack );
    set( pBot.hStrm, 'callback', @(h,evnt) buttonPress('setStrm'));
    set( pBot.hBh,   'callback', @(h,evnt) buttonPress('setType'));
    set( pBot.hSetL, 'callback', @(h,evnt) buttonPress('moveLeft'));
    set( pBot.hSetR, 'callback', @(h,evnt) buttonPress('moveRight'));
    set( pBot.hDel,  'callback', @(h,evnt) buttonPress('delete'));
    set( pBot.hArrL, 'callback', @(h,evnt) buttonPress('prevBeh'));
    set( pBot.hArrR, 'callback', @(h,evnt) buttonPress('nextBeh'));
    set( pBot.hSl,   'callback', @(h,evnt) setFrame(0));
    set( pBot.hZm,   'callback', @(h,evnt) buttonPress('setZoom'));
    set( pTop.hBh,   'callback', @(h,evnt) buttonPress('gotoBeh'));
    
    function updateAnn()
      % new annotation loaded or annotation closed
      isAnn=~isempty(A); if(isAnn), en='on'; else en='off'; end;
      hAll=[pTop.hBh pBot.hBh pBot.hSetL pBot.hArrL pBot.hSl ...
        pBot.hArrR pBot.hSetR pBot.hZm pBot.hDel];
      set(hAll,'Enable',en); set([pBot.hBar pMid.hBar],'Visible',en);
      if(~isAnn), strs={''}; else strs=A.getNames(); end
      set(pBot.hBh,'Value',1,'String',strs);
      set(pTop.hBh,'Value',1,'String',{''});
      if(~isAnn), strs={''}; else strs=int2str2(1:A.nStrm()); end
      set(pBot.hStrm,'Value',1,'String',strs);
      if(isAnn), clrs=[.3 .3 .3; uniqueColors(ceil((A.k()-1)/6),6)]; end
      if(~isempty(pMid.hTxt)), set(pMid.hTxt,'String',''); end
      % update context menu for inserting behaviors
      if(isAnn), ns=A.getNames(); ks=A.getKeys(); k=A.k(); else k=0; end
      delete(pMid.hAdds); pMid.hAdds=zeros(1,k);
      ls=cell(1,k); for t=1:k, ls{t}=[ns{t} ' (' ks(t) ')']; end
      for t=1:k, pMid.hAdds(t)=uimenu(pMid.hAdd,'Label',ls{t}); end
      for t=1:k, set(pMid.hAdds(t),'callback',@(h,e) insertBh(t)); end
      % finally update display
      updateDisp();
    end
    
    function updateDisp()
      if(isempty(A)), return; end
      % get current frame / annotation info
      f=dispApi.getFrame(); id=A.getId(f); type=A.getType(id); n=A.n();
      nFrame=A.nFrame(); bs=A.getBnds(); ts=A.getTypes(); ns=A.getNames();
      % set bounds for zoomed slider
      h=pBot.hZm; s=get(h,'String'); v=get(h,'Value'); w=str2double(s{v});
      fL=max(0,fM-w/2); fR=min(nFrame,fL+w); fL=max(0,fR-w);
      % update standard GUI controls
      clr={'ForegroundColor',clrs(type,:)};
      set(pBot.hBh,'Value',type,clr{:}); ss=ns(ts);
      for i=1:n, ss{i}=sprintf('%i-%i %s',bs(i)+1,bs(i+1),ss{i}); end
      set(pTop.hBh,'String',ss,'Value',id,clr{:});
      if( nFrame==1 ), set(pBot.hSl,'Enable','off'); else
        set(pBot.hSl,'Min',fL,'Max',fR-1,'Value',f,'Enable','on');
        s=1/(fR-fL-1); set(pBot.hSl,'SliderStep',[s s]);
      end
      % display text label containing info about every stream
      strm0=get(pBot.hStrm,'Value'); nSt=A.nStrm(); s=cell(1,nSt);
      for i=1:nSt, A.setStrm(i); j=A.getId(f);
        s{i}=A.getName(j); if(i==strm0 && nSt>1), s{i}=['[' s{i} ']']; end
        s{i}=['\color[rgb]{' num2str(clrs(A.getType(j),:)) '}' s{i} ' / '];
      end
      s=[s{:}]; s=s(1:end-3); s(s=='_')='-'; A.setStrm(strm0);
      set(pMid.hTxt,'String',s);
      % update hBar for zoomed slider
      idL=A.getId(fL); idR=A.getId(fR-1);
      bs1=[fL bs(idL+1:idR) fR]-fL; ts1=ts(idL:idR);
      colBar( pBot.hBar, pBot.hSl, bs1, ts1, 4 );
      % update hBar for main slider
      colBar( pMid.hBar, pMid.hSl, bs, ts, 6, fL, fR );
      % finally backup annotation
      menuApi.annBackup();
      
      function colBar( hBar, hSl, bs, ts, h, fL, fR )
        % set position of hBar, adjust according to width of slider (8)
        p=get(hSl,'Position'); w0=16; w1=(p(3)-2*w0)/(bs(end)-bs(1));
        p(1)=p(1)+w0; p(2)=p(2)+p(4)-h; p(3)=p(3)-2*w0; p(4)=h;
        if(w1<8), p(1)=p(1)+4; p(3)=p(3)+round(w1)-8; end
        set(hBar,'Position',p); w=ceil(p(3)); h=ceil(p(4));
        % get hbar image
        nFrame=bs(end); bs=round(bs/nFrame*w); I=zeros(w,1);
        for i1=1:length(ts), I(bs(i1)+1:bs(i1+1),:)=ts(i1); end
        I=permute(clrs(I,:),[3 1 2]); I=I(ones(1,h),:,:);
        if(nargin==7)
          fL=round(fL/nFrame*w); fR=max(1,round(fR/nFrame*w));
          I(:,[fL+1 fR],:)=1; I([1 end],fL+1:fR,:)=1;
        end
        set(hBar,'CData',I);
      end
    end
    
    function setFrame(flag)
      assert(~isempty(A)); rng=get(pBot.hSl,{'Min','Max'});
      f = min(max(round(get(pBot.hSl,'Value')+flag),rng{1}),rng{2});
      setCenter = (f==rng{1} && f>0) || (f==rng{2} && f<A.nFrame()-1);
      set(pBot.hSl,'Value',f); dispApi.setFrame(f,0,setCenter);
    end
    
    function buttonPress( str )
      assert(~isempty(A));
      f=dispApi.getFrame(); id=A.getId(f);
      switch str
        case 'setStrm'
          strm = get(pBot.hStrm,'Value');
          A.setStrm(strm); dispApi.requestUpdate();
        case 'setType'
          type = get(pBot.hBh,'Value');
          A.setType(id,type); dispApi.requestUpdate();
        case 'moveRight'
          if(id==A.n()), return; end %id==A.getId(get(pBot.hSl,'Max'))
          A.move(id+1,f+1); dispApi.requestUpdate();
        case 'moveLeft'
          if(id==1), return; end %id==A.getId(get(pBot.hSl,'Min'))
          A.move(id,f); dispApi.requestUpdate();
        case 'delete'
          A.setType(id,1); %A.delete( id );
          dispApi.requestUpdate();
        case 'prevBeh'
          f1=A.getStart(id); if(id>1 && f==f1), f1=A.getStart(id-1); end
          dispApi.setFrame(f1,0);
        case 'nextBeh'
          f1=A.getEnd(id); if(id<A.n()), f1=f1+1; end
          dispApi.setFrame(f1,0);
        case 'setZoom'
          dispApi.setFrame(f,0)
        case 'gotoBeh'
          f1=A.getStart(get(pTop.hBh,'Value'));
          dispApi.setFrame(f1,0);
        otherwise
          assert(false);
      end
    end
    
    function insertBh( type )
      if(isempty(A)), return; end
      A.add(type,dispApi.getFrame());
      dispApi.requestUpdate();
    end
    
    function setCenter( frame ), fM=round(frame); end
    
    function hs = dispTrack( frame )
      if(isempty(trk)), hs=[]; return; end; hs0=[]; hs1=[]; hs2=[];
      cols=[0 1 0; 1 0 0; 0 0 1; 1 1 0; 0 1 1; 1 0 1];
      if(isfield(trk,'bbs')) % display detections
        bbs=trk.bbs{frame+1}; if(isempty(bbs)), bbs=zeros(0,6); end
        bbs=bbs(bbs(:,5)>0,:); n=size(bbs,1);
        hs0=zeros(1,n); rPrp={'LineWidth',2,'LineStyle','-','EdgeColor'};
        if(size(bbs,2)==6), is=mod(bbs(:,6)-1,6)+1; else is=ones(1,n); end
        for b=1:n, hs0(b)=rectangle('Position',bbs(b,1:4),rPrp{:},...
            cols(is(b),:)); end
      end
      if(isfield(trk,'Y')) % display (x,y) tracking results
        if(iscell(trk.Y)), Y=trk.Y{frame+1}; else Y=trk.Y(:,:,frame+1); end
        if(isempty(Y)), Y=zeros(0,2); end; m=size(Y,1); hs1=zeros(1,m);
        Y=max(Y,1); inf=dispApi.getInfo(); r=min(inf.width,inf.height)/70;
        Y(:,2)=min(Y(:,2),inf.height); Y(:,1)=min(Y(:,1),inf.width);
        rPrp={'LineWidth',2,'LineStyle','-','Curvature',[1 1],...
          'EdgeColor','w','FaceColor'};
        %D=pdist2(Y,Y)+diag(nan(m,1)); close=min(D)<125^2;
        %for i=1:m, if(close(i)), cols(i,:)=max(.7,cols(i,:)); end; end
        for i=1:m, hs1(i)=rectangle(rPrp{:},cols(i,:),...
            'Position',[Y(i,:)-r 2*r 2*r]); end
      end
      if(isfield(trk,'E')) % display ellipse tracking results
        if(iscell(trk.E)), E=trk.E{frame+1}; else E=trk.E(:,:,frame+1); end
        if(isempty(E)), E=zeros(0,5); end; m=size(E,1); hs2=zeros(3,m);
        hold on; for i=1:m, [hs2(1,i),hs2(2,i),hs2(3,i)]=plotEllipse(...
            E(i,1),E(i,2),E(i,3),E(i,4),E(i,5),cols(i,:),[],2); end
        hold off; hs2=hs2(:)';
      end
      hs = [hs0 hs1 hs2];
    end
  end

  function api = dispMakeApi()
    % create api
    [sr, audio, info, nFrame, speed, curInd, hs, ...
      hImg, needUpdate, prevTime, looping ]=deal([]);
    api = struct( 'setVid',@setVid, 'setAud',@setAud, ...
      'setSpeedCb',@setSpeedCb, 'getInfo',@getInfo, ...
      'getFrame',@getFrame, 'setFrame',@setFrame, ...
      'requestUpdate',@requestUpdate, 'exportVid',@exportVid );
    set(pMid.hSl,    'Callback',@(h,evnt) setFrameCb(0));
    set(pTop.hFrmInd,'Callback',@(h,evnt) setFrameCb(1));
    
    function setVid( sr1 )
      % reset local variables
      if(isstruct(sr)), sr=sr.close(); end
      if(~isempty(hs)), delete(hs); hs=[]; end
      [sr, audio, info, nFrame, speed, curInd, hs, ...
        hImg, needUpdate, prevTime, looping ]=deal([]);
      sr=sr1; nFrame=0; looping=0; speed=-1; setFrame( 0, 0 );
      % update GUI
      if(~isstruct(sr)), cla(pMid.hAx); pMid.hTxt=[]; else
        info=sr.getinfo(); nFrame=info.numFrames;
        sr.seek(0); s=max(1e-6,1/(nFrame-1)); ss={'SliderStep',[s,s]};
        if(nFrame>1), set(pMid.hSl,'Max',nFrame-1,ss{:}); end
        hImg = imshow( zeros(info.height,info.width,'uint8') );
        set(hImg,'UIContextMenu',pMid.hAdd);
        pMid.hTxt=text(0,0,'','FontSize',25,'Units','pixels',...
          'HorizontalAlignment','center', 'VerticalAlignment','top');
        %fprintf('fps of video = %f\n', info.fps); % temp display
      end
      set(pMid.hSl,'Value',0); v=(nFrame>1)+1;
      en={'off','on'}; set(pMid.hSl,'Enable',en{v});
      en={'inactive','on'}; set(pTop.hFrmInd,'Enable',en{v});
      set(pTop.hFrmInd,'String','0'); set(pTop.hTmVal,'String','0:00');
      set(pTop.hFrmNum,'String',[' / ' int2str(nFrame)]);
      % update display
      feval(get(hFig,'ResizeFcn'));
      requestUpdate();
    end
    
    function exportVid( nm )
      % prompt for range of frames to export
      prompt={'Start frame:','End frame:','Frame Skip','Quality (0-100)'};
      wi=getInfo(); dfs={'1', num2str(wi.numFrames),'1','80'};
      rng=str2double(inputdlg(prompt,'Select Export Range',1,dfs));
      if(any(isnan(rng)) || rng(1)>rng(2)), error('invalid range'); end
      f0=max(1,rng(1)); f1=min(rng(2),wi.numFrames); skip=max(1,rng(3));
      wi.codec='jpg'; wi.quality=rng(4);
      try %#ok<ALIGN> % export video
        for f=f0:skip:f1
          setFrame(f,0); I=getframe(pMid.hAx); I=I.cdata;
          c=2; I=I(1+c:end-c,1+c:end-c,:); h=size(I,1); w=size(I,2);
          if(f==f0), wi.height=h; wi.width=w; sw=seqIo(nm,'w',wi); end
          sw.addframe(I);
        end; sw.close();
      catch err, sw.close(); throw(err); end
    end
    
    function setAud(y,fs,nb)
      a = abs(1 - (length(y)/fs) / (nFrame/info.fps));
      if(a>.01), error('Audio/video mismatch.'); end
      audio.fPlay=audioplayer(y,fs,nb);
      audio.bPlay=audioplayer(flipud(y),fs,nb);
      audio.fs=fs; audio.ln=length(y); setSpeed(speed);
      requestUpdate();
    end
    
    function dispLoop()
      if(looping), return; end; looping=1;
      while( 1 )
        % exit if appropriate, or if vid not loaded do nothing
        if(~isstruct(sr) || ~isstruct(info)), looping=0; return; end
        
        % stop playing video if at begin/end
        if((speed>0&&curInd==nFrame-1) || (speed<0&&curInd==0))
          setSpeed(0); needUpdate=1;
        end
        
        % increment/decrement curInd appropriately
        if( speed~=0 )
          t=clock(); eTime=etime(t,prevTime);
          del = speed * max(10,info.fps) * min(.1,eTime);
          if( speed>0 ), del=min(del, nFrame-curInd-1 ); end
          if( speed<0 ), del=max(del, -curInd ); end
          setFrame(curInd+del, speed); prevTime=t; needUpdate=1;
        end
        
        % update display if necessary
        if(~needUpdate), looping=0; return; else
          sr.seek( round(curInd) ); I=sr.getframe();
          if(~isempty(hs)), delete(hs); hs=[]; end
          hs=annApi.dispTrack(round(curInd));
          assert(~isempty(I)); set(hImg,'CData',I);
          set(pMid.hSl,'Value',curInd); c=round(curInd/info.fps);
          set(pTop.hFrmInd,'String',int2str(round(curInd+1)));
          c0=floor(c/3600); c=mod(c,3600); c1=floor(c/60); c2=mod(c,60);
          if(~c0), set(pTop.hTmVal,'String',sprintf('%i:%02i',c1,c2)); else
            set(pTop.hTmVal,'String',sprintf('%i:%02i:%02i',c0,c1,c2)); end
          annApi.updateDisp(); needUpdate=false; drawnow();
        end
      end
    end
    
    function setSpeedCb( flag )
      if(~isstruct(sr)),return; end
      if( flag==0 )
        setSpeed( 0 );
      elseif( speed==0 )
        setSpeed( flag ); prevTime=clock();
      elseif( sign(speed)==flag && abs(speed)<2^12 )
        setSpeed( speed*2 );
      elseif( sign(speed)~=flag && abs(speed)>1/8 )
        setSpeed( speed/2 );
      elseif( sign(speed)~=flag )
        setSpeed( 0 );
      end
      requestUpdate();
    end
    
    function setSpeed( speed1 )
      if((speed1>0&&curInd==nFrame-1)||(speed1<0&&curInd==0)),speed1=0;end
      speed=speed1; p=abs(speed); if(speed<0), ss='-'; else ss=''; end
      if(p<1 && p~=0), s=['1/' int2str(1/p)]; else s=int2str(p); end
      set(pTop.hPlySpd,'String',[ss s 'x']);
      if(~isempty(audio))
        stop(audio.fPlay); stop(audio.bPlay); if(speed==0), return; end;
        st=curInd/(nFrame-1); if(speed<0), st=1-st; end; st=st*audio.ln+1;
        if(speed>0), plr=audio.fPlay; else plr=audio.bPlay; end;
        set(plr,'SampleRate',audio.fs*p); play(plr,st);
      end
    end
    
    function setFrameCb(flag)
      if( flag==0 )
        f=round(get(pMid.hSl,'Value')); set(pMid.hSl,'Value',f);
      elseif(flag==1)
        f=str2double(get(pTop.hFrmInd,'String'));
        if(isnan(f)), requestUpdate(); return; else f=f-1; end
      end
      setFrame(f,0);
    end
    
    function setFrame( curInd1, speed1, setCenter )
      curInd=max(0,min(curInd1,nFrame-1));
      if( speed~=speed1 ), setSpeed(speed1); end
      if(nargin<3 || setCenter), annApi.setCenter(curInd); end
      requestUpdate();
    end
    
    function requestUpdate(), needUpdate=true; dispLoop(); end
    
    function info1 = getInfo(), info1=info; end
    
    function curInd1 = getFrame(), curInd1=round(curInd); end
  end

  function api = menuMakeApi()
    % create api
    [fVid, fAnn, lastSave]=deal([]);
    api = struct('vidClose',@vidClose, 'annClose',@annClose, ...
      'vidOpen',@vidOpen, 'audOpen',@audOpen, 'trkOpen',@trkOpen, ...
      'annOpen',@annOpen, 'annBackup',@annBackup );
    set(menu.hVidOpn,'Callback',@(h,envt) vidOpen(1) );
    set(menu.hVidsOpn,'Callback',@(h,envt) vidOpen(2) );
    set(menu.hVidExp,'Callback',@(h,envt) vidExport() );
    set(menu.hVidCls,'Callback',@(h,envt) vidClose() );
    set(menu.hVidInf,'Callback',@(h,envt) vidInfo() );
    set(menu.hVidAud,'Callback',@(h,envt) audOpen() );
    set(menu.hAnnNew,'Callback',@(h,envt) annNew(0) );
    set(menu.hAnnOpn,'Callback',@(h,envt) annOpen(0) );
    set(menu.hAnnCls,'Callback',@(h,envt) annClose() );
    set(menu.hAnnSav,'Callback',@(h,envt) annSave() );
    set(menu.hAnnCnf,'Callback',@(h,envt) annNew(1) );
    set(menu.hAnnMrg,'Callback',@(h,envt) annOpen(1) );
    set(menu.hTrkOpn,'Callback',@(h,envt) trkOpen(0) );
    set(menu.hTrkCls,'Callback',@(h,envt) trkOpen([]) );
    
    function updateMenus()
      m=menu; if(isempty(fVid)), en='off'; else en='on'; end
      set([m.hVidExp m.hVidCls m.hVidInf m.hVidAud m.hAnnNew m.hAnnOpn ...
        m.hTrkOpn m.hTrkCls],'Enable',en);
      if(isempty(A)), en='off'; else en='on'; end
      set([m.hAnnSav m.hAnnCls m.hAnnCnf m.hAnnMrg],'Enable',en);
      nm='Caltech Behavior Annotator';
      if(~isempty(fVid)), [~,nm1]=fileparts(fVid); nm=[nm ' - ' nm1]; end
      set(hFig,'Name',nm); annApi.updateAnn(); dispApi.requestUpdate();
    end
    
    function vidClose()
      if(~isempty(A)), annClose(); end; trkOpen([]);
      fVid=[]; dispApi.setVid([]); updateMenus();
    end
    
    function vidOpen( flag )
      if(isempty(fVid)), d='.'; else d=fileparts(fVid); end
      if(all(ischar(flag)))
        [d,f]=fileparts(flag); if(isempty(d)), d='.'; end;
        d=[d '/']; f=[f '.seq']; flag=1;
      elseif( flag==1 )
        [f,d]=uigetfile('*.seq','Select video',[d '/*.seq']);
      elseif( flag==2 )
        [f,d]=uigetfile('*.seq','Select first video',[d '/*.seq']);
        [f2,d2]=uigetfile('*.seq','Select second video',[d '/*.seq']);
        if( f2==0 ), return; end
      end
      if( f==0 ), return; end; vidClose(); fVid=[d f];
      try
        if( flag==1 ), sr=seqIo(fVid,'r'); else
          sr=seqIo({fVid,[d2 f2]},'rdual'); end
        dispApi.setVid(sr); updateMenus();
      catch er
        errordlg(['Failed to load: ' fVid '. ' er.message],'Error');
        fVid=[]; return;
      end
    end
    
    function vidInfo()
      info=dispApi.getInfo(); txt=evalc('disp(info);'); %#ok<NASGU>
      while(txt(end)==10), txt=txt(1:end-1); end; txt=[char([10 10]) txt];
      pos=get(hFig,'Position'); pos(1:2)=pos(1:2)+100; pos(3:4)=[400 400];
      h=figure('NumberTitle','off', 'Toolbar','auto', ...
        'Color','k', 'MenuBar','none', 'Visible','on', ...
        'Name','', 'Resize','off','Position',pos); pos(1:2)=0;
      uicontrol(h,'Style','text','FontSize',10,'BackgroundColor','w',...
        'HorizontalAlignment','left','Position',pos,'String',txt,...
        'FontName','FixedWidth');
    end
    
    function vidExport()
      assert(~isempty(fVid)); fNm=[fVid(1:end-4) '-copy.seq'];
      [f,d] = uiputfile('*.seq','Select export file',fNm);
      if(f==0), return; end; f=[d f];
      try dispApi.exportVid(f); catch er
        errordlg(['Failed to export: ' f '. ' er.message],'Error'); end
    end
    
    function audOpen( fAud )
      if( nargin==0 ), [f,d]=uigetfile('*.wav','Select audio',...
          [fVid(1:end-3) 'wav']); if(f==0), return; end; fAud=[d f]; end
      try
        [y,fs,nb]=wavread(fAud); dispApi.setAud(y,fs,nb); %#ok<REMFF1>
      catch er
        errordlg(['Failed to load: ' fAud '. ' er.message],'Error');
      end
    end
    
    function annClose()
      assert(~isempty(A)); qstr='Save Current Annotation?';
      button = questdlg(qstr,'Save','yes','no','yes');
      if(strcmp(button,'yes')); annSave(); end
      [fAnn,A,lastSave]=deal([]); updateMenus();
    end
    
    function annOpen( flag )
      assert(~isempty(fVid)); A1=A; if(~isempty(A)), annClose(); end; e='';
      if( all(ischar(flag)) ), f=flag; flag=0;
        [d,f,e]=fileparts(f); if(isempty(d)), d='.'; end; d=[d '/'];
        if(isempty(e) && exist([d f '.txt'],'file')), e='.txt'; end
        if(isempty(e) && exist([d f '.bAnn'],'file')), e='.bAnn'; end
      else
        if(isempty(fAnn)), fAnn=[fVid(1:end-3) 'txt']; end
        [f,d]=uigetfile('*.txt;*.bAnn','Select Annotation',fAnn);
      end
      if( f==0 ), return; end; fAnn=[d f e];
      try
        if( flag==1 )
          A=A1; assert(~isempty(A)); A.merge(fAnn);
        elseif( flag==0 )
          A=behaviorData('load',fAnn);
          info=dispApi.getInfo(); nFrame=info.numFrames;
          if(A.nFrame()~=nFrame), error('Annotation/video mismatch.'); end
        end
        updateMenus();
      catch er
        errordlg(['Failed to load: ' fAnn '. ' er.message],'Error');
        [fAnn,A,lastSave]=deal([]); return;
      end
    end
    
    function annSave()
      assert(~isempty(fVid) && ~isempty(A) && ~isempty(fAnn));
      [f,d] = uiputfile('*.txt;*.bAnn','Select annotation',fAnn);
      if( f==0 ), return; end; fAnn=[d f]; A.save(fAnn);
    end
    
    function annNew( update )
      assert(~isempty(fVid)); A1=A; if(~isempty(A)), annClose(); end
      fNm=[fileparts(fVid) '/config.txt'];
      [f,d] = uigetfile('*.txt','Select config file',fNm);
      if( f==0 ), return; end; f=[d f]; fAnn=[fVid(1:end-3) 'txt'];
      try
        if( update )
          A=A1; assert(~isempty(A)); A.recreate(f); updateMenus();
        else
          info=dispApi.getInfo(); nFrame=info.numFrames;
          A=behaviorData('create',f,nFrame); updateMenus();
        end
      catch er
        errordlg(er.message, 'File Error'); A=[];
      end
    end
    
    function annBackup()
      if( isempty(lastSave) || etime(clock,lastSave)>60 )
        [d,f]=fileparts(fAnn); f=[d '/' f '-backup.txt'];
        assert(~isempty(A)); A.save(f); lastSave=clock();
      end
    end
    
    function trkOpen( flag )
      if(isempty(flag)), trk=[]; dispApi.requestUpdate(); return; end
      if( all(ischar(flag)) ), f=flag; else fNm=[fVid(1:end-3) 'mat'];
        [f,d]=uigetfile('*.mat','Load Tracking',fNm); f=[d f];
      end
      assert(~isempty(fVid)); if(f==0), return; end
      try
        tmp=load(f); assert(any(isfield(tmp,{'Y','bbs','E'})));
        if(isfield(tmp,'Y')), trk.Y=tmp.Y; T=size(trk.Y,3);
        elseif(isfield(tmp,'bbs')), trk.bbs=tmp.bbs; T=length(trk.bbs);
        elseif(isfield(tmp,'E')), trk.E=tmp.E; T=size(trk.E,3);
        end
        info=dispApi.getInfo(); nFrame=info.numFrames;
        if(T~=nFrame), error('Tracking/video mismatch.'); end
      catch er
        trk=[]; errordlg(['Failed to load: ' f '. ' er.message],'Error');
      end
      dispApi.requestUpdate();
    end
    
  end
end
