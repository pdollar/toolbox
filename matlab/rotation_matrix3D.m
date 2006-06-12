% Uses Rodrigues's formula to create a 3x3 rotation matrix R.
%
% The results of R*xMatrix is x rotated theta degrees about u.
%
% INPUTS
%   u       - axis of rotation - specified as (x,y,z)
%   theta   - angle of rotation (radians)
%
% OUTPUTS
%   R       - 3x3 Rotation matrix
%
% EXAMPLE
%   R = rotation_matrix3D( [0 0 1], pi/4 )
%   R * [1 0 0]'
%
% DATESTAMP
%   11-Oct-2005  9:00pm
%
% See also RECOVER_ROTATION3D, ROTATION_MATRIX2D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function R = rotation_matrix3D( u, theta )
    u =  u / norm(u);
    U = [ 0 -u(3) u(2) ; u(3) 0 -u(1); -u(2) u(1) 0 ];
    R=eye(3)+U  *sin(theta)+U^2*(1-cos(theta));
