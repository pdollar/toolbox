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
%  IR = imtransform2( I, H, [method], [bbox], [show] )
%  IR = imtransform2( I, angle, [method], [bbox], [show] )
%  IR = imtransform2( I, dx, dy, [method], [bbox], [show] )
%
% INPUTS - 1 - general homography
%  I       - input black and white image (2D double or unint8 array)
%  H       - 3x3 nonsingular homography matrix
%  method  - ['linear'] for interp2 'nearest','linear','spline','cubic'
%  bbox    - ['loose'] see above for meaning of bbox 'loose','crop')
%  show    - [0] figure to use for optional display
%
% INPUTS - 2 - rotation case
%  I       - 2D image [converted to double]
%  angle   - angle to rotate in degrees
%  method  - ['linear'] 'nearest', 'linear', 'spline', 'cubic'
%  bbox    - ['loose'] 'loose' or 'crop'
%  show    - [0] figure to use for optional display
%
% INPUTS - 3 - translation case
%  I       - 2D image [converted to double]
%  dx      - x translation (right)
%  dy      - y translation (up)
%  method  - ['linear'] 'nearest', 'linear', 'spline', 'cubic'
%  bbox    - ['loose'] 'loose' or 'crop'
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  IR      - transformed image
%
% EXAMPLE - 1
%  load trees; I=X;
%  R = rotationMatrix( pi/4 ); T = [1; 3]; H = [R T; 0 0 1];
%  IR = imtransform2( I, H, [], 'crop', 1 );
%
% EXAMPLE - 2
%  load trees;
%  tic; X1 = imrotate( X, 55, 'bicubic', 'crop' ); toc,
%  tic; X2 = imtransform2( X, 55, 'bicubic', 'crop' ); toc
%  clf;  subplot(2,2,1); im(X); subplot(2,2,2); im(X1-X2);
%  subplot(2,2,3); im(X1); subplot(2,2,4); im(X2);
%
% EXAMPLE - 3
%  load trees;
%  XT = imtransform2(X,0,1.5,'bicubic','crop');
%  figure(1); im(X,[0 255]); figure(2); im(XT,[0 255]);
%
% See also TEXTURE_MAP

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function IR = imtransform2( varargin )

I=varargin{1};
try %#ok<TRYNC>
  H=varargin{2}; method=varargin{3}; bbox=varargin{4}; show=varargin{5};
end

if size(varargin{2})==1
  if nargin==2 || ischar(varargin{3}) % Rotation case
    angle=varargin{2};

    angle_rads = angle /180 * pi;
    R = rotationMatrix( angle_rads );
    H = [R [0;0]; 0 0 1];
    IR = imtransform2( I, H, method, bbox,show );
    return
  else % Translation case
    dy=varargin{2}; dx=varargin{3};
    try %#ok<TRYNC>
      method=varargin{4}; bbox=varargin{5}; show=varargin{6};
    end

    H = [eye(2) [dy; dx]; 0 0 1];
    IR = imtransform2( I, H, method, bbox, show );
    return
  end
end

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
  row_dest = pr(1,:) ./ pr(3,:);  col_dest = pr(2,:) ./ pr(3,:);
  minr = floor(min(row_dest(:)));  maxr = ceil(max(row_dest(:)));
  minc = floor(min(col_dest(:)));  maxc = ceil(max(col_dest(:)));
elseif (strcmp(bbox,'crop'))
  minr = rstart; maxr = rend;
  minc = cstart; maxc = cend;
else
  error('illegal value for bbox');
end

mrows = maxr-minr+1;
ncols = maxc-minc+1;

% apply inverse homography on meshgrid in destination image
[col_dest_grid,row_dest_grid] = meshgrid( minc:maxc, minr:maxr );
pr = inv(H) * [row_dest_grid(:)'; col_dest_grid(:)'; ones(1,mrows*ncols)];
row_sample_locs = pr(1,:) ./ pr(3,:) + (siz(1)+1)/2;
row_sample_locs = reshape(row_sample_locs,mrows,ncols);
col_sample_locs = pr(2,:) ./ pr(3,:) + (siz(2)+1)/2;
col_sample_locs = reshape(col_sample_locs,mrows,ncols);

% now texture map results
IR = interp2( I, col_sample_locs, row_sample_locs, method );
IR(isnan(IR)) = 0;
IR = arraycrop2dims( IR, size(IR)-6 ); %undo extra padding

if(~strcmp(classname,'double')); IR=feval(classname,IR ); end

% optionally show
if ( show)
  I = arraycrop2dims( I, size(IR)-2 );
  figure(show); clf; im(I);
  figure(show+1); clf; im(IR);
end
