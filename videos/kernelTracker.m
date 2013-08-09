function [allRct, allSim, allIc] = kernelTracker( I, prm )
% Kernel Tracker from Comaniciu, Ramesh and Meer PAMI 2003.
%
% Implements the algorithm described in "Kernel-Based Object Tracking" by
% Dorin Comaniciu, Visvanathan Ramesh and Peter Meer, PAMI 25, 564-577,
% 2003.  This is a fast tracking algorithm that utilizes a histogram
% representation of an object (in this implementation we use color
% histograms, as in the original work).  The idea is given a histogram q in
% frame t, find histogram p in frame t+1 that is most similar to q. It
% turns out that this can be formulated as a mean shift problem. Here, the
% kernel is fixed to the Epanechnikov kernel.
%
% This implementation uses mex files to optimize speed, it is significantly
% faster than  real time for a single object on a 2GHz standard laptop (as
% of 2007).
%
% If I==[], toy data is created.  If rctS==0, the user is queried to
% specify the first rectangle.  rctE, denoting the object location in the
% last frame, can optionally be specified.  If rctE is given, the model
% histogram at fraction r of the video is (1-r)*histS+r*histE where histS
% and histE are the model histograms from the first and last frame.  If
% rctE==0 rectangle in final frame is queried, if rectE==-1 it is not used.
%
% Let T denote the length of the video. Returned values are of length t,
% where t==T if the object was tracked through the whole sequence (ie sim
% does not fall below simThr), otherwise t<=T is equal to the last frame in
% which obj was found.  You can test if the object was tracked using:
%   success = (size(allRct,1)==size(I,4));
%
% USAGE
%  [allRct, allIc, allSim] = kernelTracker( [I], [prm] )
%
% INPUTS
%  I            - MxNx3xT input video
%  [prm]
%   .rctS       - [0] rectangle denoting initial object location
%   .rctE       - [-1] rectangle denoting final object location
%   .dispFlag   - [1] show interactive display
%   .scaleSrch  - [1] if true search over scale
%   .nBit       - [4] n=2^nBit, color histograms are [n x n x n]
%   .simThr     - [.7] sim thr for when obj is considered lost
%   .scaleDel   - [.9] multiplicative diff between consecutive scales
%
% OUTPUTS
%  allRct       - [t x 4] array of t locations [x,y,wd,ht]
%  allSim       - [1 x t] array of similarity measures during tracking
%  allIc        - [1 x t] cell array of cropped windows containing obj
%
% EXAMPLE
%  disp('Select a rectangular region for tracking');
%  [allRct,allSim,allIc] = kernelTracker();
%  figure(2); clf; plot(allRct);
%  figure(3); clf; montage2(allIc,struct('hasChn',true));
%
% See also
%
% Piotr's Image&Video Toolbox      Version 3.22
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

%%% get parameters (set defaults)
if( nargin<1 ); I=[]; end;
if( nargin<2 ); prm=struct(); end;
dfs = {'scaleSrch',1, 'nBit',4, 'simThr',.7, ...
  'dispFlag',1, 'scaleDel',.9, 'rctS',0, 'rctE',-1 };
prm = getPrmDflt( prm, dfs );
scaleSrch=prm.scaleSrch; nBit=prm.nBit; simThr=prm.simThr;
dispFlag=prm.dispFlag; scaleDel=prm.scaleDel;
rctS=prm.rctS; rctE=prm.rctE;
if(isempty(I)); I=toyData(100,1); end;

%%% get rctS and rectE if necessary
rctProp = {'EdgeColor','g','Curvature',[1 1],'LineWidth',2};
if(rctS==0); figure(1); clf; imshow(I(:,:,:,1)); rctS=getrect; end
if(rctE==0); figure(1); clf; imshow(I(:,:,:,end)); rctE=getrect; end

%%% precompute kernels for all relevant scales
rctS=round(rctS); rctS(3:4)=rctS(3:4)-mod(rctS(3:4),2);
pos1 = rctS(1:2)+rctS(3:4)/2;  wd=rctS(3);  ht=rctS(4);
[mRows,nCols,~,nFrame] = size(I);
nScaleSm = max(1,floor(log(max(10/wd,10/ht))/log(scaleDel)));
nScaleLr = max(1,floor(-log(min(nCols/wd,mRows/ht)/2)/log(scaleDel)));
nScale = nScaleSm+nScaleLr+1;  scale = nScaleSm+1;
kernel = repmat( buildKernel(wd,ht), [1 nScale] );
for s=1:nScale
  r = power(scaleDel,s-1-nScaleSm);
  kernel(s) = buildKernel( wd/r, ht/r );
end

%%% build model histogram for rctS
[Ic,Qc] = cropWindow( I(:,:,:,1), nBit, pos1, wd, ht );
qS = buildHist( Qc, kernel(scale), nBit );

%%% optionally build model histogram for rctE
if(length(rctE)==4);
  rctE=round(rctE); rctE(3:4)=rctE(3:4)-mod(rctE(3:4),2);
  posE = rctE(1:2)+rctE(3:4)/2; wdE=rctE(3);  htE=rctE(4);
  kernelE = buildKernel(wdE,htE);
  [Ic,Qc] = cropWindow( I(:,:,:,end), nBit, posE, wdE, htE ); %end
  qE = buildHist( Qc, kernelE, nBit );
else
  qE = qS;
end

%%% setup display
if( dispFlag )
  figure(1); clf; hImg=imshow(I(:,:,:,1));
  hR = rectangle('Position', rctS, rctProp{:} );
  pause(.1);
end

%%% main loop
pos = pos1;
allRct = zeros(nFrame,4); allRct(1,:)=rctS;
allIc = cell(1,nFrame); allIc{1}=Ic;
allSim = zeros(1,nFrame);
for frm = 1:nFrame
  Icur = I(:,:,:,frm);
  
  % current model (linearly interpolate)
  r=(frm-1)/nFrame; q = qS*(1-r) + qE*r;
  
  if( scaleSrch )
    % search over scale
    best={}; bestSim=-1; pos1=pos;
    for s=max(1,scale-1):min(nScale,scale+1)
      [p,pos,Ic,sim]=kernelTracker1(Icur,q,pos1,kernel(s),nBit);
      if( sim>bestSim ); best={p,pos,Ic,s}; bestSim=sim; end;
    end
    [~,pos,Ic,scale]=deal(best{:});
    wd=kernel(scale).wd; ht=kernel(scale).ht;
    
  else
    % otherwise just do meanshift once
    [~,pos,Ic,bestSim]=kernelTracker1(Icur,q,pos,kernel(scale),nBit);
  end
  
  % record results
  if( bestSim<simThr ); break; end;
  rctC=[pos(1)-wd/2 pos(2)-ht/2 wd, ht ];
  allIc{frm}=Ic;  allRct(frm,:)=rctC;
  allSim(frm)=bestSim;
  
  % display
  if( dispFlag )
    set(hImg,'CData',Icur); title(['bestSim=' num2str(bestSim)]);
    delete(hR); hR=rectangle('Position', rctC, rctProp{:} );
    if(0); waitforbuttonpress; else drawnow; end
  end
end

%%% finalize & display
if( bestSim<simThr ); frm=frm-1; end;
allIc=allIc(1:frm); allRct=allRct(1:frm,:); allSim=allSim(1:frm);
if( dispFlag )
  if( bestSim<simThr ); disp('lost target'); end
  disp( ['final sim = ' num2str(bestSim) ] );
end

end

function [p,pos,Ic,sim] = kernelTracker1( I, q, pos, kernel, nBit )

mRows=size(I,1); nCols=size(I,2);
wd=kernel.wd; wd2=wd/2;
ht=kernel.ht; ht2=ht/2;
xs=kernel.xs; ys=kernel.ys;
for iter=1:1000
  posPrev = pos;
  
  % check if pos in bounds
  rct = [pos(1)-wd/2 pos(2)-ht/2 wd, ht ];
  if( rct(1)<1 || rct(2)<1 || (rct(1)+wd)>nCols || (rct(2)+ht)>mRows )
    pos=posPrev; p=[]; Ic=[]; sim=eps; return;
  end
  
  % crop window / compute histogram
  [Ic,Qc] = cropWindow( I, nBit, pos, wd, ht );
  p = buildHist( Qc, kernel, nBit );
  if( iter==20 ); break; end;
  
  % compute meanshift step
  w = ktComputeW_c( Qc, q, p, nBit );
  posDel = [sum(xs.*w)*wd2, sum(ys.*w)*ht2] / (sum(w)+eps);
  posDel = round(posDel+.1);
  if(all(posDel==0)); break; end;
  pos = pos + posDel;
end
locs=p>0; sim=sum( sqrt(q(locs).*p(locs)) );
end

function kernel = buildKernel( wd, ht )
wd = round(wd/2)*2;  xs = linspace(-1,1,wd);
ht = round(ht/2)*2;  ys = linspace(-1,1,ht);
[ys,xs] = ndgrid(ys,xs); xs=xs(:); ys=ys(:);
xMag = ys.*ys + xs.*xs;  xMag(xMag>1) = 1;
K = 2/pi * (1-xMag);  sumK=sum(K);
kernel = struct( 'K',K, 'sumK',sumK, 'xs',xs, 'ys',ys, 'wd',wd, 'ht',ht );
end

function p = buildHist( Qc, kernel, nBit )
p = ktHistcRgb_c( Qc, kernel.K, nBit ) / kernel.sumK;
if(0); p=gaussSmooth(p,.5,'same',2); p=p*(1/sum(p(:))); end;
end

function [Ic,Qc] = cropWindow( I, nBit, pos, wd, ht )
row = pos(2)-ht/2;  col = pos(1)-wd/2;
Ic = I(row:row+ht-1,col:col+wd-1,:);
if(nargout==2); Qc=bitshift(reshape(Ic,[],3),nBit-8); end;
end

function I = toyData( n, sigma )
I1 = imresize(imread('peppers.png'),[256 256],'bilinear');
I=ones(512,512,3,n,'uint8')*100;
pos = round(gaussSmooth(randn(2,n)*80,[0 4]))+128;
for i=1:n
  I((1:256)+pos(1,i),(1:256)+pos(2,i),:,i)=I1;
  I1 = uint8(double(I1) + randn(size(I1))*sigma);
end;
I=I((1:256)+128,(1:256)+128,:,:);
end

% % debugging code
% if( debug )
%   figure(1);
%   subplot(2,3,2); image( Ic ); subplot(2,3,1); image(Icur);
%   rectangle('Position', posToRct(pos0,wd,ht), rctProp{:} );
%   subplot(2,3,3); imagesc( reshape(w,wd,ht), [0 5] ); colormap gray;
%   subplot(2,3,4); montage2( q ); subplot(2,3,5); montage2( p1 );
%   waitforbuttonpress;
% end

% % search over 9 locations (with fixed scale)
% if( locSrch )
%   best={};  bestSim=0.0;  pos1=pos;
%   for lr=-1:1
%     for ud=-1:1
%       posSt = pos1 + [wd*lr ht*ud];
%       [p,pos,Ic,sim] = kernelTracker1(Icur,q,posSt,kernel(scale),nBit);
%       if( sim>bestSim ); best={p,pos,Ic}; bestSim=sim; end;
%     end
%   end
%   [p,pos,Ic]=deal(best{:});
% end

%%% background histogram -- seems kind of useless, removed
% if( 0 )
%   bgSiz = 3; bgImp = 2;
%   rctBgStr = max([1 1],rctS(1:2)-rctS(3:4)*(bgSiz/2-.5));
%   rctBgEnd = min([nCols mRows],rctS(1:2)+rctS(3:4)*(bgSiz/2+.5));
%   rctBg = [rctBgStr rctBgEnd-rctBgStr+1];
%   posBg = rctBg(1:2)+rctBg(3:4)/2;  wdBg=rctBg(3);  htBg=rctBg(4);
%   [IcBg,QcBg] = cropWindow( I(:,:,:,1), nBit, posBg, wdBg, htBg );
%   wtBg = double( reshape(kernel.K,ht,wd)==0 );
%   pre=rctS(1:2)-rctBg(1:2);  pst=rctBg(3:4)-rctS(3:4)-pre;
%   wtBg = padarray( wtBg, fliplr(pre), 1, 'pre' );
%   wtBg = padarray( wtBg, fliplr(pst), 1, 'post' );
%   pBg = buildHist( QcBg, wtBg, [], nBit );
%   pWts = min( 1, max(pBg(:))/bgImp./pBg );
%   if(0); montage2(pWts); impixelinfo; return; end
% else
%   pWts=[];
% end;
% if(~isempty(pWts)); p = p .* pWts; end; % in buildHistogram
