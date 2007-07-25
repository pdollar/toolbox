function [arg1, arg2]=extractFromTFT(T)

switch nargout
  case 2
    % Extract the epipoles of the 2 other views
    % Reference: HZ2, p.395
    V=zeros(3,3); for i=1:3; V(i,:)=solveLeastSqAx(T(:,:,i))'; end
    epp=solveLeastSqAx(V);
    for i=1:3; V(i,:)=solveLeastSqAx(T(:,:,i)')'; end
    ep=solveLeastSqAx(V);

    arg1=ep; arg2=epp;
end
