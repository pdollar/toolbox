% Canonical case
function M=convertPF(P,Pp)

if ~isempty(P) && ~isempty(Pp)
  % Reference: HZ2, p246, Table 9.1
  [U,S,V]=svd(P);
  C = V(:,3);
  ep = Pp*C;
  M=skew(ep)*Pp*pinv(P);
  return
end

F=Pp;

if isempty(P)
  % Reference: HZ2, p256, Result 9.14
  [U,S,V] = svd(F); %#ok<NASGU>
  e = U(:,3);
  M = [ skew(e)*F e ];
  return
end

if isempty(F)
  % Reference: HZ2, p246, Table 9.1
  ep=P(:,4);
  M = skew(ep)*P(:,1:3);
  return
end

error('Bad input');
