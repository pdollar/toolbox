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
%  nIter       - [100] number of iterations (speed vs accuracy)
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
if( nargin<6 || isempty(nIter)); nIter=1000; end;

% error checking
if( ndims(I1)~=2 || ndims(I2)~=2 || any(size(I1)~=size(I2)) )
  error('Input images must be 2D and have same dimensions.'); end

% smooth images
I1 = single(gaussSmooth(I1,sigma,'same'));
I2 = single(gaussSmooth(I2,sigma,'same'));

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

% initialize the values of U and V and iterate
den=1./(alpha*alpha + Ex.*Ex + Ey.*Ey);
[m,n]=size(I1); U=zeros(m,n,'single'); V = U;
for i = 1:nIter
  Ub=.25*(shift(U,-1,0)+shift(U,1,0)+shift(U,0,-1)+shift(U,0,1));
  Vb=.25*(shift(V,-1,0)+shift(V,1,0)+shift(V,0,-1)+shift(V,0,1));
  num=(Ex.*Ub + Ey.*Vb + Et).*den;
  U=Ub-Ex.*num; U=U(2:end-1,2:end-1);
  V=Vb-Ey.*num; V=V(2:end-1,2:end-1);
end
Vx = V; Vy = U;

% show quiver plot on top of reliab
if( show )
  figure(show); clf; im(I1); hold('on');
  quiver( Vx, Vy, 0,'-b' ); hold('off');
end

end

function J = shift( I, x, y )
% shift I by -1<=x,y<=1 pixels
[h,w]=size(I); J=zeros(h+2,w+2,'single');
J(2-y:end-1-y,2-x:end-1-x)=I;
end
