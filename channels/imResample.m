function B = imResample( A, scale, method, norm )
% Fast bilinear image downsampling/upsampling.
%
% Gives similar results to imresize with the bilinear option and
% antialiasing turned off if scale is near 1, except sometimes the final
% dims are off by 1 pixel. For very small values of the scale imresize is
% faster but only looks at subset of values of original image.
%
% This code requires SSE2 to compile and run (most modern Intel and AMD
% processors support SSE2). Please see: http://en.wikipedia.org/wiki/SSE2.
%
% USAGE
%  B = imResample( A, scale, [method], [norm] )
%
% INPUT
%  A        - input image (2D or 3D single, double or uint8 array)
%  scale    - scalar resize factor [s] of target height and width [h w]
%  method   - ['bilinear'] either 'bilinear' or 'nearest'
%  norm     - [1] optionally multiply every output pixel by norm
%
% OUPUT
%   B       - resampled image
%
% EXAMPLE
%  I=single(imread('cameraman.tif')); n=100; s=1/2; method='bilinear';
%  tic, for i=1:n, I1=imresize(I,s,method,'Antialiasing',0); end; toc
%  tic, for i=1:n, I2=imResample(I,s,method); end; toc
%  figure(1); im(I1); figure(2); im(I2);
%
% See also imresize
%
% Piotr's Image&Video Toolbox      Version 3.24
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% figure out method and get target dimensions
if( nargin<3 || isempty(method) ), bilinear=1; else
  if(~all(ischar(method))), error('method must be a string'); end
  bilinear = ~strcmpi(method,'nearest');
end
if( nargin<4 || isempty(norm) ), norm=1; end
[m,n,~]=size(A); k=numel(scale);
same = (k==1 && scale==1) | (k==2 && m==scale(1) && n==scale(2));
if( same && norm==1 ); B=A; return; end

if( bilinear )
  % use bilinear interpolation
  if(k==1), m1=round(scale*m); n1=round(scale*n);
  else m1=scale(1); n1=scale(2); end
  B=imResampleMex(A,m1,n1,norm);
else
  % use nearest neighbor interpolation
  if(k==1), sy=scale; sx=sy; m1=ceil(m*sy); n1=ceil(n*sx);
  else m1=scale(1); n1=scale(2); sy=m1/m; sx=n1/n; end
  y=(1:m1)'; y=floor(y/sy-.5/sy+1); y=min(max(1,y),m);
  x=(1:n1)'; x=floor(x/sx-.5/sx+1); x=min(max(1,x),n);
  nd=ndims(A); if(nd==2), B=A(y,x); elseif(nd==3), B=A(y,x,:);
  else ids={y,x}; ids(3:nd)={':'}; B=A(ids{:}); end
  if(norm~=1), B=B*norm; end
end
