% Translate an image to subpixel accuracy.
%
% Note that for subplixel accuracy cannot use nearest neighbor interp.
%
% USAGE
%  IR = imtranslate( I, dx, dy, [method], [bbox] )
%
% INPUTS
%  I       - 2D image [converted to double]
%  dx      - x translation (right)
%  dy      - y translation (up)
%  method  - ['linear'] 'nearest', 'linear', 'spline', 'cubic'
%  bbox    - ['loose'] 'loose' or 'crop'
%
% OUTPUTS
%  IR      - translated image
%
% EXAMPLE
%  load trees;
%  XT = imtranslate(X,0,1.5,'bicubic','crop');
%  figure(1); im(X,[0 255]); figure(2); im(XT,[0 255]);
%
% See also IMROTATE2

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function IR = imtranslate( I, dx, dy, method, bbox )

if( ~isa( I, 'double' ) ); I = double(I); end
if( nargin<4 || isempty(method)); method='linear'; end
if( nargin<5 || isempty(bbox) ); bbox='loose'; end
if( strcmp(method,'bilinear') || strcmp(method,'lin')); method='linear';end

% convert arguments for apply_homography
H = [eye(2) [dy; dx]; 0 0 1];
IR = apply_homography( I, H, method, bbox );
