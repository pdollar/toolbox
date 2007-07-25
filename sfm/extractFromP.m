% K[R|t]
function [K,R,t]=decomposeP(P,isProj)

if nargin<2; isProj=1; end

if isProj
  % Reference: HZ2, p163
  [K,R]=rq(P(:,1:3));
  if nargout>2; t=inv(K)*P(:,4); end
else
  % Reference: HZ2, p169
end
