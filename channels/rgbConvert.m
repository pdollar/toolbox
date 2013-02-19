function J = rgbConvert( I, colorSpace, useSingle )
% Convert RGB image to other color spaces (highly optimized).
%
% If colorSpace=='gray' transforms I to grayscale. The output is within
% numerical error of Matlab's rgb2gray, except ~10x faster. The output in
% this case is hxwx1, and while the input must be hxwx3 for all other
% cases, the input for this case can also be hxwx1 (normalization only).
%
% If colorSpace=='hsv' transforms I to the HSV color space. The output is
% within numerical error of Matlab's rgb2hsv, except ~15x faster.
%
% If colorSpace=='rgb' or colorSpace='orig' only normalizes I to be in the
% range [0,1]. In this case both the input and output may have an arbitrary
% number of channels (that is I may be [hxwxd] for any d).
%
% If colorSpace=='luv' transforms I to the LUV color space. The LUV color
% space is "perceptually uniform" (meaning that two colors equally distant
% in the color space according to the Euclidean metric are equally distant
% perceptually). The L,u,v channels correspond roughly to luminance,
% green-red, blue-yellow. For more information see:
%   http://en.wikipedia.org/wiki/CIELUV - using this color spaces
%   http://en.wikipedia.org/wiki/CIELAB - more info about color spaces
% The LUV channels are normalized to fall in ~[0,1]. Without normalization
% the ranges are L~[0,100], u~[-88,182], and v~[-134,105] (and typically
% u,v~[-100,100]). The applied transformation is L=L/270, u=(u+88)/270, and
% v=(v+134)/270. This results in ranges L~[0,.37], u~[0,1], and v~[0,.89].
% Perceptual uniformity is maintained since divisor is constant
% (normalizing each color channel independently would break uniformity).
% To undo the normalization on an LUV image J use:
%   J=J*270; J(:,:,2)=J(:,:,2)-88; J(:,:,3)=J(:,:,3)-134;
% To test the range of the colorSpace use:
%   R=100; I=zeros(R^3,1,3); k=1; R=linspace(0,1,R);
%   for r=R, for g=R, for b=R, I(k,1,:)=[r g b]; k=k+1; end; end; end
%   J=rgbConvert(I,'luv'); [min(J), max(J)]
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  J = rgbConvert( I, colorSpace, [useSingle] );
%
% INPUTS
%  I          - [hxwx3] input rgb image (uint8 or single/double in [0,1])
%  colorSpace - ['luv'] other choices include: 'gray', 'hsv', 'rgb', 'orig'
%  useSingle  - [true] determines output type (faster if useSingle)
%
% OUTPUTS
%  J          - [hxwx3] single or double output image (normalized to [0,1])
%
% EXAMPLE - luv
%  I = imread('peppers.png');
%  tic, J = rgbConvert( I, 'luv' ); toc
%  figure(1); montage2( J );
%
% EXAMPLE - hsv
%  I=imread('peppers.png');
%  tic, J1=rgb2hsv( I ); toc
%  tic, J2=rgbConvert( I, 'hsv' ); toc
%  mean2(abs(J1-J2))
%
% EXAMPLE - gray
%  I=imread('peppers.png');
%  tic, J1=rgb2gray( I ); toc
%  tic, J2=rgbConvert( I, 'gray' ); toc
%  J1=single(J1)/255; mean2(abs(J1-J2))
%
% See also rgb2hsv, rgb2gray
%
% Piotr's Image&Video Toolbox      Version 3.02
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<3 || isempty(useSingle)), useSingle=true; end
flag = find(strcmpi(colorSpace,{'gray','rgb','luv','hsv','orig'}))-1;
if(isempty(flag)), error('unknown colorSpace: %s',colorSpace); end
if(useSingle), outClass='single'; else outClass='double'; end
if(isempty(I) && flag>0 && flag~=4), I=I(:,:,[1 1 1]); end
d=size(I,3); if(flag==4), flag=1; end; norm=(d==1 && flag==0) || flag==1;
if( norm && isa(I,outClass) ), J=I; return; end
J=rgbConvertMex(I,flag,useSingle);
