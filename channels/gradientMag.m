function [M,O] = gradientMag( I, channel, normRad, normConst, full )
% Compute gradient magnitude and orientation at each image location.
%
% If input image has k>1 channels and channel=0, keeps gradient with
% maximum magnitude (over all channels) at each location. Otherwise if
% channel is between 1 and k computes gradient for the given channel.
% If full==1 orientation is computed in [0,2*pi) else it is in [0,pi).
%
% If normRad>0, normalization is performed by first computing S, a smoothed
% version of the gradient magnitude, then setting: M = M./(S + normConst).
% S is computed by S = convTri( M, normRad ).
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  [M,O] = gradientMag( I, [channel], [normRad], [normConst], [full] )
%
% INPUTS
%  I          - [hxwxk] input k channel single image
%  channel    - [0] if>0 color channel to use for gradient computation
%  normRad    - [0] normalization radius (no normalization if 0)
%  normConst  - [.005] normalization constant
%  full       - [0] if true compute angles in [0,2*pi) else in [0,pi)
%
% OUTPUTS
%  M          - [hxw] gradient magnitude at each location
%  O          - [hxw] approximate gradient orientation modulo PI
%
% EXAMPLE
%  I=rgbConvert(imread('peppers.png'),'gray');
%  [Gx,Gy]=gradient2(I); M=sqrt(Gx.^2+Gy.^2); O=atan2(Gy,Gx);
%  full=0; [M1,O1]=gradientMag(I,0,0,0,full);
%  D=abs(M-M1); mean2(D), if(full), o=pi*2; else o=pi; end
%  D=abs(O-O1); D(~M)=0; D(D>o*.99)=o-D(D>o*.99); mean2(abs(D))
%
% See also gradient, gradient2, gradientHist, convTri
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<1 || isempty(I)), M=single([]); O=M; return; end
if(nargin<2 || isempty(channel)), channel=0; end
if(nargin<3 || isempty(normRad)), normRad=0; end
if(nargin<4 || isempty(normConst)), normConst=.005; end
if(nargin<5 || isempty(full)), full=0; end

if(nargout<=1), M=gradientMex('gradientMag',I,channel,full);
else [M,O]=gradientMex('gradientMag',I,channel,full); end

if( normRad==0 ), return; end; S = convTri( M, normRad );
gradientMex('gradientMagNorm',M,S,normConst); % operates on M
