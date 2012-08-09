function [Vx,Vy,reliab]=optFlowLk( I1, I2, rad, sigma, thr, show )
% Calculate optical flow using Lucas & Kanade.  Fast, parallel code.
%
% USAGE
%  [Vx,Vy,reliab]=optFlowLk( I1,I2,rad,[sigma],[thr],[show] )
%
% INPUTS
%  I1, I2  - input images to calculate flow between
%  rad     - window radius for hard window (uses convTri)
%  sigma   - [1] amount to smooth by (may be 0)
%  thr     - [3e-6] ABSOLUTE reliability threshold (min eigenvalue)
%  show    - [0] figure to use for display (no display if == 0)
%
% OUTPUTS
%  Vx, Vy  - x,y components of flow  [Vx>0->right, Vy>0->down]
%  reliab  - reliability of flow in given window (cornerness of window)
%
% EXAMPLE
%  % create square + translated square (B) + rotated square (C)
%  A=zeros(50,50); A(16:35,16:35)=1;
%  B=zeros(50,50); B(17:36,17:36)=1;
%  C=imrotate(A,5,'bil','crop');
%  optFlowLk( A, B, 6, 3, 3e-6, 1 );
%  optFlowLk( A, C, 6, 3, 3e-6, 2 );
%  % compare on stored real images (of mice)
%  load optFlowData;
%  [Vx,Vy,reliab] = optFlowLk( I5A, I5B, 5, 1.2, 3e-6, 1 );
%  [Vx,Vy,reliab] = optFlowCorr( I5A, I5B, 3, 5, 1.2, .01, 2 );
%  [Vx,Vy] = optFlowHorn( I5A, I5B, 2, 3, 2 );
%
% See also optFlowHorn, optFlowCorr, convTri
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(sigma)); sigma=1; end
if( nargin<5 || isempty(thr)); thr=3e-6; end
if( nargin<6 || isempty(show)); show=0; end

% error checking
if( ndims(I1)~=2 || ndims(I2)~=2 || any(size(I1)~=size(I2)) )
  error('Input images must be 2D and have same dimensions.'); end

% convert to single in range [0,1]
if(isa(I1,'uint8')), I1=single(I1)/255; I2=single(I2)/255; else
  if(~isa(I1,'single')), I1=single(I1); I2=single(I2); end
  Is=[I1(:); I2(:)]; v0=min(Is); v1=max(Is);
  if(v0<0 || v1>1), I1=(I1-v0)/(v1-v0); I2=(I2-v0)/(v1-v0); end
end

% smooth images using convTri
if(sigma), r=ceil(sqrt(6*sigma*sigma+1)-1);
  I1=convTri(I1,r); I2=convTri(I2,r); end

% Compute components of outer product of gradient of frame 1
[Gx,Gy]=gradient2(I1); Gxx=Gx.^2; Gxy=Gx.*Gy; Gyy=Gy.^2;
Axx=convTri(Gxx,rad); Axy=convTri(Gxy,rad); Ayy=convTri(Gyy,rad);

% Find determinant, trace, and eigenvalues of A'A
detA=Axx.*Ayy-Axy.^2; trA=Axx+Ayy;
V1=0.5*sqrt(trA.^2-4*detA);

% Compute inner product of gradient with time derivative
It=I2-I1; Ixt=-Gx.*It; Iyt=-Gy.*It;
ATbx=convTri(Ixt,rad); ATby=convTri(Iyt,rad);

% Compute components of velocity vectors
Vx=(1./(detA+eps)).*(Ayy.*ATbx-Axy.*ATby);
Vy=(1./(detA+eps)).*(-Axy.*ATbx+Axx.*ATby);

% Check for ill conditioned second moment matrices
reliab = 0.5*trA-V1;
reliab([1:rad end-rad+1:end],:)=0;
reliab(:,[1:rad end-rad+1:end])=0;
Vx(reliab<thr)=0; Vy(reliab<thr)=0;

% show quiver plot on top of reliab
if( show )
  figure(show); clf; im(I1); hold('on');
  quiver(Vx,Vy,0,'-b'); hold('off');
end

end
