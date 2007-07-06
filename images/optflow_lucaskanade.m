% Calculate optical flow using Lucas & Kanade.  Fast, parallel code.
%
% Note that the window of integration can either be a hard square window of
% radius winN or it can be a soft 'gaussian' window with sigma winSig.
% In general the soft window should be more accurate.
%
% USAGE
%  [Vx,Vy,reliab]=optflow_lucaskanade( I1, I2, winN, ...
%                                [winSig], [sigma], [thr], [show] )
%
% INPUTS
%  I1, I2  - input images to calculate flow between
%  winN    - window radius for hard window (=[] if winSig provided)
%  winSig  - [] sigma for soft 'gauss' window (=[] if winN provided)
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
%  optflow_lucaskanade( A, B, [], 2, 2, 3e-6, 1 );
%  optflow_lucaskanade( A, C, [], 2, 2, 3e-6, 4 );
%  % compare on stored real images (of mice)
%  load optflow_data;
%  [Vx,Vy,reliab] = optflow_lucaskanade( I5A, I5B, [], 4, 1.2, 3e-6, 1 );
%  [Vx,Vy,reliab] = optflow_corr( I5A, I5B, 3, 5, 1.2, .01, 2 );
%  [Vx,Vy] = optflow_horn( I5A, I5B, 2, 3 );
%
% See also OPTFLOW_HORN, OPTFLOW_CORR

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [Vx,Vy,reliab]=optflow_lucaskanade( I1, I2, winN, ...
                                            winSig, sigma, thr, show )

if( nargin<4 || isempty(winSig));  winSig=[]; end
if( nargin<5 || isempty(sigma)); sigma=1; end
if( nargin<6 || isempty(thr)); thr=3e-6; end
if( nargin<7 || isempty(show)); show=0; end

% error check inputs
if( ~isempty(winN) && ~isempty(winSig))
  error('Either winN or winSig should be empty!'); end
if( isempty(winN) && isempty(winSig))
  error('Either winN or winSig must be non-empty!'); end
if( ndims(I1)~=2 || ndims(I2)~=2 )
  error('Only works for 2d input images.');
end
if( any(size(I1)~=size(I2)) );
  error('Input images must have same dimensions.');
end

% convert to double in range [0,1]
if( isa(I1,'uint8') )
  I1=double(I1)/255; I2=double(I2)/255;
else
  if( ~isa(I1,'double'))
    I1=double(I1); I2=double(I2);
  end;
  if( abs(max([I1(:); I2(:)]))>1 )
    minval = min([I1(:); I2(:)]);  I1=I1-minval;  I2=I2-minval;
    maxval = max([I1(:); I2(:)]);  I1=I1/maxval;  I2=I2/maxval;
  end;
end;

% smooth images (using the 'smooth' flag causes this to be slow)
I1 = gauss_smooth(I1,sigma,'same');
I2 = gauss_smooth(I2,sigma,'same');

% Compute components of outer product of gradient of frame 1
[Gx,Gy]=gradient(I1);
Gxx=Gx.^2;  Gxy=Gx.*Gy;   Gyy=Gy.^2;
if( isempty(winSig) )
  win_mask = ones(2*winN+1);
  win_mask = win_mask / sum(win_mask(:));
  Axx=conv2(Gxx,win_mask,'same');
  Axy=conv2(Gxy,win_mask,'same');
  Ayy=conv2(Gyy,win_mask,'same');
else
  winN = ceil(winSig);
  Axx=gauss_smooth(Gxx,winSig,'same',2);
  Axy=gauss_smooth(Gxy,winSig,'same',2);
  Ayy=gauss_smooth(Gyy,winSig,'same',2);
end;

% Find determinant, trace, and eigenvalues of A'A
detA=Axx.*Ayy-Axy.^2;
trA=Axx+Ayy;
V1=0.5*sqrt(trA.^2-4*detA);

% Compute inner product of gradient with time derivative
It=I2-I1;    IxIt=-Gx.*It;   IyIt=-Gy.*It;
if( isempty(winSig) )
  ATbx=conv2(IxIt,win_mask,'same');
  ATby=conv2(IyIt,win_mask,'same');
else
  ATbx=gauss_smooth(IxIt,winSig,'same',2);
  ATby=gauss_smooth(IyIt,winSig,'same',2);
end;

% Compute components of velocity vectors
Vx=(1./(detA+eps)).*(Ayy.*ATbx-Axy.*ATby);
Vy=(1./(detA+eps)).*(-Axy.*ATbx+Axx.*ATby);

% Check for ill conditioned second moment matrices
reliab = 0.5*trA-V1;
reliab([1:winN end-winN+1:end],:)=0;
reliab(:,[1:winN end-winN+1:end])=0;
Vx(reliab<thr) = 0;   Vy(reliab<thr) = 0;

% show quiver plot on top of reliab
if( show )
  figure(show); clf; im( I1 );
  hold('on'); quiver( Vx, Vy, 0,'-b' ); hold('off');
end
