function [J,Vxs,Vys] = imagesAlignSeq( I, pFlow, type, bndThr )
% Stabilize image sequence using coarse optical flow estimation.
%
% Perform weak image sequence stabilization as described in:
%  D. Park, C. Zitnick, D. Ramanan and P. Dollár
%  "Exploring Weak Stabilization for Motion Feature Extraction", CVPR 2013.
% The approach stabilizes coarse motion due to camera movement but leaves
% independent object motions intact. This code performs weak sequence
% stabilization only (no feature extraction), see section 3.1 of the paper.
% Please cite the above paper if you end up using the stabilization code.
%
% Optical flow is computed between all pairs of frames using opticalFlow.m
% with params 'pFlow'. Flow across multiple frames is accumulated and flow
% at integer locations at each stage is obtained either using either
% nearest neighbor (if type==1) or bilinear interpolation (if type==2)
% which is slightly more accurate but slower. Finally, all images in I are
% warped to the last frame of the sequence using the accumulated flows. If
% type==-1, a homography computed via imagesAlign.m with params pFlow is
% used instead. If videos have black boundaries use bndThr to ignore dark
% boundaries for flow estimation (with average pixel values under bndThr).
%
% USAGE
%  [J,Vxs,Vys] = imagesAlignSeq( I, pFlow, [type], [bndThr] )
%
% INPUTS
%  I          - HxWxN or HxWx3xN input image sequence
%  pFlow      - parameters to use for optical flow computation
%  type       - [1] interpolation type 1:nearest, 2:bilinear
%  bndThr     - [0] fill in black areas around image boundaries
%
% OUTPUTS
%  J          - HxWxN or HxWx3xN stabilized image sequence
%  Vxs        - HxWxN-1 x-components of flow fields
%  Vys        - HxWxN-1 y-components of flow fields
%
% EXAMPLE
%  I = seqIo(which('peds30.seq'),'toImgs'); I=I(:,:,:,1:15);
%  pFlow={'smooth',1,'radius',25,'type','LK','maxScale',1};
%  tic, J = imagesAlignSeq( I, pFlow, 1, 20 ); toc
%  playMovie([I J],15,-10,struct('hasChn',1))
%
% EXAMPLE
%  % Requires Caltech Pedestrian Dataset to be installed
%  [pth,ss,vs]=dbInfo; s=randi(length(ss)); v=randi(length(vs{s}));
%  nm=sprintf('%s/videos/set%02i/V%03i.seq',pth,ss(s),vs{s}(v));
%  f=seqIo(nm,'getinfo'); f=f.numFrames; f=randi(f-30);
%  I=seqIo(nm,'toImgs',[],1,f,f+9);
%  pFlow={'smooth',1,'radius',25,'type','LK','maxScale',1};
%  tic, J = imagesAlignSeq( I, pFlow, 1, 20 ); toc
%  playMovie([I J],15,-10,struct('hasChn',1))
%
% See also opticalFlow, imtransform2, imagesAlign
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.24
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% default parameters
if(nargin<3 || isempty(type)), type=1; end
if(nargin<4 || isempty(bndThr)), bndThr=0; end

% fill in black areas around image boundaries
[h,w,k,n]=size(I); if(n>1), assert(k==3); else n=k; k=1; end
for t=1:n, if(bndThr<=0), break; end; is=(1:k)+(t*k-k);
  xs=find(sum(sum(I(:,:,is),1),3)>k*h*bndThr);
  ys=find(sum(sum(I(:,:,is),2),3)>k*w*bndThr);
  if(isempty(xs)||isempty(ys)), error('bndThr set too high'); end
  pad=[ys(1)-1 h-ys(end) xs(1)-1 w-xs(end)];
  I(:,:,is)=imPad(imPad(I(:,:,is),-pad,0),pad,'replicate');
end
if(k==1), G=I; else G=rgbConvert(I,'gray'); end; J=I;

% special case if type==-1 use homographies for alignment
if( type==-1 )
  Hs=zeros(3,3,n-1); Gref=G(:,:,end);
  for t=1:n-1, is=(1:k)+(t*k-k);
    Hs(:,:,t) = imagesAlign(G(:,:,t),Gref,pFlow);
    J(:,:,is) = imtransform2(I(:,:,is), Hs(:,:,t),'pad','replicate');
  end; Vxs=Hs; Vys=Hs; return;
end

% compute flow between each pair of images in reverse direction
Vxs=cell(1,n-1); Vys=Vxs;
for t=1:n-1, [Vxs{t},Vys{t}]=opticalFlow(G(:,:,t+1),G(:,:,t),pFlow); end

% accumulate flow across frames
Vx=Vxs{end}; Vy=Vys{end}; [X,Y]=meshgrid(1:w,1:h);
for t=n-2:-1:1
  [Vxt,Vyt] = interpolate(Vxs{t},Vys{t},X+Vx,Y+Vy,type);
  Vx=Vx+Vxt; Vxs{t}=Vx; Vy=Vy+Vyt; Vys{t}=Vy;
end

% transform each I by given flow
for t=1:n-1, is=(1:k)+(t*k-k); J(:,:,is) = imtransform2(I(:,:,is), ...
    [],'vs',Vxs{t},'us',Vys{t},'pad','replicate'); end
if(nargout>1), Vxs=cell2array(Vxs); Vys=cell2array(Vys); end

end

function [Vx,Vy] = interpolate( Vx, Vy, X, Y, type )
% Interpolate flow fields at locations X,Y given flow fields Vx,Vy.
[h,w]=size(X); XY=@(X,Y) (min(max(X,1),w)-1)*h + min(max(Y,1),h);
if( type==1 )
  X=round(X); Y=round(Y); Z=XY(X,Y); Vx=Vx(Z); Vy=Vy(Z);
else
  Xd0=mod(X,1); Xd1=1-Xd0; Xi=X-Xd0;
  Yd0=mod(Y,1); Yd1=1-Yd0; Yi=Y-Yd0;
  W00=Xd1.*Yd1; W10=Xd0.*Yd1; W01=Xd1.*Yd0; W11=Xd0.*Yd0;
  Z00=XY(Xi,Yi); Z10=XY(Xi+1,Yi); Z01=XY(Xi,Yi+1); Z11=XY(Xi+1,Yi+1);
  Vx = W00.*Vx(Z00) + W10.*Vx(Z10) + W01.*Vx(Z01) + W11.*Vx(Z11);
  Vy = W00.*Vy(Z00) + W10.*Vy(Z10) + W01.*Vy(Z01) + W11.*Vy(Z11);
end
end
