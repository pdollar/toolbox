% Returns the matrix: R=[cos(t) -sin(t); sin(t) cos(t)].
%
% y=R*x is the result of rotating x theta degress clockwise about the z-axis.  
% One can retrive the angle of rotation via theta = acos(R(1)).
%
% INPUTS
%   theta   - angle of rotation (radians)
%
% OUTPUTS
%   R       - 2x2 Rotation matrix
%
% EXAMPLE
%   R = rotation_matrix2D( pi/6 )
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also ROTATION_MATRIX3D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function R = rotation_matrix2D( theta )
    R=[cos(theta) -sin(theta); sin(theta) cos(theta)];
