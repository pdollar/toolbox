function [M,O] = gradientMag( I, channel, normRad, normConst )
% Compute gradient magnitude and orientation at each image location.
%
% If input image has k>1 channels and channel=0, keeps gradient with
% maximum magnitude (over all channels) at each location. Otherwise if
% channel is between 1 and k computes gradient for the given channel.
% Orientation is given modulo PI degrees. Highly optimized using mex.
%
% If normRad>0, normalization is performed by first computing S, a smoothed
% version of the gradient magnitude, then setting: M = M./(S + normConst).
% S is computed by S = convTri( M, normRad ).
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  [M,O] = gradientMag( I, [channel], [normRad], [normConst] )
%
% INPUTS
%  I          - [hxwxk] input k channel single image
%  channel    - [0] if>0 color channel to use for gradient computation
%  normRad    - [0] normalization radius (no normalization if 0)
%  normConst  - [.005] normalization constant
%
% OUTPUTS
%  M          - [hxw] gradient magnitude at each location
%  O          - [hxw] approximate gradient orientation modulo PI
%
% EXAMPLE
%  I=rgb2gray(single(imread('peppers.png'))/255);
%  tic, [M1,O1]=gradientMag(I); toc
%  tic, [Gx,Gy]=gradient2(I); M2=sqrt(Gx.^2+Gy.^2);
%  O2=mod(atan2(Gy,Gx),pi); toc, mean2(abs(M1-M2))
%  d=abs(O1-O2); d(d>pi/2)=pi-d(d>pi/2); mean2(d)
%
% See also gradient, gradient2, gradientHist, convTri
%
% Piotr's Image&Video Toolbox      Version 3.00
% Copyright 2012 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<2 || isempty(channel)), channel=0; end
if(nargin<3 || isempty(normRad)), normRad=0; end
if(nargin<4 || isempty(normConst)), normConst=.005; end

if(nargout<=1), M=gradientMex('gradientMag',I,channel);
else [M,O]=gradientMex('gradientMag',I,channel); end

if( normRad==0 ), return; end; S = convTri( M, normRad );
gradientMex('gradientMagNorm',M,S,normConst); % operates on M
