function seqPlayer( fName, dispFunc )
% Simple GUI to play seq files.
%
% Use arrow keys to play the video. Controls are as follows:
% (1) If stopped: [L] play backward, [R] play forward
% (2) If playing forward: [L] halve speed, [R] double speed, [U/D] stop
% (3) If playing backward: [L] double speed, [R] halve speed,[U/D] stop
% You can explicitly enter a frame or use the slider to jump in the video.
%
% One can pass in a function handle dispFunc, where "hs=dispFunc(frame)"
% performs additional custom display for the given frame (and returns the
% handles for any created objects).
%
% USAGE
%  seqPlayer( [fName], [dispFunc] )
%
% INPUTS
%  fName    - optional seq file to load
%  dispFunc - allow custom display per frame
%
% OUTPUTS
%
% EXAMPLE
%  load images; [h,w,n]=size(video);
%  info=struct('height',h,'width',w,'codec','monojpg','fps',20);
%  sw=seqIo('video','w',info); for t=1:n, sw.addframe(video(:,:,t)); end
%  sw.close(); seqPlayer('video');
%
% See also SEQIO
%
% Piotr's Image&Video Toolbox      Version 2.30
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if(nargin<1), fName=[]; end
if(nargin<2), dispFunc=[]; end

% handles to gui objects / other globals
[hFig,menu,pTop,pMid,dispApi] = deal([]);

% initialize all
makeLayout();
menuApi = menuMakeApi();
dispApi = dispMakeApi();
menuApi.vidClose();

% open vid if given
if(~isempty(fName)), menuApi.vidOpen(fName); end


  function makeLayout()
    % common properties
    name = 'Seq Player';
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
    
    % mid panel
    pMid.hAx=axes(units{:},'Parent',hFig,'XTick',[],'YTick',[]);
    pMid.hSl=uicontrol(hFig,'Style','slider','Min',0,'Max',1,bg,'k');
    btnPrp=[units,{'Style','pushbutton', bg,[.9 .9 .9],fs,9,st}];
    pMid.hLf=uicontrol(hFig,'FontWeight','bold',btnPrp{:},'<<');
    pMid.hRt=uicontrol(hFig,'FontWeight','bold',btnPrp{:},'>>');
    imshow(0);
    
    % top panel
    pnlProp = [units {bg,[.1 .1 .1],'BorderType','none'}];
    txtPrp = {'Style','text',bg,[.1 .1 .1],fg,'w',ha};
    edtPrp = {'Style','edit',bg,[.1 .1 .1],fg,'w',ha};
    pTop.h = uipanel(pnlProp{:},'Parent',hFig);
    pTop.hFrmLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'frame:');
    pTop.hFrmInd=uicontrol(pTop.h,edtPrp{:},'Right');
    pTop.hTmLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'time:');
    pTop.hTmVal=uicontrol(pTop.h,txtPrp{:},'Left');
    pTop.hFrmNum=uicontrol(pTop.h,txtPrp{:},'Left');
    pTop.hPlyLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'speed:');
    pTop.hPlySpd=uicontrol(pTop.h,txtPrp{:},'Left',st,'0x');
    
    % set the keyPressFcn for all focusable components (except popupmenus)
    set( [hFig pMid.hSl pMid.hLf pMid.hRt], 'keyPressFcn',@keyPress );
    
    % create menus
    menu.hVid = uimenu(hFig,'Label','Video');
    menu.hVidOpn = uimenu(menu.hVid,'Label','Open');
    menu.hVidsOpn = uimenu(menu.hVid,'Label','Open dual');
    menu.hVidCls = uimenu(menu.hVid,'Label','Close');
    menu.hVidAud = uimenu(menu.hVid,'Label','Audio');
    
    % set hFig to visible upon completion
    set(hFig,'Visible','on'); drawnow;
    
    
    function keyPress( h, evnt ) %#ok<INUSL>
      char=int8(evnt.Character); if(isempty(char)), char=0; end;
      if( char>=28 && char<=31 ) % L/R/U/D = 28/29/30/31
        if(char>=30), flag=0; else flag=double(char-28)*2-1; end
        dispApi.setSpeedCb(flag);
      end
    end
    
    function figResized( h, evnt ) %#ok<INUSD>
      % aspect ratio of video
      if(isempty(dispApi)), info=[]; else info=dispApi.getInfo(); end
      if(isempty(info)), ar=4/3; else ar=info.width/info.height; end
      % enforce minimum size (min width=500+pad*2)
      pos=get(hFig,ps); pad=8; htSl=20; htTop=20;
      mWd=500+pad*2; mHt=500/ar+htSl+htTop+pad*2;
      persistent posPrv;
      if(pos(3)<mWd || pos(4)<mHt && ~isempty(posPrv))
        set(hFig,ps,[posPrv(1:2) mWd mHt]); figResized(); return;
      end; posPrv=pos;
      % overall layout
      wd=pos(3)-2*pad; ht=pos(4)-2*pad-htSl-htTop;
      wd=min(wd,ht*ar); ht=min(ht,wd/ar); x=(pos(3)-wd)/2; y=pad;
      set(pMid.hLf,ps,[x y 22 htSl]);
      set(pMid.hSl,ps,[x+22 y wd-44 htSl]);
      set(pMid.hRt,ps,[x+wd-22 y 22 htSl]); y=y+htSl;
      set(pMid.hAx,ps,[x y wd ht]); y=y+ht;
      set(pTop.h,ps,[x y wd htTop]);
      % position stuff in top panel
      x=10;
      set(pTop.hPlyLbl,ps,[x 3 40 14]); x=x+40;
      set(pTop.hPlySpd,ps,[x 3 40 14]); x=x+40;
      set(pTop.hTmLbl,ps,[x 3 30 14]); x=x+30;
      set(pTop.hTmVal,ps,[x 3 35 14]); x=x+40;
      set(pTop.hFrmLbl,ps,[x 3 35 14]); x=x+35;
      set(pTop.hFrmInd,ps,[x 3 40 16]); x=x+40;
      set(pTop.hFrmNum,ps,[x 3 40 14]);
      % update display
      if(~isempty(dispApi)); dispApi.requestUpdate(); end;
    end
    
    function exitProg( h, evnt ) %#ok<INUSD>
      menuApi.vidClose();
    end
  end

  function api = dispMakeApi()
    % create api
    [sr, audio, info, nFrame, speed, curInd, hs, ...
      hImg, needUpdate, prevTime, looping ]=deal([]);
    api = struct( 'setVid',@setVid, 'setAud',@setAud, ...
      'setSpeedCb',@setSpeedCb, 'getInfo',@getInfo, ...
      'getFrame',@getFrame, 'requestUpdate',@requestUpdate );
    set(pMid.hSl,    'Callback',@(h,evnt) setFrameCb(0));
    set(pTop.hFrmInd,'Callback',@(h,evnt) setFrameCb(1));
    set(pMid.hLf, 'Callback',@(h,evnt) setSpeedCb(-1));
    set(pMid.hRt, 'Callback',@(h,evnt) setSpeedCb(+1));
    
    function setVid( vr1 )
      % reset local variables
      if(isstruct(sr)), sr=sr.close(); end
      if(~isempty(hs)), delete(hs); hs=[]; end
      [sr, audio, info, nFrame, speed, curInd, hs, ...
        hImg, needUpdate, prevTime, looping ]=deal([]);
      sr=vr1; nFrame=0; looping=0; speed=-1; setFrame( 0, 0 );
      % update GUI
      if(~isstruct(sr)), cla(pMid.hAx); else
        info=sr.getinfo(); nFrame=info.numFrames;
        sr.seek(0); s=1/(nFrame-1); ss={'SliderStep',[s,s]};
        if(nFrame>1), set(pMid.hSl,'Max',nFrame-1,ss{:}); end
        hImg = imshow( zeros(info.height,info.width) );
      end
      set(pMid.hSl,'Value',0); v=(nFrame>1)+1;
      en={'off','on'}; set([pMid.hSl pMid.hLf pMid.hRt],'Enable',en{v});
      en={'inactive','on'}; set(pTop.hFrmInd,'Enable',en{v});
      set(pTop.hFrmInd,'String','0'); set(pTop.hTmVal,'String','0:00');
      set(pTop.hFrmNum,'String',[' / ' int2str(nFrame)]);
      % update display
      feval(get(hFig,'ResizeFcn'));
      requestUpdate();
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
        if(~isstruct(sr)), looping=0; return; end
        
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
          if(~isempty(dispFunc)), hs=dispFunc(round(curInd)); end
          assert(~isempty(I)); set(hImg,'CData',I);
          set(pMid.hSl,'Value',curInd);
          set(pTop.hFrmInd,'String',int2str(round(curInd+1)));
          c=round(curInd/info.fps); c1=floor(c/60); c2=mod(c,60);
          set(pTop.hTmVal,'String',sprintf('%i:%02i',c1,c2));
          needUpdate=false; drawnow();
        end
      end
    end
    
    function setSpeedCb( flag )
      if(~isstruct(sr)),return; end
      if( flag==0 )
        setSpeed( 0 );
      elseif( speed==0 )
        setSpeed( flag ); prevTime=clock();
      elseif( sign(speed)==flag && abs(speed)<256 )
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
    
    function setFrameCb( flag )
      if( flag==0 )
        f=round(get(pMid.hSl,'Value')); set(pMid.hSl,'Value',f);
      elseif(flag==1)
        f=str2double(get(pTop.hFrmInd,'String'));
        if(isnan(f)), requestUpdate(); return; else f=f-1; end
      end
      setFrame(f,0); requestUpdate();
    end
    
    function setFrame( curInd1, speed1 )
      curInd=max(0,min(curInd1,nFrame-1));
      if( speed~=speed1 ), setSpeed(speed1); end
    end
    
    function requestUpdate(), needUpdate=true; dispLoop(); end
    
    function info1 = getInfo(), info1=info; end
    
    function curInd1 = getFrame(), curInd1=round(curInd); end
  end

  function api = menuMakeApi()
    % create api
    fVid=deal([]); dVid='.';
    api=struct('vidClose',@vidClose,'vidOpen',@vidOpen,'audOpen',@audOpen);
    set(menu.hVidOpn,'Callback',@(h,envt) vidOpen() );
    set(menu.hVidsOpn,'Callback',@(h,envt) vidsOpen() );
    set(menu.hVidCls,'Callback',@(h,envt) vidClose() );
    set(menu.hVidAud,'Callback',@(h,envt) audOpen() );
    
    function updateMenus()
      m=menu; if(isempty(fVid)), en='off'; else en='on'; end
      set([m.hVidCls m.hVidAud],'Enable',en);
      dispApi.requestUpdate();
    end
    
    function vidClose()
      fVid=[]; dispApi.setVid([]); updateMenus();
    end
    
    function vidOpen( f )
      if(nargin==1)
        [d f]=fileparts(f); if(isempty(d)), d='./'; else d=[d '/']; end
      else
        [f,d]=uigetfile([dVid '/*.seq'],'Select video');
      end
      if(f==0), return; end; vidClose(); dVid=d; fVid=f;
      try
        sr=seqIo([dVid fVid],'r');
        dispApi.setVid(sr); updateMenus();
      catch er
        errordlg(['Failed to load: ' fVid '. ' er.message],'Error');
        fVid=[]; return;
      end
    end
    
    function vidsOpen()
      [f1,d1]=uigetfile([dVid '/*.seq'],'Select first video');
      if( f1==0 ), return; end; dVid=d1;
      [f2,d2]=uigetfile([d1 '/*.seq'],'Select second video');
      if( f2==0 ), return; end; vidClose(); dVid=d1; fVid=f1;
      try
        sr=seqIo({[dVid fVid],[d2 f2]},'rdual');
        dispApi.setVid(sr); updateMenus();
      catch er
        errordlg(['Failed to load: ' fVid '. ' er.message],'Error');
        fVid=[]; return;
      end
    end
    
    function audOpen( d, f )
      if(nargin<2), [f,d]=uigetfile([dVid '/*.wav'],'Select audio'); end
      [d f]=fileparts([d f]); if(isempty(d)), d='.'; end; d(end+1)='/';
      if(f==0), return; end; f=[d f];
      try
        [y,fs,nb]=wavread(f); dispApi.setAud(y,fs,nb);
      catch er
        errordlg(['Failed to load: ' f '. ' er.message],'Error');
      end
    end
  end
end
