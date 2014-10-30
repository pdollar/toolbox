% Custom version of imrotate that demonstrates use of apply_homography.
%
% Works exactly the same as imrotate.  For usage see imrotate.
%
% USAGE
%  IR = imrotate2( I, angle, [method], [bbox] )
%
% INPUTS
%  I       - 2D image [converted to double]
%  angle   - angle to rotate in degrees
%  method  - ['linear'] 'nearest', 'linear', 'spline', 'cubic'
%  bbox    - ['loose'] 'loose' or 'crop'
%
% OUTPUTS
%  IR      - rotated image
%
% EXAMPLE
%  load trees;
%  tic; X1 = imrotate( X, 55, 'bicubic' ); toc,
%  tic; X2 = imrotate2( X, 55, 'bicubic' ); toc
%  clf;  subplot(2,2,1); im(X); subplot(2,2,2); im(X1-X2);
%  subplot(2,2,3); im(X1); subplot(2,2,4); im(X2);
%
% See also IMROTATE

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function IR = imrotate2( I, angle, method, bbox )

if( ~isa( I, 'double' ) ); I = double(I); end
if( nargin<3 || isempty(method)); method='linear'; end
if( nargin<4 || isempty(bbox) ); bbox='loose'; end
if( strcmp(method,'bilinear') || strcmp(method,'lin')); method='linear';end

% convert arguments for apply_homography
angle_rads = angle /180 * pi;
R = rotationMatrix( angle_rads );
H = [R [0;0]; 0 0 1];
IR = apply_homography( I, H, method, bbox );
