% Applies a general/special homography on an image I
%
% Takes the center of the image as the origin, not the top left corner.
% Also, the coordinate system is row/column format, so H must be also.
%
% The bounding box of the image is set by the BBOX argument, a string that
% can be 'loose' (default) or 'crop'. When BBOX is 'loose', IR includes the
% whole transformed image, which generally is larger than I. When BBOX is
% 'crop' IR is cropped to include only the central portion of the
% transformed image and is the same size as I. The 'loose' flag is
% currently inexact (because of some padding/cropping). Preserves I's type.
%
% USAGE
%  IR = imtransform2( I, H, [method], [bbox], [show] )      % general hom
%  IR = imtransform2( I, angle, [method], [bbox], [show] )  % rotation
%  IR = imtransform2( I, dx, dy, [method], [bbox], [show] ) % translation
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
%  IR      - transformed image
%
% EXAMPLE - general homography
%  load trees; I=X;
%  R = rotationMatrix( pi/4 ); T = [1; 3]; H = [R T; 0 0 1];
%  IR = imtransform2( I, H, [], 'crop', 1 );
%
% EXAMPLE - rotation
%  load trees;
%  tic; X1 = imrotate( X, 55, 'bicubic', 'crop' ); toc,
%  tic; X2 = imtransform2( X, 55, 'bicubic', 'crop' ); toc
%  clf;  subplot(2,2,1); im(X); subplot(2,2,2); im(X1-X2);
%  subplot(2,2,3); im(X1); subplot(2,2,4); im(X2);
%
% EXAMPLE - translation
%  load trees;
%  XT = imtransform2(X,0,1.5,'bicubic','crop');
%  figure(1); clf; im(X,[0 255]); figure(2); clf; im(XT,[0 255]);
%
% See also TEXTUREMAP, INTERP2

% Piotr's Image&Video Toolbox      Version 2.02
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Liscensed under the Lesser GPL [see external/lgpl.txt]

function IR = imtransform2( I, varargin )

% parse inputs and switch between cases
if( nargin>1 && isscalar(varargin{1}) && ...
    (nargin==2 || ischar(varargin{2})) ) % rotation
  angle = varargin{1};  angle = angle /180 * pi;
  H = [rotationMatrix(angle) [0;0]; 0 0 1];
  IR = imtransform2main( I, H, varargin{2:end} );

elseif( nargin>2 && isscalar(varargin{1}) ...
    && isscalar(varargin{2}) ) % translation
  dx=varargin{1}; dy=varargin{2};
  H = [eye(2) [dy; dx]; 0 0 1];
  IR = imtransform2main( I, H, varargin{3:end} );

else % presumably a general homography
  IR = imtransform2main( I, varargin{:} );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function IR = imtransform2main( I, H, method, bbox, show )

% General homography case
if( ndims(I)~=2 ); error('I must a MxN array'); end
if(any(size(H)~=[3 3])); error('H must be 3 by 3'); end
if(rank(H)~=3); error('H must be full rank.'); end
if(~isempty(bbox) && ~any(strcmp(bbox,{'loose','crop'})));
 error(['illegal value for bbox: ' bbox]); 
end

if( nargin<3 || isempty(method)); method='linear'; end
if( nargin<4 || isempty(bbox)); bbox='loose'; end
if( nargin<5 || isempty(show)); show=0; end

className = class( I );
if(~strcmp(className,'double')); I = double(I); end
I = padarray(I,[1,1],eps,'both');
siz = size(I);

% set origin to be center of image
rStr = (-siz(1)+1)/2; rEnd = (siz(1)-1)/2;
cStr = (-siz(2)+1)/2; cEnd = (siz(2)-1)/2;

% If 'bbox' then get bounds of resulting image. To do this project the
% original points accoring to the homography and see the bounds.  Note
% that since a homography maps a quadrilateral to a quadrilateral only
% need to look at where the bounds of the quadrilateral are mapped to.
if( strcmp(bbox,'loose') )
  pr = H * [rStr rEnd rStr rEnd; cStr cStr cEnd cEnd; 1 1 1 1];
  rowDst = pr(1,:) ./ pr(3,:);  colDst = pr(2,:) ./ pr(3,:);
  rStr = min(rowDst(:));  rEnd = max(rowDst(:));
  cStr = min(colDst(:));  cEnd = max(colDst(:));
end

% apply inverse homography on meshgrid in destination image
[colGrid,rowGrid] = meshgrid( cStr:cEnd, rStr:rEnd );
[mRow,nCol] = size( colGrid );
pr = inv(H) * [rowGrid(:)'; colGrid(:)'; ones(1,mRow*nCol)];
rowLocs = pr(1,:) ./ pr(3,:) + (siz(1)+1)/2;
rowLocs = reshape(rowLocs,mRow,nCol);
colLocs = pr(2,:) ./ pr(3,:) + (siz(2)+1)/2;
colLocs = reshape(colLocs,mRow,nCol);

% now texture map results
IR = interp2( I, colLocs, rowLocs, method );
IR(isnan(IR)) = 0;
IR = arrayToDims( IR, size(IR)-2 ); %undo extra padding (exact if 'crop')
if(~strcmp(className,'double')); IR=feval(className,IR ); end

% optionally show
if( show )
  I = arrayToDims( I, size(I)-2 );
  figure(show); clf; im(I);
  figure(show+1); clf; im(IR);
end
