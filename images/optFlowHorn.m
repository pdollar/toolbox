function [Vx,Vy] = optFlowHorn( I1, I2, smooth, alpha, nIter, show )
% Calculate optical flow using Horn & Schunck (mexed implementation).
%
% USAGE
%  [Vx,Vy] = optFlowHorn( I1, I2, smooth, [alpha], [nIter], [show] )
%
% INPUTS
%  I1, I2   - input images to calculate flow between
%  smooth   - smoothing radius for triangle filter (may be 0)
%  alpha    - smoothness constraint (data vs smoothness term)
%  nIter    - [500] number of iterations (speed vs accuracy)
%  show     - [0] figure to use for display (no display if == 0)
%
% OUTPUTS
%  Vx, Vy   - x,y components of flow  [Vx>0->right, Vy>0->down]
%
% EXAMPLE
%
% See also optFlowLk, convTri
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% default parameters
if( nargin<5 || isempty(nIter)); nIter=500; end;
if( nargin<6 || isempty(show)); show=0; end;

% error checking
if( ndims(I1)~=2 || ndims(I2)~=2 || any(size(I1)~=size(I2)) )
  error('Input images must be 2D and have same dimensions.'); end

% run optical flow in coarse to fine fashion
I1=single(I1); I2=single(I2);
[h,w]=size(I1); nScales=floor(log2(min(h,w)))-2;
for s=1:nScales
  % get current scale and I1b and I2b at given scale
  scale=2^(nScales-s); h1=round(h/scale); w1=round(w/scale);
  if( scale==1 ), I1b=I1; I2b=I2; else
    I1b=imResample(I1,[h1 w1]); I2b=imResample(I2,[h1 w1]); end
  % initialize Vx,Vy or upsample from previous scale
  if(s==1), Vx=zeros(h1,w1,'single'); Vy=Vx; else
    Vx=imResample(Vx,[h1 w1])*2; Vy=imResample(Vy,[h1 w1])*2; end
  % transform I1b according to current estimate of Vx and Vy
  if(s>1), I1b=imtransform2(I1b,[],'pad','none',...
      'vs',-double(Vx),'us',-double(Vy)); end
  % smooth images
  I1b=convTri(I1b,smooth); I2b=convTri(I2b,smooth);
  % run optical flow on current scale
  [Vx1,Vy1]=optFlowHorn1(I1b,I2b,alpha,nIter);
  Vx=Vx+Vx1; Vy=Vy+Vy1;
end

% show quiver plot on top of reliab
if( show )
  figure(show); clf; im(I1); hold('on');
  quiver(Vx,Vy,0,'-b'); hold('off');
end

end

function [Vx,Vy] = optFlowHorn1( I1, I2, alpha, nIter )
% compute derivatives (averaging over 2x2 neighborhoods)
A00=shift(I1,0,0); A10=shift(I1,1,0);
A01=shift(I1,0,1); A11=shift(I1,1,1);
B00=shift(I2,0,0); B10=shift(I2,1,0);
B01=shift(I2,0,1); B11=shift(I2,1,1);
Ex=0.25*((A01+B01+A11+B11)-(A00+B00+A10+B10));
Ey=0.25*((A10+B10+A11+B11)-(A00+B00+A01+B01));
Et=0.25*((B00+B10+B01+B11)-(A00+A10+A01+A11));
Ex([1 end],:)=0; Ex(:,[1 end])=0;
Ey([1 end],:)=0; Ey(:,[1 end])=0;
Et([1 end],:)=0; Et(:,[1 end])=0;
Z=1./(alpha*alpha + Ex.*Ex + Ey.*Ey);
% iterate updating Ux and Vx in each iter
if( 1 )
  [Vx,Vy]=optFlowHornMex(Ex,Ey,Et,Z,nIter);
  Vx=Vx(2:end-1,2:end-1); Vy=Vy(2:end-1,2:end-1);
else
  Vx=zeros(size(I1),'single'); Vy=Vx;
  for i = 1:nIter
    Mx=.25*(shift(Vx,-1,0)+shift(Vx,1,0)+shift(Vx,0,-1)+shift(Vx,0,1));
    My=.25*(shift(Vy,-1,0)+shift(Vy,1,0)+shift(Vy,0,-1)+shift(Vy,0,1));
    m=(Ex.*Mx+Ey.*My+Et).*Z; Vx=Mx-Ex.*m; Vy=My-Ey.*m;
    Vx=Vx(2:end-1,2:end-1); Vy=Vy(2:end-1,2:end-1);
  end
end
end

function J = shift( I, y, x )
% shift I by -1<=x,y<=1 pixels
[h,w]=size(I); J=zeros(h+2,w+2,'single');
J(2-y:end-1-y,2-x:end-1-x)=I;
end
