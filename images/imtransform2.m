% Applies a general/special homography on an image I
%
% Takes the center of the image as the origin, not the top left corner.
% Also, the coordinate system is row/ column format, so H must be also.
%
% The bounding box of the image is set by the BBOX argument, a string that
% can be 'loose' (default) or 'crop'. When BBOX is 'loose', IR includes the
% whole transformed image, which generally is larger than I. When BBOX is
% 'crop' IR is cropped to include only the central portion of the
% transformed image and is the same size as I.  Preserves I's type.
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

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

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

if( nargin<3 || isempty(method)); method='linear'; end
if( nargin<4 || isempty(bbox)); bbox='loose'; end
if( nargin<5 || isempty(show)); show=0; end

classname = class( I );
if(~strcmp(classname,'double')); I = double(I); end
I = padarray(I,[3,3],eps,'both');
siz = size(I);

% set origin to be center of image
rstart = (-siz(1)+1)/2; rend = (siz(1)-1)/2;
cstart = (-siz(2)+1)/2; cend = (siz(2)-1)/2;

% If 'bbox' then get bounds of resulting image. To do this project the
% original points accoring to the homography and see the bounds.  Note
% that since a homography maps a quadrilateral to a quadrilateral only
% need to look at where the bounds of the quadrilateral are mapped to.
% If 'same' then simply use the original image bounds.
if (strcmp(bbox,'loose'))
  pr = H * [rstart rend rstart rend; cstart cstart cend cend; 1 1 1 1];
  rowDst = pr(1,:) ./ pr(3,:);  colDst = pr(2,:) ./ pr(3,:);
  minr = floor(min(rowDst(:)));  maxr = ceil(max(rowDst(:)));
  minc = floor(min(colDst(:)));  maxc = ceil(max(colDst(:)));
elseif (strcmp(bbox,'crop'))
  minr = rstart; maxr = rend;
  minc = cstart; maxc = cend;
else
  error('illegal value for bbox');
end

mrows = maxr-minr+1;
ncols = maxc-minc+1;

% apply inverse homography on meshgrid in destination image
[colDstGrid,rowDstGrid] = meshgrid( minc:maxc, minr:maxr );
pr = inv(H) * [rowDstGrid(:)'; colDstGrid(:)'; ones(1,mrows*ncols)];
rowSampleLocs = pr(1,:) ./ pr(3,:) + (siz(1)+1)/2;
rowSampleLocs = reshape(rowSampleLocs,mrows,ncols);
colSampleLocs = pr(2,:) ./ pr(3,:) + (siz(2)+1)/2;
colSampleLocs = reshape(colSampleLocs,mrows,ncols);

% now texture map results
IR = interp2( I, colSampleLocs, rowSampleLocs, method );
IR(isnan(IR)) = 0;
IR = arrayToDims( IR, size(IR)-6 ); %undo extra padding

if(~strcmp(classname,'double')); IR=feval(classname,IR ); end

% optionally show
if ( show)
  I = arrayToDims( I, size(IR)-2 );
  figure(show); clf; im(I);
  figure(show+1); clf; im(IR);
end
