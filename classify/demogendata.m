% Generate data drawn form a mixture of Gaussians.
%
% Adapted from code by [Nikos Vlassis, 2000].
% For definitions see [Dasgupta, 1999].
%
% INPUTS
%   n - size of training set 
%   m - size of test set 
%   k - number of components
%   d - dimension
%   c - separation degree
%   e - maximum eccentricity
%   f - [optional] fraction of points that are noise (uniformly distributed)
%
% OUTPUTS
%   X    - training set (n x d)
%   IDX  - cluster membership [see kmeans2.m]
%   T    - test set (m x d) 
%   IDT  - cluster membership [see kmeans2.m]
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also VISUALIZE_DATA, DEMOCLUSTER, DEMOCLASSIFY

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [X,IDX,T,IDT] = demogendata(n,m,k,d,c,e,f)

    if( nargin<7 ) f=0; end;
    if (f<0 || f>=1 ) 
        error('illegal value for f');
    end


    % mixing weights
    while 1
      W = rand(k,1); 
      W = W / sum(W);
      if all(W > 1/(4*k)) 
        break;
      end
    end

    % adjust n and m for noise frac
    if( nargin>=7 && f~=0)
        nnoise = floor( f * n );
        mnoise = floor( f * m );
        n = n - nnoise;  m = m - mnoise;
    end

    % create c-separated Gaussian clusters of maximum eccentricity e
    R=zeros(k,d^2);
    trials = 1;
    while 1
      IDX = [];
      IDT = [];
      X = [];
      T = [];
      M = randn(k,d)*sqrt(k)*sqrt(c)*trials/10;
      Trace = zeros(k,1);
      for j = 1:k
        U = rand(d,d)-0.5; 
        U = sqrtm(inv(U*U')) * U;
        L = diag(rand(d,1)*(e-1)+1).^2/100;
        msg = 1;
        while msg
          [C,msg] = chol(U*L*U');
        end
        R(j,:)=C(:)';

        nj = ceil(n*W(j));
        Xj = randn(nj,d) * C;
        IDX = [IDX j(ones(1,nj))];
        X = [X; repmat(M(j,:),nj,1) + Xj];
        Trace(j) = trace(cov(Xj));


        mj = ceil(m*W(j));
        Tj = randn(mj,d) * C;
        IDT = [IDT j(ones(1,mj))];    
        T = [T; repmat(M(j,:),mj,1) + Tj];

      end


      % check degree of separation
      er = 0;
      for i = 1:k-1
        for j = i+1:k
          if norm(M(i,:)-M(j,:)) < c * sqrt(max(Trace(i),Trace(j)))
            er = 1;
          end
        end
      end
      if ~er
        break;
      end
      trials = trials + 1;
    end

    % make some uniformly distributed noise
    if( f~=0)
        if (m>0) 
            maxv=max( max(abs(X(:))), max(abs(T(:))) ); 
        else 
            maxv=max(abs(X(:))); 
        end;

        Xnoise = (rand( nnoise, d ) - .5) * maxv * 2.5;
        IDXnoise = -1;  IDXnoise = IDXnoise( ones(1,nnoise ) );
        X = [X; Xnoise]; IDX = [IDX IDXnoise];
        p = randperm( length(IDX) );  X = X(p,:); IDX = IDX(p);

        if( m>0 )
            Tnoise = (rand( mnoise, d ) - .5) * maxv * 2.5;
            IDTnoise = -1;  IDTnoise = IDTnoise( ones(1,mnoise ) );
            T = [T; Tnoise]; IDT = [IDT IDTnoise];
            p = randperm( length(IDT) );  T = T(p,:); IDT = IDT(p);
        end
    end

    % put into standard form (column format)
    IDX = IDX'; IDT = IDT';
