function [J,boundX,boundY] = textureMap( I, rsDst, csDst, bbox, fillVal )
% Maps texture in I according to rsDst and csDst.
%
% I has (nrows*ncols) coordinates.  Each coordinate has an associated
% intensity value.  A transformation on I can be defined by giving the
% destination (r',c') of the intensity associated with coordinate (r,c) in
% I -- ie I(r,c).  Applying the transformation, we ask what intensity is
% associated with a coordinate (r0',c0') by interpolating between the
% intensities at the closest coordinates (r',c').  In the function below
% specify the destination of (r,c) by (rsDst(r,c), csDst(r,c)).
%
% If the inverse mapping is also available -- ie, if we can go from the
% coordinates in the destination to the coordinates in the source, then a
% much more efficient procedure can be used to textureMap that involves
% interp2 instead of griddata. Use imtransform2 for this case.
%
% The bounding box of the image is set by the BBOX argument, a string that
% can be 'loose' (default) or 'crop'. When BBOX is 'loose', J includes the
% whole transformed image, which generally is larger than I. When BBOX is
% 'crop' J is cropped to include only the central portion of the
% transformed image and is the same size as I.
%
% USAGE
%  J = textureMap( I, rsDst, csDst, [bbox], [fillVal] )
%
% INPUTS
%  I           - 2D input image
%  rsDst       - rsDst(i,j) is row loc where I(i,j) gets mapped to
%  csDst       - csDst(i,j) is col loc where I(i,j) gets mapped to
%  bbox        - ['loose'] see above for meaning of bbox 'loose' or 'crop'
%  fillVal     - [0] Value of the empty warps
%
% OUTPUTS
%  J           - result of texture mapping
%  boundaryX   - returns the smallest/biggest x coordinate of the output
%  boundaryY   - returns the smallest/biggest y coordinate of the output
%
% EXAMPLE
%  load trees; I=X; angle=55; R=rotationMatrix(-angle/180*pi);
%  m=size(I,1); n=size(I,2); m2=(m+1)/2; n2=(n+1)/2;
%  [cs,rs]=meshgrid(1:n,1:m); vs=R*[cs(:)-n2 rs(:)-m2]';
%  tic; J1 = imrotate(I,angle,'bilinear','crop'); toc
%  tic, J2 = textureMap(I,vs(2,:)+m2,vs(1,:)+n2,'crop',nan); toc
%  figure(1); clf; subplot(2,2,1); im(I); subplot(2,2,2); im(J1-J2);
%  subplot(2,2,3); im(J1); subplot(2,2,4); im(J2);
%
% See also IMTRANSFORM2
%
% Piotr's Image&Video Toolbox      Version 2.61
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<4 || isempty(bbox)), bbox='loose'; end
if(nargin<5 || isempty(fillVal)), fillVal=0; end
if(isa(I,'uint8')), I=double(I); end; m=size(I,1); n=size(I,2);
rsDst=rsDst(:); assert(numel(rsDst)==m*n);
csDst=csDst(:); assert(numel(csDst)==m*n);

% find sampling points
if( strcmp('loose',bbox) )
  minr=floor(min(rsDst)); maxr=ceil(max(rsDst));
  minc=floor(min(csDst)); maxc=ceil(max(csDst));
  [cs,rs] = meshgrid( minc:maxc, minr:maxr );
  boundX=[minc maxc]; boundY=[minr maxr];
elseif( strcmp('crop',bbox) )
  [cs,rs]=meshgrid(1:n,1:m); boundX=[1 n]; boundY=[1 m];
else
  error('illegal value for bbox: %s',bbox);
end

% Get values at cs and rs
if(exist('TriScatteredInterp','file'))
  F=TriScatteredInterp(csDst,rsDst,I(:),'linear'); J=F(cs,rs); %#ok<REMFF1>
else
  J=griddata(csDst,rsDst,I(:),cs,rs);
end
if(~isnan(fillVal)), J(isnan(J))=fillVal; end

end
