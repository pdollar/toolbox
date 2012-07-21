function [Vx,Vy] = optFlowHorn( I1, I2, sigma, show, alpha, nIter )
% Calculate optical flow using Horn & Schunck.
%
% USAGE
%  [Vx,Vy] = optFlowHorn( I1, I2, [sigma], [show], [alpha], [nIter] )
%
% INPUTS
%  I1, I2      - input images to calculate flow between
%  sigma       - [1] amount to smooth by (may be 0)
%  show        - [0] figure to use for display (no display if == 0)
%  alpha       - [.1] smoothness constraint
%  nIter       - [500] number of iterations (speed vs accuracy)
%
% OUTPUTS
%  Vx, Vy      - x,y components of flow  [Vx>0->right, Vy>0->down]
%
% EXAMPLE
%
% See also optFlowCorr, optFlowLk
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% default parameters
if( nargin<3 || isempty(sigma)); sigma=1; end;
if( nargin<4 || isempty(show)); show=0; end;
if( nargin<5 || isempty(alpha)); alpha=.1; end;
if( nargin<6 || isempty(nIter)); nIter=500; end;

% error checking
if( ndims(I1)~=2 || ndims(I2)~=2 || any(size(I1)~=size(I2)) )
  error('Input images must be 2D and have same dimensions.'); end

% run optical flow in coarse to fine fashion
[h,w]=size(I1); nScales=floor(log2(min(h,w)))-2;
for s=1:nScales
  % get current scale and I1b and I2b at given scale
  scale=2^(nScales-s); h1=round(h/scale); w1=round(w/scale);
  if( scale==1 ), I1b=I1; I2b=I2; else
    I1b=imResample(I1,[h1 w1]); I2b=imResample(I2,[h1 w1]); end
  % smooth images
  if(sigma), I1b=single(gaussSmooth(I1b,sigma,'same')); end
  if(sigma), I2b=single(gaussSmooth(I2b,sigma,'same')); end
  % initialize Vx,Vy or upsample from previous scale
  if(s==1), Vx=zeros(h1,w1,'single'); Vy=Vx; else
    Vx=imResample(Vx,[h1 w1])*2; Vy=imResample(Vy,[h1 w1])*2; end
  % run optical flow on current scale
  [Vx,Vy]=optFlowHorn1(I1b,I2b,Vx,Vy,alpha,nIter);
end

% show quiver plot on top of reliab
if( show )
  figure(show); clf; im(I1); hold('on');
  quiver(Vx,Vy,0,'-b'); hold('off');
end

end

function [Vx,Vy] = optFlowHorn1( I1,I2,Vx,Vy,alpha,nIter )
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
% iterate updating U and V in each iter
den=1./(alpha*alpha + Ex.*Ex + Ey.*Ey); V=Vx; U=Vy;
for i = 1:nIter
  Ub=.25*(shift(U,-1,0)+shift(U,1,0)+shift(U,0,-1)+shift(U,0,1));
  Vb=.25*(shift(V,-1,0)+shift(V,1,0)+shift(V,0,-1)+shift(V,0,1));
  num=(Ex.*Ub + Ey.*Vb + Et).*den;
  U=Ub-Ex.*num; U=U(2:end-1,2:end-1);
  V=Vb-Ey.*num; V=V(2:end-1,2:end-1);
end
Vx = V; Vy = U;
end

function J = shift( I, x, y )
% shift I by -1<=x,y<=1 pixels
[h,w]=size(I); J=zeros(h+2,w+2,'single');
J(2-y:end-1-y,2-x:end-1-x)=I;
end
