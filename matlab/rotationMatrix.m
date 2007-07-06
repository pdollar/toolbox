% Operates different operations dealing with a rotation matrix
%
% USAGE
%  [u,theta] = recover_rotation3D( R )
%
% INPUTS - 1
%  R       - 3x3 Rotation matrix
%
% INPUTS - 2
%  theta   - angle of rotation (radians)
%
% INPUTS - 3
%  u       - 1x3 or 3x1 axis of rotation - norm is theta
%
% OUTPUTS - 1
%  u       - axis of rotation
%  theta   - angle of rotation (radians)
%
% OUTPUTS - 2
%  R       - 2x2 Rotation matrix
%
% OUTPUTS - 3
%  R       - 3x3 Rotation matrix
%
% EXAMPLE
%  R = rotation_matrix3D( [0 0 1], pi/4 );
%  [u,theta]  = recover_rotation3D( R )
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function varargout=rotationMatrix(varargin)

%%% Find the closest rotation matrix 
if all(size(varargin{1})==[3 3]) && nargout==1
  [U,S,V]=svd(varargin{1});
  varargout{1}=U*V';
end

%%% Takes a rotation matrix and extracts the rotation angle and axis.
if all(size(varargin{1})==[3 3]) && nargout==2
  R=varargin{1};
  % find location of eigenvector with eigen value other than 1
  % eigenvalue has form cos(theta) +- i sin(theta)
  [v,d]=eig( R );
  [dr, dc] = find( imag(d)==0 & real(d)~=0 );  %#ok<NASGU>
  u = v(:,dr);
  varargout{1}=u;
  if (dr==1)
    theta = acos(real( d(2,2) ));
  else
    theta = acos(real( d(1,1) ));
  end

  %now resolve sign ambiguity
  epsilon = ones(3)*.000001;
  dif = R-rotation_matrix3D(u,theta);
  if (any(any(dif<-epsilon)) || any(any(dif>epsilon))); theta = -theta; end
  varargout{2}=theta;
end

%%% Returns the matrix: R=[cos(t) -sin(t); sin(t) cos(t)].
if all(size(varargin{1})==[1 1])
  theta=varargin{1};
  varargout{1}=[cos(theta) -sin(theta); sin(theta) cos(theta)];
end

%%% Uses Rodrigues's formula to create a 3x3 rotation matrix R.
if all(sort(size(varargin{1}))==[1 3]) && length(varargin)==1
  u=varargin{1};
  theta=norm(u);
  u =  u / theta;
  U = [ 0 -u(3) u(2) ; u(3) 0 -u(1); -u(2) u(1) 0 ];
  varargout{1}=eye(3)+U  *sin(theta)+U^2*(1-cos(theta));
end
