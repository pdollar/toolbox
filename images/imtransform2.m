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
%  J = imtransform2( I, H, [method], [bbox], [show] )      % general hom
%  J = imtransform2( I, angle, [method], [bbox], [show] )  % rotation
%  J = imtransform2( I, dx, dy, [method], [bbox], [show] ) % translation
%
% INPUTS - common
%  I       - 2D image [converted to double]
%  method  - ['linear'] 'nearest', 'spline', 'cubic' (for interp2)
%  bbox    - ['loose'] or 'crop'
%  show    - [0] figure to use for optional display
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
%  J = imtransform2(I,H,method,'crop',1);
%
% EXAMPLE - general homography (out of plane rotation)
%  load trees; I=X; method='nearest';
%  R = rotationMatrix([0 1 0],pi/4); z=500;
%  H = R; H(1:2,:)=H(1:2,:)*z; H(:,3)=H(:,3)*z;
%  J = imtransform2(I,H,method,'loose',1);
%
% EXAMPLE - rotation
%  load trees; I=X; method='bicubic';
%  tic; Y1 = imrotate(I,55,method,'crop'); toc
%  tic; Y2 = imtransform2(I,55,method,'crop'); toc
%  clf; subplot(2,2,1); im(I); subplot(2,2,2); im(Y1-Y2);
%  subplot(2,2,3); im(Y1); subplot(2,2,4); im(Y2);
%
% EXAMPLE - translation
%  load trees; I=X; method='bicubic';
%  J = imtransform2(X,0,1.5,method,'crop');
%  figure(1); clf; im(I,[0 128]); figure(2); clf; im(J,[0 128]);
%
% See also TEXTUREMAP, INTERP2
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
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

function J = imtransform2main( I, H, method, bbox, show )

% check inputs
if( nargin<3 || isempty(method)), method='linear'; end
if( nargin<4 || isempty(bbox)), bbox='loose'; end
if( nargin<5 || isempty(show)), show=0; end
if( ndims(I)~=2 ), error('I must a MxN array'); end
if( any(size(H)~=[3 3])), error('H must be 3x3'); end
if( rank(H)~=3), error('H must be full rank.'); end
if( ~any(strcmp(bbox,{'loose','crop'})));
  error(['illegal value for bbox: ' bbox]); end

% set origin to be center of image
sizI = size(I)+2;
r0 = (-sizI(1)+1)/2; r1 = (sizI(1)-1)/2;
c0 = (-sizI(2)+1)/2; c1 = (sizI(2)-1)/2;

% If 'loose' then get bounds of resulting image. To do this project the
% original points accoring to the homography and see the bounds. Note
% that since a homography maps a quadrilateral to a quadrilateral only
% need to look at where the bounds of the quadrilateral are mapped to.
if( strcmp(bbox,'loose') )
  P = H * [r0 r1 r0 r1; c0 c0 c1 c1; 1 1 1 1];
  rowDst = P(1,:)./P(3,:); colDst=P(2,:)./P(3,:);
  r0 = min(rowDst(:)); r1 = max(rowDst(:));
  c0 = min(colDst(:)); c1 = max(colDst(:));
end

% apply inverse homography on meshgrid in destination image
[colGr,rowGr] = meshgrid(c0:c1,r0:r1); sizJ=size(colGr);
P = H \ [rowGr(:)'; colGr(:)'; ones(1,prod(sizJ))];
rs = reshape( P(1,:)./P(3,:), sizJ ) + (sizI(1)+1)/2;
cs = reshape( P(2,:)./P(3,:), sizJ ) + (sizI(2)+1)/2;

% now texture map results ('nearest' inlined for speed)
classI=class(I); T=I; I=zeros(sizI); I(2:end-1,2:end-1)=T;
if( strcmp(method,'nearest') )
  rs = min(max(floor(rs+.5),1),sizI(1));
  cs = min(max(floor(cs+.5),1),sizI(2));
  J = I( rs+(cs-1)*sizI(1) );
else
  I(:,[1 end])=eps; I([1 end],:)=eps;
  J = interp2( I, cs, rs, method );
  J(isnan(J)) = 0;
end
J = J(2:end-1,2:end-1);
if(~strcmp(classI,'double')), J=feval(classI,J ); end

% optionally show
if( show )
  figure(show); clf; im(I(2:end-1,2:end-1));
  figure(show+1); clf; im(J);
end
