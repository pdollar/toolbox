function I = convOnes( I, rads, shape )
% Fast routine for box filtering with a ones filter.
%
% Same effect as calling 'C=convn( I, ones(2*rads+1), shape)', except more
% efficient. A faster special case of localSum.
%
% USAGE
%  I = convOnes( I, rads, [shape] )
%
% INPUTS
%  I       - 2D or 3D matrix to compute sum over
%  rads    - size of volume to compute sum over, can be scalar
%  shape   - ['full'] 'valid', 'full', or 'same'
%
% OUTPUTS
%  C       - matrix of sums
%
% EXAMPLE
%  A=rand(500,500,10); ry=25; rx=25; rz=0; shape='same'; r=10;
%  tic, for i=1:r, B = localSum(A,[ry rx rz]*2+1,shape); end; toc
%  tic, for i=1:r, C = convOnes(A,[ry rx rz],shape); end; toc
%  diff=B-C; sum(abs(diff(:)))
% 
% See also LOCALSUM, IMSHRINK
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if(length(rads)==1), rads=[rads rads 0]; end
if(length(rads)==2), rads=[rads(:)' 0]; end
siz=size(I); if(length(siz)==2), siz=[siz(:)' 1]; end
assert(ndims(I)==2 || ndims(I)==3); assert(length(rads)==3);
assert(any(strcmp(shape,{'same','valid','full'})));

% pad I to 'full' dimensions
if(strcmp(shape,'valid') && any((2*rads+1)>siz)); I=[]; return; end
if(strcmp(shape,'full')), s=1+rads; e=siz+rads;
  Z=zeros(siz+2*rads); Z(s(1):e(1),s(2):e(2),s(3):e(3))=I; I=Z; end

% compute convolution
I = convOnes1(I,rads(1),rads(2),rads(3));

% crop to appropriate size if 'valid'
if(strcmp(shape,'valid')), s=1+rads; e=siz-rads;
  I=I(s(1):e(1),s(2):e(2),s(3):e(3)); end

end
