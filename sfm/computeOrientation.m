% Compute Absolute or Exterior Orientation (Pose Estimation)
%
% Absolute is : given x and xp (2 arrays of 3D coordinates), find the best
% transformation such that x=s*R*xp+t
%
% Exterior is : 1 array of 3D position x is known and its 2D projection xp.
% Find the best transformation such that x=projection*(s*R*xp+t)
% (same as Pose Estimation)
%
% USAGE
%  [R,t,s]=computeOrientation(x,xp,method)
%
% INPUTS
%  x,xp    - 3xN or 2xN array of points
%  method  - 'absolute' or 'exterior'
%
% OUTPUTS
%  R       - rotation matrix
%  t       - translation vector
%  s       - scale factor (if not requested, s=1)
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [R,t,s]=computeOrientation(x,xp,method)

n=size(x,2);

switch method
  case 'absolute'
    % Computes the absolute orientation between 2 sets of 3D points
    % Xright=s*R*Xleft + t   . We wan tot recover s,R,T
    % Ref: B.K.P. Horn, H.M. Hilden, and S. Negahdaripour, Closed-Form
    % Solution of Absolute Orientation Using Orthonormal Matrices
    x=normalizePoint(x,4); rr=x(1:3,:);
    xp=normalizePoint(xp,4); rl=xp(1:3,:);
    rrBar=mean(rr,2); rlBar=mean(rl,2);
    rrp=rr-rrBar(:,ones(1,n)); rlp=rl-rlBar(:,ones(1,n));

    M=zeros(3); for i=1:n; M=M+rrp(:,i)*rlp(:,i)'; end
    R=M*inv(sqrtm(M'*M));

    if nargout==2; s=1; else s=sqrt(norm(rr,'fro')/norm(rl,'fro')); end

    t=rrBar-s*R*rlBar;
  case 'exterior'
    % Sedumi and GloptiPoly must be installed and in the path !
    mini='min ';
    for i=1:n
      mini=[mini '(' num2str(xp(1,i)) '-r11*(' num2str(x(1,i)) ...
        ')-r12*(' num2str(x(2,i)) ')-r13*(' num2str(x(3,i)) ')-t1)^2' ...
        '+(' num2str(xp(2,i)) '-r21*(' num2str(x(1,i)) ...
        ')-r22*(' num2str(x(2,i)) ')-r23*(' num2str(x(3,i)) ')-t2)^2+'...
        ]; %#ok<AGROW>
    end
    mini=mini(1:end-1);
    
    var={'r11','r21','r12','r22','r13','r23','t1','t2'};
    if nargout==3
      for i=1:8; strrep(mini,var{i},['s*' var{i}]); end; var{end+1}='s'; 
    end
    for i=2:length(var); var{1}=[var{1} ',' var{i}]; end; var=var{1};
    
    P=defipoly({mini,'r11^2+r12^2+r13^2 == 1','r21^2+r22^2+r23^2 ==1',...
      'r11*r21+r12*r22+r13*r23 == 0'}, var );
    out=gloptipoly(P);
    
    R=rotationMatrix(reshape(out.sol{1}(1:6),2,3)); t=out.sol{1}(7:8);
    
    if nargout==3; s=out.sol{1}(9); end
end
