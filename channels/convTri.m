function J = convTri( I, r, s, nomex )
% Extremely fast 2D image convolution with a triangle filter.
%
% Convolves an image by a 2D triangle filter (the 1D triangle filter f is
% [1:r r+1 r:-1:1]/(r+1)^2, the 2D version is simply conv2(f,f')). The
% convolution can be performed in constant time per-pixel, independent of
% the radius r. In fact the implementation is nearly optimal, with the
% convolution taking only slightly more time than creating a copy of the
% input array. Boundary effects are handled as if the image were padded
% symmetrically prior to performing the convolution. An optional integer
% downsampling parameter "s" can be specified, in which case the output is
% downsampled by s (the implementation is efficient with downsampling
% occurring simultaneously with smoothing, saving additional time).
%
% The output is exactly equivalent to the following Matlab operations:
%  f = [1:r r+1 r:-1:1]/(r+1)^2;
%  J = padarray(I,[r r],'symmetric','both');
%  J = convn(convn(J,f,'valid'),f','valid');
%  if(s>1), t=floor(s/2)+1; J=J(t:s:end-s+t,t:s:end-s+t,:); end
% The computation, however, is an order of magnitude faster than the above.
%
% When used as a smoothing filter, the standard deviation (sigma) of a tri
% filter with radius r can be computed using [sigma=sqrt(r*(r+2)/6)]. For
% the first few values of r this translates to: r=1: sigma=1/sqrt(2), r=2:
% sigma=sqrt(4/3), r=3: sqrt(5/2), r=4: sigma=2. Given sigma, the
% equivalent value of r can be computed via [r=sqrt(6*sigma*sigma+1)-1].
%
% For even finer grained control for very small amounts of smoothing, any
% value of r between 0 and 1 can be used (normally if r>=1 then r must be
% an integer). In this case a filter of the form fp=[1 p 1]/(2+p) is used,
% with p being determined automatically from r. The filter fp has a
% standard deviation of [sigma=sqrt(2/(p+2))]. Hence p can be determined
% from r by setting [sqrt(r*(r+2)/6)=sqrt(2/(p+2))], which gives
% [p=12/r/(r+2)-2]. Note that r=1 gives p=2, so fp=[1 2 1]/4 which is the
% same as the normal r=1 triangle filter. As r goes to 0, p goes to
% infinity, and fp becomes the delta function [0 1 0]. The computation for
% r<=1 is particularly fast.
%
% The related function convBox performs convolution with a box filter,
% which is slightly faster but has worse properties if used for smoothing.
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  J = convTri( I, r, [s], [nomex] )
%
% INPUTS
%  I      - [hxwxk] input k channel single image
%  r      - integer filter radius (or any value between 0 and 1)
%           filter standard deviation is: sigma=sqrt(r*(r+2)/6)
%  s      - [1] integer downsampling amount after convolving
%  nomex  - [0] if true perform computation in matlab (for testing/timing)
%
% OUTPUTS
%  J      - [hxwxk] smoothed image
%
% EXAMPLE - matlab versus mex
%  I = single(imResample(imread('cameraman.tif'),[480 640]))/255;
%  r = 5; s = 2; % set parameters as desired
%  tic, J1=convTri(I,r,s); toc % mex version (fast)
%  tic, J2=convTri(I,r,s,1); toc % matlab version (slow)
%  figure(1); im(J1); figure(2); im(abs(J2-J1));
%
% EXAMPLE - triangle versus gaussian smoothing
%  I = single(imResample(imread('cameraman.tif'),[480 640]))/255;
%  sigma = 4; rg = ceil(3*sigma); f = filterGauss(2*rg+1,[],sigma^2);
%  tic, J1=conv2(conv2(imPad(I,rg,'symmetric'),f,'valid'),f','valid'); toc
%  r=sqrt(6*sigma*sigma+1)-1; tic, J2=convTri(I,r); toc
%  figure(1); im(J1); figure(2); im(J2); figure(3); im(abs(J2-J1));
%
% See also conv2, convBox, gaussSmooth
%
% Piotr's Image&Video Toolbox      Version 3.02
% Copyright 2012 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 ), s=1; end
if( nargin<4 ), nomex=0; end
if( isempty(I) || (r==0 && s==1) ), J = I; return; end
m=min(size(I,1),size(I,2)); if( m<4 || 2*r+1>=m ), nomex=1; end

if( nomex==0 )
  if( r>0 && r<=1 && s<=2 )
    J = convConst('convTri1',I,12/r/(r+2)-2,s);
  else
    J = convConst('convTri',I,r,s);
  end
else
  if(r<=1), p=12/r/(r+2)-2; f=[1 p 1]/(2+p); r=1;
  else f=[1:r r+1 r:-1:1]/(r+1)^2; end
  J = padarray(I,[r r],'symmetric','both');
  J = convn(convn(J,f,'valid'),f','valid');
  if(s>1), t=floor(s/2)+1; J=J(t:s:end-s+t,t:s:end-s+t,:); end
end
