function [X,Pp]=computeSMFromx(x,xp,method,isProj)

if nargin<3; method=0; end
if any(size(x)~=size(xp)); error('x1 and x2 have different size'); end
if size(x,1)>3; x=x'; xp=xp'; end
if size(x,1)==2; x(3,:)=1; xp(3,:)=1; end

n=size(x,2);

switch method
  case 0
    if isProj
      % Normalized 8-point algorithm
      % Reference: HZ2, p279

      % Normalize input data
      [x T]=normalizex(x);
      [xp Tp]=normalizex(xp);

      A=[repmat(xp(1,:),[2,1]).*x(1:2,:); xp(1,:); ...
        repmat(xp(2,:),[2,1]).*x(1:2,:); xp(2,:); x ]';

      [U,S,V]=svd(A,0); F=reshape(V(:,end),[3,3])';
      [U,S,V]=svd(F,0); F=U*diag([S(1,1) S(2,2) 0])*V';

      F=Tp'*F*T;
    else
      % Linear Algorithm
      % Reference: HZ2, p348

      % Not implemented because there is no point :) The Gold Standard is as fast
    end

    Pp = computePfromF(F);
    X=computeXfromxP(x,xp,eye(3,4),Pp);
  case Inf
    % Gold Standard algorithm
    if isProj
      % Reference: HZ2, p285, Algorithm 11.3
      % Reference: HZ2, p609, Sparse LM

      F=computeFfromx(x,xp,0,isProj);

      caseCons = 'none';

      % Initialize some variables
      lambda = 0.001;

      P = eye(3,4);
      Pp = computePfromF(F);
      % Impose the constraint on PP{2}
      switch caseCons
        case 'rot'
          for j = 1 : 3
            for i = 1 : 3
              if abs( Pp( j, i ) )>1
                Pp( j, i ) = sign( Pp( j, i ) );
              end
            end
          end
      end
      % Create P
      warning off all;
      X=computeXfromxP(x,xp,P,Pp);

      % Initialize Pb, Pb stands for P bold
      Pb = zeros( 1, 12 + 3*n );
      temp = Pp';
      Pb( 1 : 12 ) = temp(1:12);

      for i = [ 1 2 4 ]; X( i, : ) = X( i, : )./X( 3, : ); end; X( 3, : ) = 1;
      Pb( 13 : end ) = reshape( X( [1 2 4], : ), 3*n, 1 )';

      % Initialize XHat
      errMin = computeError( x, xp, Pb );

      XDiff = XDiffNew;
      X3D = X3DNew;

      %Initial definition of the derivative matrices
      A = zeros( 4, 12, n );	% The first 2 rows are zeros (no P' is in there, as it is multiplied by [I|0]
      B = zeros( 4, 3, n );
      B( 1, 1, : ) = 1; B( 2, 2, : ) = 1;
      
      Hi = zeros( 3, n );
      Gi = zeros( 3, 12, n );
      Wi=zeros(12,3,n);

      % compute the Sigma_xi
      j = 0;nIter=100;
      while j<nIter
        %XHati = [ [[I|0],P']'bi], every 1 and 2 row is divided by the 3 and the 3 is removed too, is 4*1
        % Compute Ai=dxHat_i/da, Ai is 4*12 and Bi=dxHat_i/db_i, Bi is 4*3

        % Define the Ai
        PpXtRep=cell(1,3);
        PpXtRep{3}=repmat( 1./(Pp(3,:)*X3D), [ 4, 1 ] );
        Xt = X3D.*PpXtRep{3};

        for i=1:2
          PpXtRep{i}=repmat( Pp(i,:)*Xt, [ 4, 1 ] );
        end

        A( 3, 1:4, : ) = reshape( Xt, [ 1, 4, n ] );
        A( 4, 5:8, : ) = A( 3, 1:4, : );
        A( 3, 9:12, : ) = reshape( -PpXtRep{1}.*Xt, [ 1, 4, n ] );
        A( 4, 9:12, : ) = reshape( -PpXtRep{2}.*Xt, [ 1, 4, n ] );

        % Define the Bi
        Pp( :, 3 ) = []; for i=1:3 PpXtRep{i}(4,:)=[]; end
        B( 3, :, : ) = reshape( PpXtRep{3}.*(repmat(Pp(1,:)',[ 1 n ]) - ...
          PpXtRep{1}.*repmat( Pp( 3, : )', [ 1 n ] ) ), [ 1 3 n ] );
        B( 4, :, : ) = reshape( PpXtRep{3}.*(repmat(Pp(2,:)',[ 1 n ]) - ...
          PpXtRep{2}.*repmat( Pp( 3, : )', [ 1 n ] ) ), [ 1 3 n ] );

        % Compute some values independent from delta
        U = zeros( 12 );
        DeltaLeft = zeros( 12 );
        DeltaRight = zeros( 12, 1 );
        for i = 1 : n
          Ai = A( :, :, i );
          Aip = Ai';
          Bi = B( :, :, i );

          % Compute Ui, Ui is 12*12
          U = U + Aip*Ai; %Ai'*sigmaInvi*Ai.*UiStarFactor;

          % Compute Wi, Wi is 12*3
          Wi(:,:,i) = Aip*Bi;%Ai'*sigmaInvi*Bi;
        end
        
        % Perform the sparse computation
        while j<nIter
          for i = 1 : n
            Ai = A( :, :, i );
            Bi = B( :, :, i );
            Bip = Bi';
            
            % Compute Vi, Vi is 3*3
            ViStar = Bip*Bi;%Bi'*sigmaInvi*Bi.*ViStarFactor;
            for k = 1 : 3
              ViStar( k, k ) = ViStar( k, k )*( 1 + lambda );
            end

            % Use different temp variables
            Fi = inv(ViStar)*Bip;
            Gi(:,:,i) = Fi*Ai;
            Hi(:,i) = Fi*XDiff( :, i );

            % Compute the left of the equation in deltaA, it is 12*12
            DeltaLeft = DeltaLeft + Wi(:,:,i)*Gi(:,:,i);

            % Compute the right of the equation in deltaA, it is 12*1
            DeltaRight = DeltaRight + Aip*XDiff( :, i )- Wi(:,:,i)*Hi(:,i);
          end
          % Compute deltaA and update P
          UStar=U;
          for k = 1 : 12; UStar(k,k) = U(k,k)*( 1 + lambda ); end

          deltaA = (UStar-DeltaLeft)\DeltaRight;
          PbNew = Pb;
          PbNew( 1 : 12 ) = PbNew( 1 : 12 ) + deltaA';
          switch caseCons
            case 'rot'
              temp = find( abs( PbNew( 1 : nParam ) )>1 );
              temp( ismember( temp, [ 4, 8 ,12 ] ) ) = [];
              PbNew( temp ) = sign( PbNew( temp ) );
          end

          % Compute each deltaBi and update P
          PbNew( 13 : end ) = PbNew( 13 : end ) + Hi(:)';
          for i = 1 : n
            PbNew(3*i+(10:12)) = PbNew(3*i+(10:12))-(Gi(:,:,i)*deltaA)';
          end

          % Compute the new error
          err = computeError( x,xp,PbNew);
          
          % Update lambda
          j = j + 1;
          if err<errMin
            Pb = PbNew;
            lambda = lambda/10;
            errMin = err;
            XDiff = XDiffNew;
            X3D = X3DNew;
            break;
          else
            lambda = lambda*10;
          end
        end
      end
      
      Pp = reshape( Pb( 1 : 12 ), [ 4, 3 ] )';
      X = X3D./repmat( X3D( 4, : ), [ 4, 1 ] );
    else
      % Affine camera matrix
      % Reference: HZ2, p351, Algorithm 14.1

      A=[ xp(1:2,:)./repmat(xp(3,:),[2,1]); x(1:2,:)./repmat(x(3,:),[2,1]) ]';
      Xbar=mean(A,1);
      A=A-repmat(Xbar,[ n 1 ]);

      [U,S,V]=svd(A);

      F=zeros(3,3); F(1,1)=V(1,end); F(2,1)=V(2,end); F(3,1)=V(3,end);
      F(3,2)=V(4,end); F(3,3)=-V(:,4)'*Xbar';

      Pp = computePfromF(F);
      X=computeXfromxP(x,xp,eye(3,4),Pp);
    end
end


%%%%%%%%%%%
% Compute the reconstruction error for each point
  function err = computeError( x, xp, Pb )

    if isProj
      Pp = reshape( Pb( 1 : 12 ), [ 4, 3 ] )'; nParam=12;
    else
      Pp = [ Pb( 1 : 4 ); Pb( 5 : 8 ); 0, 0, 0, 1 ]; nParam=8;
    end

    X3DNew = [ Pb( nParam+1 : 3 : end ); Pb( nParam+2 : 3 : end ); ...
      ones( 1, size(x,2) ); Pb( nParam+3 : 3 : end ) ];

    xpHatNew = Pp*X3DNew;
    xpHatNew( 1:2, : )= xpHatNew( 1:2, : )./repmat(xpHatNew( 3, : ),[2 1]);

    if isProj
      XHatNew = [ X3DNew(1:2,:); xpHatNew(1:2,:) ];
    else
      XHatNew = [ X3DNew(1,:)./X3DNew(4,:); X3DNew(2,:)./X3DNew(4,:); ...
        xpHatNew(1:2,:) ];
    end

    XDiffNew=[x(1:2,:);xp(1:2,:)]-XHatNew;
    err = norm( XDiffNew, 'fro' );
  end
end
