% Takes a rotation matrix and extracts the rotation angle and axis.
%
% INPUTS
%   R       - 3x3 Rotation matrix
%
% OUTPUTS
%   u       - axis of rotation
%   theta   - angle of rotation (radians)
%
% EXAMPLE
%   R = rotation_matrix3D( [0 0 1], pi/4 );
%   [u,theta]  = recover_rotation3D( R )
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also ROTATION_MATRIX3D

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [u,theta] = recover_rotation3D( R )
    % find location of eigenvector w evalue other than 1
    % eigenvalue has form cos(theta) +- i sin(theta)
    [v,d]=eig( R ); 
    [dr, dc] = find( imag(d)==0 & real(d)~=0 ); 
    u = v(:,dr);
    if (dr==1)
        theta = acos(real( d(2,2) ));
    else
        theta = acos(real( d(1,1) ));
    end

    %now resolve sign ambiguity
    epsilon = ones(3)*.000001;
    dif = R-rotation_matrix3D(u,theta);
    if (any(any(dif<-epsilon)) || any(any(dif>epsilon)))
        theta = -theta;
    end
