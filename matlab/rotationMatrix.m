% Performs different operations dealing with a rotation matrix
%
% USAGE
%  R = rotationMatrix( M )
%  [u,theta] = rotationMatrix( R )
%  R = rotationMatrix( theta )
%  R = rotationMatrix( u )
%  R = rotationMatrix( u, theta )
%
% INPUTS - 1 - Finds the closest matrix to a given matrix M
%  M       - 3x3 matrix
%
% INPUTS - 2 - Extract the axis and the angle of a 3x3 rotation matrix
%  R       - 3x3 Rotation matrix
%
% INPUTS - 3 - Creates a 2x2 rotation matrix from an angle
%  theta   - angle of rotation (radians)
%
% INPUTS - 4 - creates a 3x3 rotation matrix from a rotation vector
%  u       - 1x3 or 3x1 axis of rotation - norm is theta
%
% INPUTS - 5 - creates a 3x3 rotation matrix from a rotation vector
%  u       - axis of rotation
%  theta   - angle of rotation (radians)
%
% OUTPUTS - 1,4,5
%  R       - 3x3 rotation matrix
%
% OUTPUTS - 2
%  u       - axis of rotation
%  theta   - angle of rotation (radians)
%
% OUTPUTS - 3
%  R       - 2x2 Rotation matrix
%
% EXAMPLE
%  R = rotationMatrix( [0 0 1], pi/4 );
%  [u,theta]  = rotationMatrix( R )
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
  return
end

%%% Takes a rotation matrix and extracts the rotation angle and axis.
if all(size(varargin{1})==[3 3]) && nargout==2
  R=varargin{1};
  % find location of eigenvector with eigen value other than 1
  % eigenvalue has form cos(theta) +- i sin(theta)
  [v,d]=eig( R );
  [dr, disc] = find( imag(d)==0 & real(d)~=0 );  %#ok<NASGU>
  u = v(:,dr);
  varargout{1}=u;
  if (dr==1)
    theta = acos(real( d(2,2) ));
  else
    theta = acos(real( d(1,1) ));
  end

  %now resolve sign ambiguity
  epsilon = ones(3)*.000001;
  dif = R-rotationMatrix(u,theta);
  if (any(any(dif<-epsilon)) || any(any(dif>epsilon))); theta = -theta; end
  varargout{2}=theta;
  return
end

%%% Returns the matrix: R=[cos(t) -sin(t); sin(t) cos(t)].
if all(size(varargin{1})==[1 1])
  theta=varargin{1};
  varargout{1}=[cos(theta) -sin(theta); sin(theta) cos(theta)];
  return
end

%%% Uses Rodrigues's formula to create a 3x3 rotation matrix R.
if all(sort(size(varargin{1}))==[1 3])
  u=varargin{1};
  if length(varargin)==1
    theta=norm(u);
  else
    if ~isnumeric(varargin{2}); error('Input format not supported'); end
    theta=varargin{2};
  end
  u =  u / norm(u);
  U = [ 0 -u(3) u(2) ; u(3) 0 -u(1); -u(2) u(1) 0 ];
  varargout{1}=eye(3)+U  *sin(theta)+U^2*(1-cos(theta));
  return
end

error('Input format not supported');
