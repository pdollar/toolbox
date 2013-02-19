function J = convBox( I, r, s, nomex )
% Extremely fast 2D image convolution with a box filter.
%
% Convolves an image by a F=ones(2*r+1,2*r+1)/(2*r+1)^2 filter. The
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
%  f = ones(1,2*r+1); f=f/sum(f);
%  J = padarray(I,[r r],'symmetric','both');
%  J = convn(convn(J,f,'valid'),f','valid');
%  if(s>1), t=floor(s/2)+1; J=J(t:s:end-s+t,t:s:end-s+t,:); end
% The computation, however, is an order of magnitude faster than the above.
%
% When used as a smoothing filter, the standard deviation (sigma) of a box
% filter with radius r can be computed using [sigma=sqrt(r*(r+1)/3)]. For
% the first few values of r this translates to: r=1: sigma=sqrt(2/3), r=2:
% sigma=sqrt(2), r=3: sigma=2. Given sigma, the equivalent value of r can
% be computed via [r=sqrt(12*sigma*sigma+1)/2-.5].
%
% The related function convTri performs convolution with a triangle filter,
% which has nicer properties if used for smoothing, but is slightly slower.
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  J = convBox( I, r, [s], [nomex] )
%
% INPUTS
%  I      - [hxwxk] input k channel single image
%  r      - integer filter radius
%  s      - [1] integer downsampling amount after convolving
%  nomex  - [0] if true perform computation in matlab (for testing/timing)
%
% OUTPUTS
%  J      - [hxwxk] smoothed image
%
% EXAMPLE
%  I = single(imResample(imread('cameraman.tif'),[480 640]))/255;
%  r = 5; s = 2; % set parameters as desired
%  tic, J1=convBox(I,r,s); toc % mex version (fast)
%  tic, J2=convBox(I,r,s,1); toc % matlab version (slow)
%  figure(1); im(J1); figure(2); im(abs(J2-J1));
%
% See also conv2, convTri
%
% Piotr's Image&Video Toolbox      Version 3.02
% Copyright 2012 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

assert( r>=0 );
if( nargin<3 ), s=1; end
if( nargin<4 ), nomex=0; end
if( isempty(I) || (r==0 && s==1) ), J = I; return; end
m=min(size(I,1),size(I,2)); if( m<4 || 2*r+1>=m ), nomex=1; end

if( nomex==0 )
  if( r==1 && s<=2 )
    J = convConst('convTri1',I,1,s);
  else
    J = convConst('convBox',I,r,s);
  end
else
  f = ones(1,2*r+1); f=f/sum(f);
  J = padarray(I,[r r],'symmetric','both');
  J = convn(convn(J,f,'valid'),f','valid');
  if(s>1), t=floor(s/2)+1; J=J(t:s:end-s+t,t:s:end-s+t,:); end
end
