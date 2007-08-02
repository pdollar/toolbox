% x is 2xNxT or 3xNxT

function [X,Pp,WFinal,errReproj]=computeSMFromMultx(x,isProj,method)

if nargin<4; method=0; end
f=size(x,3); n=size(x,2); 

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
      Pp(4:3:end,1:3)=M(3:2:end,:); Pp(5:3:end,1:3)=M(4:2:end,:);
      Pp(3:3:end,4)=1;
      for i=1:f
        Pp(2*i-1:2*i,4)=ti(2*i-1:2*i)-M(2*i-1:2*i,:)*[ti(1:2);0];
      end
      Pp=permute(reshape(Pp',4,3,[]),[2,1,3]);

      X=H*[V(:,1),V(:,2),V(:,3)]';

      X(1,:)=X(1,:)+ti(1); X(2,:)=X(2,:)+ti(2); X(4,:)=1;
    end
  case Inf
    if ~isProj
      % Tomasi Kanade with the metric constraint
      [X,Pp,WFinal]=computeSMFromMultx(x,isProj,0);
      A=cell(1,3*f); rowR=floor(1:1.5:3*f);
      for i=1:f; A{i}=sparse(kron(Pp(3*i-2,1:3),Pp(3*i-1,1:3))); end
      j=f; for i=rowR; j=j+1; A{j}=sparse(kron(Pp(i,1:3),Pp(i,1:3))); end
      B=ones(3*f,1); B(1:f)=0;
      QQt=reshape(blkdiag(A{:})\B,3,3);
      [Q,p]=chol(QQt);
      if p>0
        warning('Cannot impose the metric constraint'); return; %#ok<WNTAG>
      end
      Q=Q'; Q=Q*rotatioMatrix(Pp(1:2,1:3)*Q)'; %Set the first matrix to Id
      Pp(rowR,1:3)=Pp(rowR,1:3)*Q; X(1:3,:)=inv(Q)*X(1:3,:);
    end
end

% Compute the reprojection error
if nargout>=3
  PpTemp=reshape(permute(Pp(1:2,:,:),[2 1 3]),4,[])';
  temp=PpTemp*X; errReproj=norm(temp-WFinal,'fro');
end
