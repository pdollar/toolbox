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
    M=zeros(3,4); M(3,4)=1;
    M(1,3)=-F(2,3);
    M(2,3)=F(1,3);
    M(1,1)=-(F(3,1)/M(1,3)*M(2,3)/M(1,3)-1)/(1+(M(2,3)/M(1,3))^2);
    M(2,1)=(F(3,1)+M(1,1)*M(2,3))/M(1,3);

    M(1,2)=-((F(3,2)/M(1,3)-1)*M(2,3)/M(1,3))/(1+(M(2,3)/M(1,3))^2);
    M(2,2)=(F(3,2)+M(1,2)*M(2,3))/M(1,3);
    M(1,4)=1; M(2,4)=(F(3,3)+M(2,3)*M(1,4))/M(1,3);
    return
  end
end
error('Bad input');
