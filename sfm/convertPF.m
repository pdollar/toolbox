% Canonical case
function M=convertPF(P,Pp,isProj)

if nargin<3; isProj=true; end

if ~isempty(P) && ~isempty(Pp)
  % Reference: HZ2, p246, Table 9.1
  [U,S,V]=svd(P);
  C = V(:,end);
  ep = Pp*C;
  M=skew(ep)*Pp*pinv(P);
  return
end

F=Pp; Pp=P;

if isProj
  if isempty(F)
    % Reference: HZ2, p246, Table 9.1
    ep=Pp(:,4);
    M = skew(ep)*Pp(:,1:3);
    return
  else
    % Reference: HZ2, p256, Result 9.14
    [U,S,V] = svd(F); %#ok<NASGU>
    ep = U(:,end);
    M = [ skew(ep)*F ep ];
    return
  end
else    % F has form 14.1, HZ2, p345 :  [ 0 0 a; 0 0 b; c d e ]
  if isempty(F)
    % Reference: HZ2, p348, table 14.1
    M=[ 0 0 Pp(2,3); 0 0 -Pp(1,3); Pp(1,3)*Pp(2,1)-Pp(1,1)*Pp(2,3) ...
      Pp(1,3)*Pp(2,2)-Pp(1,2)*Pp(2,3) Pp(1,3)*Pp(2,4)-Pp(2,3)*P(1,4) ];
    return
  else
    % Reference: HZ2, p348, table 14.1
    % As there is an ambiguity, impose the top left to be from a matrix
    % Sedumi and GloptiPoly must be installed and in the path !    
    P=defipoly({['mini (' num2str(F(1,3)) '-m23)^2+(' num2str(F(2,3)) ...
      ' +m13)^2+(' num2str(F(3,1)) '-m13*m21+m11*m23)^2+(' ...
      num2str(F(3,2)) '-m13*m22+m12*m23)^2+(' num2str(F(3,3)) ...
      '-m13*t2+m23*t1)^2'],'m11^2+m12^2+m13^2 == 1',...
      'm21^2+m22^2+m23^2 ==1','m11*m21+m12*m22+m13*m23 == 0'}, ...
      'm11,m12,m13,t1,m21,m22,m23,t2' );
    out=gloptipoly(P);
    
    M=zeros(3,4);
    M(1,:)=out.sol{1}(1:4); M(2,:)=out.sol{1}(5:8); M(3,4)=1;
    return
  end
end
error('Bad input');
