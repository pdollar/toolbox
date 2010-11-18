function J = imtransform2( I, varargin )
% Applies a general/special homography on an image I
%
% Takes the center of the image as the origin, not the top left corner.
% Also, the coordinate system is row/column format, so H must be also.
%
% The bounding box of the image is set by the BBOX argument, a string that
% can be 'loose' (default) or 'crop'. When BBOX is 'loose', J includes the
% whole transformed image, which generally is larger than I. When BBOX is
% 'crop' J is cropped to include only the central portion of the
% transformed image and is the same size as I. The 'loose' flag is
% currently inexact (because of some padding/cropping). Preserves I's type.
%
% USAGE
%  J=imtransform2(I,H,[method],[bbox],[show],[pad])     % general hom
%  J=imtransform2(I,angle,[method],[bbox],[show],[pad]) % rotation
%  J=imtransform2(I,dx,dy,[method],[bbox],[show],[pad]) % translation
%
% INPUTS - common
%  I       - 2D image [converted to double]
%  method  - ['linear'] 'nearest', 'spline', 'cubic' (for interp2)
%  bbox    - ['loose'] or 'crop'
%  show    - [0] figure to use for optional display
%  pad     - [0] padding value (scalar or 'replicate')
%
% INPUTS - specific to general homography
%  H       - 3x3 nonsingular homography matrix
%
% INPUTS - specific to rotation
%  angle   - angle to rotate in degrees
%
% INPUTS - specific to translation
%  dx      - x translation (right)
%  dy      - y translation (up)
%
% OUTPUTS
%  J       - transformed image
%
% EXAMPLE - general homography (rotation + translation)
%  load trees; I=X; method='linear';
%  R = rotationMatrix(pi/4); T=[1; 3]; H=[R T; 0 0 1];
%  J = imtransform2(I,H,method,'crop',1,'replicate');
%
% EXAMPLE - general homography (out of plane rotation)
%  load trees; I=X; method='nearest';
%  R = rotationMatrix([0 1 0],pi/4); z=500;
%  H = R; H(1:2,:)=H(1:2,:)*z; H(:,3)=H(:,3)*z;
%  J = imtransform2(I,H,method,'loose',1);
%
% EXAMPLE - rotation
%  load trees; I=X; method='bicubic';
%  tic; J1 = imrotate(I,55,method,'crop'); toc
%  tic; J2 = imtransform2(I,55,method,'crop'); toc
%  clf; subplot(2,2,1); im(I); subplot(2,2,2); im(J1-J2);
%  subplot(2,2,3); im(J1); subplot(2,2,4); im(J2);
%
% EXAMPLE - translation
%  load trees; I=X; method='bicubic';
%  J = imtransform2(X,0,1.5,method,'crop');
%  figure(1); clf; im(I,[0 128]); figure(2); clf; im(J,[0 128]);
%
% See also TEXTUREMAP, INTERP2
%
% Piotr's Image&Video Toolbox      Version 2.53
% Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

% parse inputs and switch between cases
if( nargin>1 && isscalar(varargin{1}) && ...
    (nargin==2 || ischar(varargin{2})) ) % rotation
  angle = varargin{1};  angle = angle /180 * pi;
  H = [rotationMatrix(angle) [0;0]; 0 0 1];
  J = imtransform2main( I, H, varargin{2:end} );
  
elseif( nargin>2 && isscalar(varargin{1}) ...
    && isscalar(varargin{2}) ) % translation
  dx=varargin{1}; dy=varargin{2};
  H = [eye(2) [dy; dx]; 0 0 1];
  J = imtransform2main( I, H, varargin{3:end} );
  
else % presumably a general homography
  J = imtransform2main( I, varargin{:} );
end

function J = imtransform2main( I, H, method, bbox, show, pad )

% check inputs
if( nargin<3 || isempty(method)), method='linear'; end
if( nargin<4 || isempty(bbox)), bbox='loose'; end
if( nargin<5 || isempty(show)), show=0; end
if( nargin<6 || isempty(pad)), pad=0; end
if( ndims(I)~=2 ), error('I must a MxN array'); end
if( any(size(H)~=[3 3])), error('H must be 3x3'); end
if( rank(H)~=3), error('H must be full rank.'); end
if( ~any(strcmp(bbox,{'loose','crop'})));
  error(['illegal value for bbox: ' bbox]); end

% pad I and convert to double, makes interpolation simpler
classI=class(I); [m,n]=size(I); m=m+4; n=n+4;
if(~strcmp(classI,'double')), I=double(I); end
I = padarray(I,[2,2],pad,'both');

% set origin to be center of image
r0 = (-m+1)/2; r1 = (m-1)/2;
c0 = (-n+1)/2; c1 = (n-1)/2;

% If 'loose' then get bounds of resulting image. To do this project the
% original points accoring to the homography and see the bounds. Note
% that since a homography maps a quadrilateral to a quadrilateral only
% need to look at where the bounds of the quadrilateral are mapped to.
if( strcmp(bbox,'loose') )
  P = H * [r0 r1 r0 r1; c0 c0 c1 c1; 1 1 1 1];
  rs=P(1,:)./P(3,:); r0=min(rs(:)); r1=max(rs(:));
  cs=P(2,:)./P(3,:); c0=min(cs(:)); c1=max(cs(:));
end

% apply inverse homography on meshgrid in destination image
m1=floor(r1-r0+1); cs=c0:c1; cs=cs(ones(1,m1),:);
n1=floor(c1-c0+1); rs=(r0:r1)'; rs=rs(:,ones(n1,1));
P = H \ [rs(:)'; cs(:)'; ones(1,m1*n1)];
rs = P(1,:)./P(3,:) + (m+1)/2;
cs = P(2,:)./P(3,:) + (n+1)/2;

% now texture map results ('nearest','linear' inlined for speed)
if( strcmp(method,'nearest') )
  rs = min(max(floor(rs+.5),1),m);
  cs = min(max(floor(cs+.5),1),n);
  J = I( rs+(cs-1)*m );
elseif(strncmpi(method,'lin',3) || strncmpi(method,'bil',3))
  rs=min(max(rs,2),m-1); wrs=rs-floor(rs);
  cs=min(max(cs,2),n-1); wcs=cs-floor(cs);
  ids = floor(rs)+floor(cs-1)*m;
  J = (I(ids).*(1-wrs) + I(ids+1).*wrs).*(1-wcs) + ...
    (I(ids+m).*(1-wrs) + I(ids+(m+1)).*wrs).*wcs;
else
  J = interp2( I, cs, rs, method, 0 );
end
J=reshape(J,[m1 n1]); J=J(3:end-2,3:end-2);
if(~strcmp(classI,'double')), J=feval(classI,J ); end

% optionally show
if( show )
  figure(show); clf; im(I(3:end-2,3:end-2));
  figure(show+1); clf; im(J);
end
