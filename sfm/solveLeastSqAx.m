% Find x that minimizes ||Ax|| under different copnstraints
%
% The problem can be solved with different constraints:
%  Alg 5.6, HZ2, p. 595
%   Find x that minimizes ||Ax|| subject to ||x||=1 and x=G*xHat, where G
%   has rank r
%
% USAGE
%  x = solveLeastSqAx(A)
%  [x,xHat] = solveLeastSqAx(A,G,method)
%
% INPUTS 1
%  A      - constraint matrix, ||Ax|| to be minimized with ||x||=1
%
% INPUTS 2
%
% INPUTS 3 - Find x that minimizes ||Ax|| subject to ||x||=1 and x=G*xHat,
%            where G has rank r
%  A      - constraint matrix
%  G      - condition matrix
%  method - method=2
%
% INPUTS 4
%
% OUTPUTS 1,2,4
%   x     - solution
%
% OUTPUTS 3
%   x     - solution
%   xHat  - vector such that x = G*xHat
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [x,xHat] = solveLeastSqAx(A,G,method)

% Reference: HZ2, Algorithm 5.4, p593
if nargin==1; [U,D,V] = svd(A,0); x=V(:,end); return; end
if nargin==2; error('method argument required'); end

switch method
  case 1
  case 2
    % Find x that minimizes ||Ax|| subject to ||x||=1 and x=G*xHat, where G
    % has rank r
    % Reference: HZ2, Algorithm 5.6, p595
    [U,D,V] = svd(G,0);

    % (ii)
    r = rank(G); Up = U(:,1:r);

    % (iii)
    xp = solveLeastSqAx(A*U2);

    % (iv)
    x = Up*xp;

    % (v)
    if nargout==2;
      Vp = V(:,1:r); xHat = Vp*diag(1./diag(D(1:r,1:r)))*x2;
    end
  case 3
end
