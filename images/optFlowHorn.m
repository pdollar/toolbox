function [Vx,Vy] = optFlowHorn( I1, I2, sigma, show )
% Calculate optical flow using Horn & Schunck.
%
% USAGE
%  [Vx,Vy] = optFlowHorn( I1, I2, [sigma], [show] )
%
% INPUTS
%  I1, I2      - input images to calculate flow between
%  sigma       - [1] amount to smooth by (may be 0)
%  show        - [0] figure to use for display (no display if == 0)
%
% OUTPUTS
%  Vx, Vy      - x,y components of flow  [Vx>0->right, Vy>0->down]
%
% EXAMPLE
%
% See also OPTFLOWCORR, OPTFLOWLK
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if (nargin < 3); sigma=1; end;
if (nargin < 4); show=0; end;

if( ndims(I1)~=2 || ndims(I2)~=2 )
  error('Only works for 2d input images.');
end
if( any(size(I1)~=size(I2)) )
  error('Input images must have same dimensions.');
end
I1 = gaussSmooth(I1,sigma,'smooth');
I2 = gaussSmooth(I2,sigma,'smooth');

% ALGORITHM:
[N1,N2]=size(I1);

PI1=zeros(N1+2,N2+2); PI1(2:end-1,2:end-1)=I1;
[PI11,PI12,PI13,PI14,PI15]=shifted(I1);

PI2=zeros(N1+2,N2+2); PI2(2:end-1,2:end-1)=I2;
[PI21,PI22,PI23,PI24,PI25]=shifted(I2);

Ex=clamp(0.25*((PI13+PI23+PI15+PI25)-(PI1+PI2+PI12+PI22)));
Ey=clamp(0.25*((PI12+PI22+PI15+PI25)-(PI1+PI2+PI13+PI23)));
Et=clamp(0.25*((PI2+PI22+PI23+PI25)-(PI1+PI12+PI13+PI15)));

% initialize the values of U and V;
lambda=10;
den=lambda./(1+lambda*(Ex.*Ex+Ey.*Ey));
U=zeros(N1,N2); V = U;
niter=1000;
for i = 1:niter
  [U1,U2,U3,U4,disc]=shifted(U); %#ok<NASGU>
  [V1,V2,V3,V4,disc]=shifted(V); %#ok<NASGU>

  Ub=(U1+U2+U3+U4)/4;
  Vb=(V1+V2+V3+V4)/4;

  nen=(Ex.*Ub+Ey.*Vb+Et).*den;
  Un=Ub-Ex.*nen;
  Vn=Vb-Ey.*nen;
  U=Un(2:end-1,2:end-1);
  V=Vn(2:end-1,2:end-1);
end
Vx = V; Vy = U;

% show quiver plot on top of reliab
if( show )
  figure(show); clf; im( I1 );
  hold('on'); quiver( Vx, Vy, 0,'-b' ); hold('off');
end

function I=clamp(I)
I(1,:)=0;
I(end,:)=0;
I(:,1)=0;
I(:,end)=0;

function [s1,s2,s3,s4,s5]=shifted(I)
[N1,N2]=size(I);

s1 = zeros(N1+2,N2+2);
s1(3:end,2:end-1)=I; %i-1

s2 = zeros(N1+2,N2+2);
s2(2:end-1,1:end-2)=I; %j+1

s3 = zeros(N1+2,N2+2);
s3(1:end-2,2:end-1)=I; %i+1

s4 = zeros(N1+2,N2+2);
s4(2:end-1,3:end)=I;  %j-1

s5 = zeros(N1+2,N2+2);
s5(1:end-2,1:end-2)=I; % i+1,j+1
