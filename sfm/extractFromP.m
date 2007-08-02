% Extract information from a projection matrix
%
% USAGE
%  [K,R,t]=extractFromP(P,isProj)
%
% INPUTS
%  P       - P, projection matrix
%  isProj  - [1] flag indicating if the camera ia projective one
%
% OUTPUTS
%  K      - intrinsic parameter matrix
%  R      - rotation matrix
%  t      - translation vector
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

% 
function [K,R,t]=extractFromP(P,isProj)

if nargin<2; isProj=1; end

if isProj
  % Reference: HZ2, p163
  [K,R]=rq(P(:,1:3));
  if nargout>2; t=inv(K)*P(:,4); end
else
  % Reference: HZ2, p169
end
