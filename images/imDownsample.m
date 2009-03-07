% Fast bilinear image downsampling.
%
% Does not give identical results to imresize with the bilinear option
% (results are a bit sharper). Inspired by resize.cpp from Deva Ramanan.
%
% USAGE
%  B = imDownsample( A, scaleHt, [scaleWd] )
%
% INPUT
%  A        - input image, 2D or 3D, must have type double
%  scaleHt  - resize ratio 0<scaleHt<=1
%  scaleWd  - [] resize ratio 0<scaleWd<=1, defaults to scaleHt
%
% OUPUT
%   B       - downsampled image
%
% EXAMPLE
%  I=double(imread('cameraman.tif'));
%  tic, for i=1:10, I1=imresize(I,.5,'bilinear'); end; toc
%  tic, for i=1:10, I2=imDownsample(I,.5); end; toc
%  figure(1); im(I1); figure(2); im(I2);
%
% See also IMRESIZE
%
% Piotr's Image&Video Toolbox      Version 2.20
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]
