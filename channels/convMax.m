function J = convMax( I, r, nomex )
% Extremely fast 2D image convolution with a max filter.
%
% For each location computes J(y,x) = max(max(I(y-r:y+r,x-r:x+r))). The
% filtering is constant time per-window, independent of r. First, the
% filtering is separable, which brings the complexity down to O(r) per
% window from O(r*r). To bring the implemention down to constant time
% (independent of r) we use the van Herk/Gil-Werman algorithm. Ignoring
% boundaries, just 3 max operations are need per-window regardless of r.
%  http://www.leptonica.com/grayscale-morphology.html#FAST-IMPLEMENTATION
%
% The output is exactly equivalent to the following Matlab operations:
%  I=padarray(I,[r r],'replicate','both'); [h,w,d]=size(I); J=I;
%  for z=1:d, for x=r+1:w-r, for y=r+1:h-r
%        J(y,x,z) = max(max(I(y-r:y+r,x-r:x+r,z))); end; end; end
%  J=J(r+1:h-r,r+1:w-r,:);
% The computation, however, is an order of magnitude faster than the above.
%
% USAGE
%  J = convMax( I, r, [nomex] )
%
% INPUTS
%  I      - [hxwxk] input k channel single image
%  r      - integer filter radius or radii along y and x
%  nomex  - [0] if true perform computation in matlab (for testing/timing)
%
% OUTPUTS
%  J      - [hxwxk] max image
%
% EXAMPLE
%  I = single(imResample(imread('cameraman.tif'),[480 640]))/255;
%  r = 5; % set parameter as desired
%  tic, J1=convMax(I,r); toc % mex version (fast)
%  tic, J2=convMax(I,r,1); toc % matlab version (slow)
%  figure(1); im(J1); figure(2); im(abs(J2-J1));
%
% See also conv2, convTri, convBox
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.00
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

assert( all(r>=0) );
if( nargin<3 ), nomex=0; end
if( all(r==0) ), J = I; return; end
if( numel(r)==1 ), ry=r; rx=r; else ry=r(1); rx=r(2); end

if( nomex==0 )
  d=size(I,3);
  if(d==1), J=convConst('convMax',convConst('convMax',I,ry,1)',rx,1)'; else
    J=I; for z=1:d, J(:,:,z) = ...
        convConst('convMax',convConst('convMax',J(:,:,z),ry,1)',rx,1)'; end
  end
else
  I=padarray(I,[ry rx],'replicate','both'); [h,w,d]=size(I); J=I;
  for z=1:d, for x=rx+1:w-rx, for y=ry+1:h-ry
        J(y,x,z) = max(max(I(y-ry:y+ry,x-rx:x+rx,z))); end; end; end
  J=J(ry+1:h-ry,rx+1:w-rx,:);
end

end
