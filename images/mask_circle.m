% Creates an image of a 'pie slice' of a circle.
%
% Creates a 2D array of size (2rx2r) with values between 0 and 1.  Specifically, mask has
% values 1 inside the pie slice of the circle defined by angle_start and angle_size.  For
% example, using angle_start=-pi/4 and angle_size=pi/2 would give a quarter circle facing
% right.  nsample conrols the accuracty of the circle at its boundaries.  That is if
% nsamples>1, pixels at the boundary which will have fractions values (when a pixel should
% be say half inside the circle and half outside of the circle).  Note that running time
% is O(nsamples^2*radius^2), so don't use a value that is too high for either.  A series
% of masks whose angles together go from 0-2pi will sum exactly to form a radius r circle.
% r may be either an integer, or an integer + .5.  A pixel is considered to belong to the
% circle iff it is within the given angle and has a value strictly smaller then r.
% 
% INPUTS
%   angle_start       - start position of circle
%   angle_size        - number of radians to continue circle for
%   r                 - mask radius (integer or integer+.5)
%   nsamples          - [optional] controls sampling accuracy [1 by default]
%
% OUTPUTS
%   mask      - the created image, size 2r by 2r
%
% EXAMPLE
%   mask1 = mask_circle( -pi/8, pi/4, 20, 20 ); figure(1); im(mask1); 
%   mask2 = mask_circle( pi/8, pi/8, 20, 20 );  figure(2); im(mask2); 
%   figure(3); im(mask1+mask2);
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MASK_ELLIPSE

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function mask = mask_circle( angle_start, angle_size, r, nsamples )
    if( nargin<4 || isempty(nsamples) ) nsamples = 1; end;

    % create circle
    sampling = -(r-.5/nsamples):1/nsamples:(r-.5/nsamples);
    mask = zeros(nsamples*r*2);     
    [x,y] = meshgrid(sampling, -sampling);
    mask( find( x.^2+y.^2<r^2) ) = 1;

    % keep only values at appropriate angles
    angles = atan2(y,x); angles(find(angles<0))=angles(find(angles<0))+2*pi;
    angle_end = mod( angle_start + angle_size, 2*pi );
    angle_start = mod( angle_start, 2*pi );
    if (angle_start<angle_end)
        mask( find(angles<angle_start | angles>=angle_end ) ) = 0;
    else
        mask( find(angles>=angle_end & angles<angle_start) ) = 0;
    end;

    % shrink by counting samples per 'image' pixel
    if (nsamples>1)
        mask = localsum( mask, nsamples, 'valid' );
        sampling= 1:nsamples:nsamples*r*2; 
        mask = mask(sampling,sampling) / nsamples^2;
    end;
