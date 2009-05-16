% Fast bilinear image downsampling/upsampling.
%
% Gives similar results to imresize with the bilinear option and
% antialiasing turned off, except sometimes the final dims are off by 1
% pixel. Inspired by fast downsapmling routine resize.cpp by Deva Ramanan.
%
% USAGE
%  B = imResample( A, scale )
%  B = imResample( A, h, w )
%
% INPUT [1]
%  A        - input image (2D or 3D double array)
%  scale    - size(B)=size(A)*scale
%
% INPUT [2]
%  A        - input image (2D or 3D double array)
%  h        - height(B)=h
%  w        - width(B)=w
%
% OUPUT
%   B       - resampled image
%
% EXAMPLE
%  I=double(imread('cameraman.tif')); n=100; s=.5;
%  tic, for i=1:n, I1=imresize(I,s,'bilinear','Antialiasing',0); end; toc
%  tic, for i=1:n, I2=imResample(I,s); end; toc
%  figure(1); im(I1); figure(2); im(I2); figure(3); im(abs(I1-I2));
%
% See also IMRESIZE
%
% Piotr's Image&Video Toolbox      Version 2.30
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]
