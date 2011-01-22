function B = imResample( A, varargin )
% Fast bilinear image downsampling/upsampling.
%
% Gives similar results to imresize with the bilinear option and
% antialiasing turned off if scale is near 1, except sometimes the final
% dims are off by 1 pixel. Inspired by fast downsapmling routine resize.cpp
% by Deva Ramanan. Particularly efficient if downsampling by exact integer
% value. For very small values of the scale imresize is faster but only
% looks at subset of values of original image.
%
% USAGE
%  B = imResample( A, scale, [method] )
%  B = imResample( A, h, w, [method] )
%
% INPUT [1]
%  A        - input image (2D or 3D double or uint8 array)
%  scale    - size(B)=size(A)*scale
%  method   - ['bilinear'] either 'bilinear' or 'nearest'
%
% INPUT [2]
%  A        - input image (2D or 3D double or uint8 array)
%  h        - height(B)=h
%  w        - width(B)=w
%  method   - ['bilinear'] either 'bilinear' or 'nearest'
%
% OUPUT
%   B       - resampled image
%
% EXAMPLE
%  I=double(imread('cameraman.tif')); n=100; s=1/2; method='bilinear';
%  tic, for i=1:n, I1=imresize(I,s,method,'Antialiasing',0); end; toc
%  tic, for i=1:n, I2=imResample(I,s,method); end; toc
%  figure(1); im(I1); figure(2); im(I2); figure(3); im(abs(I1-I2));
%
% See also IMRESIZE
%
% Piotr's Image&Video Toolbox      Version 2.60
% Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% figure out method
if(isnumeric(varargin{end})), bilinear=1; else
  bilinear=~strcmpi(varargin{end},'nearest');
  varargin=varargin(1:end-1);
end

% use bilinear interpolation
if(bilinear), B=imResample1(A,varargin{:}); return; end

% use nearest neighbor interpolation
m=size(A,1); n=size(A,2); nd=ndims(A);
if(nargin<=3), sy=varargin{1}; sx=sy; m1=ceil(m*sy); n1=ceil(n*sx);
else m1=varargin{1}; n1=varargin{2}; sy=m1/m; sx=n1/n; end
y=(1:m1)'; y=floor(y/sy-.5/sy+1); y=min(max(1,y),m);
x=(1:n1)'; x=floor(x/sx-.5/sx+1); x=min(max(1,x),n);
if(nd==2), B=A(y,x); elseif(nd==3), B=A(y,x,:); else
  ids={y,x}; ids(3:nd)={':'}; B=A(ids{:}); end
