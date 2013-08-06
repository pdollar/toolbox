function [J,Vxs,Vys] = imagesAlignSeq( I, pFlow, type, bndThr )
% Stabilize image sequence using coarse optical flow estimation.
%
% All images in I are warped to the last frame of the sequence. If type>=0
% coarse optical flow computed via opticalFlow.m with params pFlow is used
% (with different accumulation options). If type==-1, a homography computed
% via imagesAlign.m with params pFlow is used.
%
% USAGE
%  [J,Vxs,Vys] = imagesAlignSeq( I, pFlow, [type], [bndThr] )
%
% INPUTS
%  I          - [hxwx(3xn)] input rgb sequence of length n
%  pFlow      - parameters to use for optical flow computation
%  type       - [1] accumulation type 0:naive, 1:nearest, 2:bilinear
%  bndThr     - [0] fill in black areas around image boundaries
%
% OUTPUTS
%  J          - [hxwx(3xn)] stabilized image sequence
%
% EXAMPLE
%  pFlow={'smooth',1,'radius',25,'type','LK','resample',1};
%  J = imagesAlignSeq( I, pFlow ); % I must be a valid sequence
%  IJ=[I J]; playMovie(IJ(:,:,1:3:end),15,-1000)
%
% See also opticalFlow, imagesAlign

% default parameters
if(nargin<3 || isempty(type)), type=1; end
if(nargin<4 || isempty(bndThr)), bndThr=0; end

% fill in black areas around image boundaries
[h,w,n]=size(I);
for t=1:n, if(bndThr<=0), break; end; It=I(:,:,t);
  xs=find(sum(It,1)>h*bndThr); ys=find(sum(It,2)>w*bndThr);
  pad=[ys(1)-1 h-ys(end) xs(1)-1 w-xs(end)];
  I(:,:,t)=imPad(imPad(It,-pad,0),pad,'replicate');
end
G=rgbConvert(I,'gray'); [h,w,n]=size(G); J=I;

% special case if type==-1 use homographies for alignment
if( type==-1 )
  Hs=zeros(3,3,n-1); Gref=G(:,:,end);
  for t=1:n-1, is=(1:3)+(t*3-3);
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
  [Vxt,Vyt] = accumulate(Vxs{t},Vys{t},X+Vx,Y+Vy,type);
  Vx=Vx+Vxt; Vxs{t}=Vx; Vy=Vy+Vyt; Vys{t}=Vy;
end

% transform each I by given flow
for t=1:n-1, is=(1:3)+(t*3-3); J(:,:,is) = imtransform2(I(:,:,is), ...
    [],'vs',Vxs{t},'us',Vys{t},'pad','replicate'); end
Vxs=cell2array(Vxs); Vys=cell2array(Vys);

end

function [Vx,Vy] = accumulate( Vx, Vy, X, Y, type )
% Compute flow at locations X,Y given original flow Vx,Vy.
[h,w]=size(X); XY=@(X,Y) (min(max(X,1),w)-1)*h + min(max(Y,1),h);
if( type==0 )
  % just use Vx, Vy (naive accumulation)
elseif( type==1 )
  % nearest neighbor interpolation (good accumulation)
  X=round(X); Y=round(Y); Z=XY(X,Y); Vx=Vx(Z); Vy=Vy(Z);
else
  % bilinear interpolation (best accumulation)
  Xd0=mod(X,1); Xd1=1-Xd0; Xi=X-Xd0;
  Yd0=mod(Y,1); Yd1=1-Yd0; Yi=Y-Yd0;
  W00=Xd1.*Yd1; W10=Xd0.*Yd1; W01=Xd1.*Yd0; W11=Xd0.*Yd0;
  Z00=XY(Xi,Yi); Z10=XY(Xi+1,Yi); Z01=XY(Xi,Yi+1); Z11=XY(Xi+1,Yi+1);
  Vx = W00.*Vx(Z00) + W10.*Vx(Z10) + W01.*Vx(Z01) + W11.*Vx(Z11);
  Vy = W00.*Vy(Z00) + W10.*Vy(Z10) + W01.*Vy(Z01) + W11.*Vy(Z11);
end
end
