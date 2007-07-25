% Computes the trifocal tensor given correspondences
%
% Several methods are implemented
%
% USAGE
%  [T, TNorm, A] = computeTFT(x,xp,xpp,method)
%  [T, e2, e3] = computeTFT(x,xp,xpp,method)
%
% INPUTS
%  x,xp,xpp  - matching 2D projections (2xn or 3xn)
%
% OUTPUTS
%  T         - trifocal tensor
%  TNorm     - normalized version of the trifocal tensor
%  A         - A matrix used during the computation of T
%  e2,e3     - epipoles in images 2 and 3
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [T,arg2,arg3] = computeTFT(x,xp,xpp,method)

if nargin<4 || isempty(method); method=1; end

npts=size(x1,2);
[x,H] = normalizePoint(x);
[xp,Hp] = normalizePoint(xp);
[xpp,Hpp] = normalizePoint(xpp);

switch method
  case 1
    % Reference: HZ2, p394, Algorithm 16.1
    % (iii) Build the constraint matrix
    % t in At stores elements of T column per column.
    % We follow formula 16.1, p. 393, HZ2
    A = zeros(4*npts,27);
    k = [0 9 18];
    for i=1:2
      for l=1:2
        range = (2*i+j-2)*npts+ (1 : npts);

        A(range, [9 18 27]) = x' .* repmat( xp(i,:).*xpp(l,:), [3 1])';
        A(range, 6+i+k) = -x' .* xpp([l l l],:)';
        A(range, 3*l+k) = -x' .* xp([i i i],:)';
        A(range, 3*(l-1)+i+k) = x';
      end
    end

    [U,D,V] = svd(A,0); TNorm = reshape(V(:,end),3,3,3);
    if nargout>=2; arg2=TNorm; end; if nargout>=3; arg3=A; end
  case 2
    % Reference: HZ2, p396, Algorithm 16.2
    % (i) and (ii)
    [disc,TNorm,A] = computeTFT(x,xp,xpp,method);

    % (iii)
    [ep,epp]=extractFromTFT(TNorm);
    if nargout>=2; arg2=ep; end; if nargout>=3; arg3=epp; end
    
    ep=[ diag(-ep([1 1 1])) diag(-ep([2 2 2])) diag(-ep([3 3 3])) ];
    epp=blkdiag(epp,epp,epp);
    E=[blkdiag(epp,epp,epp) blkdiag(ep,ep,ep)];
    
    % (v)
    a=solveLeastSqAx(A*E,E,3);
    T=reshape(E*a,3,3,3);
end

% Denormalize
Y=zeros(3,3,3);
for ii = 1:3
  Y(:,:,ii) = inv(Hp) * TNorm(:,:,ii)*(inv(Hpp))';
end
for i = 1:3
  T(:,:,i) = H(1,i)*Y(:,:,1) + H(2,i)*Y(:,:,2) + H(3,i)*Y(:,:,3);
end
