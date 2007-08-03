% Computes SFM from multiple views on a rigid object
%
% isProj==false
%  method 0 is Tomasi-Kanade without orthonormality constraints
%  method Inf is Tomasi-Kanade with orthonormality constraints
%
% USAGE
%  [X,Pp,WFinal,errReproj]=computeSMFromMultx(x,isProj,method)
%
% INPUTS
%  x            - 2xNxT or 3xNxT coordinate matrix
%  isProj       - [false] flag saying if the geometry is projective
%  method       - [Inf] method to be used
%
% OUTPUTS
%  X            - 3xN 3Dcoordinates of the object
%  Pp           - 3x4xT different projection matrices
%  WFinal       - only useful internally
%  errReprojR   - final reprojection error
%
% EXAMPLE
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [X,Pp,errReproj,WFinal]=computeSMFromMultx(x,isProj,method)

if nargin<2 || isempty(isProj); isProj=false; end
if nargin<3; method=Inf; end

f=size(x,3); n=size(x,2); errReproj=Inf;

switch method
  case 0
    if ~isProj
      % Tomasi Kanade without the metric constraint
      % Affine camera matrix, MLE estimation (Tomasi Kanade)
      % Reference: HZ2, p437, Algorithm 18.1
      W=zeros(2*f,n);
      for i=1:f
        temp=normalizePoint(x(:,:,i),3); W(2*i-1:2*i,:)=temp(1:2,:);
      end
      WFinal=W;

      ti=mean(W,2);
      W=W-ti(:,ones(1,n)); [U,S,V]=svd(W);
      M=[S(1,1)*U(:,1),S(2,2)*U(:,2),S(3,3)*U(:,3)];
      H=[M(1:2,:);cross(M(1,:),M(2,:))]; %Get the first matrix to be Id
      M=M*inv(H);

      Pp=zeros(3*f,4);
      Pp(1:3:end,1:3)=M(1:2:end,:); Pp(2:3:end,1:3)=M(2:2:end,:);
      Pp(3:3:end,4)=1;
      for i=1:f
        Pp(3*i-2:3*i-1,4)=ti(2*i-1:2*i)-M(2*i-1:2*i,:)*[ti(1:2);0];
      end
      Pp=permute(reshape(Pp',4,3,[]),[2,1,3]);

      X=H*[V(:,1),V(:,2),V(:,3)]';

      X(1,:)=X(1,:)+ti(1); X(2,:)=X(2,:)+ti(2);
    end
  case Inf
    if ~isProj
      % Tomasi Kanade with the metric constraint
      [X,Pp,disc,WFinal]=computeSMFromMultx(x,isProj,0);
      A=zeros(3*f,9);
      for i=1:f
        A(i,:)=kron(Pp(1,1:3,i),Pp(2,1:3,i));
        A(i+f,:)=kron(Pp(1,1:3,i),Pp(1,1:3,i));
        A(i+2*f,:)=kron(Pp(2,1:3,i),Pp(2,1:3,i));
      end
      B=[zeros(f,1); ones(2*f,1)];
      QQt=reshape(A\B,3,3); [Q,p]=chol(QQt);
      if p>0
        warning('Cannot impose the metric constraint'); return; %#ok<WNTAG>
      end
      Q=Q'; Q=Q*rotationMatrix(Pp(1:2,1:3)*Q)'; %Set the first matrix to Id
      PpR=reshape(permute(Pp(1:2,1:3,:),[2 1 3]),3,[])'; PpR=PpR*Q;
      for i=1:f
        temp=rotationMatrix(rotationMatrix(PpR(2*i-1:2*i,:)));
        Pp(1:2,1:3,i)=temp(1:2,:);
      end
      X=inv(Q)*X;
    end
end

% Compute the reprojection error
if nargout>=3
  PpTemp=reshape(permute(Pp(1:2,:,:),[2 1 3]),4,[])';
  temp=PpTemp*[X;ones(1,n)]; errReproj=norm(temp-WFinal,'fro');
end
