% Canonical case
function M=convertPF(P,Pp,F)

if nargin==2; F=Pp; end

if isempty(P)
  % Reference: HZ2, p256, Result 9.14
  [U,S,V] = svd(F); %#ok<NASGU>
  e = U(:,3);
  M = [ skew(e)*F e ];
  return
end

if isempty(F)
  % Reference: HZ2, p246, Table 9.1
  if nargin==3
    
  else
    ep=P(:,4);
    M = skew(ep)
  end
  return
end

error('Bad input');
