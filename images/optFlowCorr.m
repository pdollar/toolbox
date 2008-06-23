function [Vx,Vy,reliab] = optFlowCorr( I1, I2, patchR, searchR, ...
  sigma, thr, show )
% Calculate optical flow using cross-correlation.
%
% Calculate optical flow using correlation, followed by lucas & kanade on
% aligned squares for subpixel accuracy.  Locally, the closest patch within
% some search radius is found.  The distance measure used is the euclidean
% distance between patches -- NOT normalized correlation since we assume
% pixel brightness constancy.  Once the closest matching patch is found,
% the alignment between the two patches is further refined using lucas &
% kanade to find the subpixel translation vector relating the two patches.
%
% This code has been refined for speed, but since it is nonvectorized code
% it can be fairly slow.  Running time is linear in the number of pixels
% but the constant is fairly large.  Test on small image (150x150) before
% running on anything bigger.
%
% USAGE
%  [Vx,Vy,reliab] = optFlowCorr( I1, I2, patchR, searchR,
%                                 [sigma], [thr], [show] )
%
% INPUTS
%  I1, I2      - input images to calculate flow between
%  patchR      - determines correlation patch size around each pixel
%  searchR     - search radius for corresponding patch
%  sigma       - [1] amount to smooth by (may be 0)
%  thr         - [.001] RELATIVE reliability threshold
%  show        - [0] figure to use for display (no display if == 0)
%
% OUTPUTS
%  Vx, Vy      - x,y components of flow  [Vx>0->right, Vy>0->down]
%  reliab  - reliability of optical flow in given window (cornerness of
%            window)
%
% EXAMPLE
%
% See also OPTFLOWHORN, OPTFLOWLK
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<5 || isempty(sigma)); sigma=1; end;
if( nargin<6 || isempty(thr)); thr=0.001; end;
if( nargin<7 || isempty(show)); show=0; end;

% error check inputs
if( ndims(I1)~=2 || ndims(I2)~=2 )
  error('Only works for 2d input images.');
end
if( any(size(I1)~=size(I2)) )
  error('Input images must have same dimensions.');
end
if( isa(I1,'uint8')); I1 = double(I1); I2 = double(I2); end;

% smooth images (using the 'smooth' flag causes this to be slow)
I1b = gaussSmooth( I1, [sigma sigma], 'smooth' );
I2b = gaussSmooth( I2, [sigma sigma], 'smooth' );

% precomputed constants
subpixelaccuracy = 1;
siz = size(I1);
bigR = searchR + patchR;
n = (2*patchR+1)^2;
widthD = 2*searchR+1;
[ndxs,ndys] = meshgrid( 1:widthD, 1:widthD );

% hack to penalize more distant translations (closest are best?)
[xs,ys] = meshgrid(-searchR:searchR,-searchR:searchR);
Dpenalty = ((xs.^2 + ys.^2)/searchR^2 + 1) .^(1/20);

% pad I1 and I2 by searchR in each direction
I1b = padarray(I1b,[searchR searchR],0,'both');
I2b = padarray(I2b,[searchR searchR],0,'both');
sizB = size(I1b);

% precompute gradient for subpixel accuracy
[gEy,gEx] = gradient( I1b );

% loop over each window
Vx = zeros( sizB-2*bigR ); Vy = Vx;  reliab = Vx;
for r = bigR+1:sizB(1)-bigR
  for c = bigR+1:sizB(2)-bigR
    T = I1b( r-patchR:r+patchR, c-patchR:c+patchR );
    IC = I2b( r-bigR:r+bigR, c-bigR:c+bigR );

    % get smallest distance
    D = xeuc2Sm( T, IC, 'valid' );
    D = (D+eps) .* Dpenalty;
    [disc, ind] = min(D(:));

    % get offset to smallest distance
    ndx = [ndys(ind(1)) ndxs(ind(1))];
    v = ndx - (widthD + 1)/2;

    % get subpixel movement using lucas kanade on rectified windows
    if( subpixelaccuracy )
      T2 = I2b( r+v(1)-patchR:r+v(1)+patchR, c+v(2)-patchR:c+v(2)+ ...
        patchR );
      gExRc = gEx(r-patchR:r+patchR, c-patchR:c+patchR );
      gEyRc = gEy(r-patchR:r+patchR, c-patchR:c+patchR );
      EtRc = T2-T;
      A = [ gExRc(:), gEyRc(:) ];  b = -EtRc(:);
      AtA = A'*A;  detAtA = AtA(1)*AtA(4)-AtA(2)*AtA(3);
      if( abs(detAtA) > eps )
        invA = ([AtA(4) -AtA(2); -AtA(3) AtA(1)] / detAtA) * A'; veps = ...
          (invA * b)';
        lambdas = eig(A'*A); subrel = abs(min(lambdas)/max(lambdas));
        if( subrel > .0001 ); v = v + veps; end
      end
    end

    % get reliability
    %Dsort = sort(D(:)); rel = 1 - Dsort(1)/Dsort(2);
    x=T(:); rel = sum(x.*x)/n - (sum(x)/n)^2; % variance

    % record reliability and velocity
    reliab(r-bigR,c-bigR) = rel;
    Vx(r-bigR,c-bigR) = v(2);
    Vy(r-bigR,c-bigR) = v(1);
  end;
end;


% resize all to get rid of padding
Vx = arrayToDims( Vx, siz );
Vy = arrayToDims( Vy, siz );
reliab = arrayToDims( reliab, siz );

% scale reliab to be between [0,1]
reliab = reliab / max([reliab(:); eps]);
Vx(reliab<thr) = 0;  Vy(reliab<thr) = 0;

% show quiver plot on top of reliab
if( show )
  reliab( reliab>1 ) = 1;
  figure(show); clf; im( I1 );
  hold('on'); quiver( Vx, Vy, 0,'-b' ); hold('off');
end

function C = xeuc2Sm( B, I, shape )
% since the convolutions are so small just call conv2 everywhere
% see xeucn.m for more general version
sizB = size(B);
B = rot90( B,2 );
Imag = localSum( I.*I, sizB, shape );
Bmag = B.^2;  Bmag = sum( Bmag(:) );
C = Imag + Bmag - 2 * conv2(I,B,shape);
