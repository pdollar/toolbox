% Triangulation
%
function X=computeSFromxM(x,xp,P,Pp,method)

if nargin<5; method=0; end

n=size(x,2);

switch method
  case 0
    % Linear triangulation
    % Reference: HZ2, p312
    
    X=zeros(4,n);
    for  i = 1 : n
      % Initial estimate of X
      A = [ x(1,i)*P(3,:)-P(1,:); x(2,i)*P(3,:)-P(2,:); ...
        xp(1,i)*Pp(3,:)-Pp(1,:); xp(2,i)*Pp(3,:)-Pp(2,:)];
      [ U, S, V ]=svd(A,0);
      X( :, i )=V( :, 4 );
    end
    X=normalizePoint(X,4);
    
  case Inf
    % Linear triangulation
    % Reference: HZ2, p318, Algorithm 12.1    
end
