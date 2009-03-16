% Fast bilinear image downsampling.
%
% Does not give identical results to imresize with the bilinear option
% (results are a bit sharper). Inspired by resize.cpp from Deva Ramanan.
%
% USAGE
%  B = imDownsample( A, h, [w] )
%
% INPUT
%  A        - input image, 2D or 3D, must have type double
%  h        - if 0<h<=1, height(B)=height(A)*h, else height(B)=h
%  w        - [h] if 0<w<=1, width(B)=width(A)*w, else width(B)=w
%
% OUPUT
%   B       - downsampled image
%
% EXAMPLE
%  I=double(imread('cameraman.tif'));
%  tic, for i=1:100, I1=imresize(I,.5,'bilinear'); end; toc
%  tic, for i=1:100, I2=imDownsample(I,.5); end; toc
%  tic, for i=1:100, I3=imDownsample(I,128,128); end; toc
%  figure(1); im(I1); figure(2); im(I2);
%
% See also IMRESIZE
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]
