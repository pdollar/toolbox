function [X0,H0,X1,H1] = demoGenData1(n0,n1,k,d,sep,ecc,frc)
% Generate data drawn form a mixture of Gaussians.
%
% For definitions of separation and eccentricity see:
%  Sanjoy Dasgupta, "Learning Mixtures of Gaussians", FOCS, 1999.
%  http://cseweb.ucsd.edu/~dasgupta/papers/mog.pdf
%
% USAGE
%  [X0,H0,X1,H1] = demoGenData(n0,n1,k,d,sep,ecc,[frc])
%
% INPUTS
%  n0     - size of training set
%  n1     - size of testing set
%  k      - number of mixture components
%  d      - data dimension
%  sep    - separation degree (sep > 0)
%  ecc    - maximum eccentricity (0 < ecc < 1)
%  frc    - [0] frac of points that are noise (uniformly distributed)
%
% OUTPUTS
%  X0     - [n0xd] training set data vectors
%  H0     - [n0x1] cluster membership in [1,k] (and -1 for noise)
%  X1     - [n1xd] testing set data vectors
%  H1     - [n1x1] cluster membership in [1,k] (and -1 for noise)
%
% EXAMPLE
%  n0=1000; k=5; d=2; sep=2; ecc=1; frc=0;
%  [X0,H0,X1,H1] = demoGenData(n0,n0,k,d,sep,ecc,frc);
%  figure(1); clf; visualizeData( X0, 2, H0 ); title('train');
%  figure(2); clf; visualizeData( X1, 2, H1 ); title('test');
%
% See also visualizeData, demoCluster
%
% Piotr's Image&Video Toolbox      Version NEW
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% generate mixing weights
W=0; while(any(W<=1/(4*k))), W=rand(k,1); W=W/sum(W); end

% adjust n0 and n1 for noise fraction
if( nargin<7 ), frc=0; end; frc=max(0,min(frc,1));
if(frc), nn0=floor(frc*n0); nn1=floor(frc*n1); n0=n0-nn0; n1=n1-nn1; end

% create sep-separated Gaussian clusters of maximum eccentricity ecc
trial = 1;
while( 1 )
  lam = ones(k,1)/1000;
  k0=sum(ceil(W*n0)); X0=zeros(k0,d); H0=zeros(k0,1); k0=0;
  k1=sum(ceil(W*n1)); X1=zeros(k1,d); H1=zeros(k1,1); k1=0;
  mu = randn(k,d)*sqrt(k)*sqrt(sep)*trial/10;
  for j = 1:k
    % generate a random covariance matrix S=C'*C
    U=rand(d,d)-0.5; U=sqrtm(inv(U*U'))*U;
    L=diag(rand(d,1)*(ecc-1)+1).^2/100; C=chol(U*L*U');
    % populate X0, H0
    nj=ceil(n0*W(j));
    X0j=randn(nj,d)*C + repmat(mu(j,:),nj,1);
    H0(k0+1:k0+nj)=j; X0(k0+1:k0+nj,:)=X0j; k0=k0+nj;
    if(nj>1), lam(j) = sqrt(trace(cov(X0j))); end
    % populate X1, H1
    mj=ceil(n1*W(j));
    X1j=randn(mj,d)*C + repmat(mu(j,:),mj,1);
    H1(k1+1:k1+mj)=j; X1(k1+1:k1+mj,:)=X1j; k1=k1+mj;
  end
  
  % check that degree of separation is sufficient (see Dasgupta 99)
  % use "lam=sqrt(trace(S))" instead of "lam=sqrt(eigs(S,1))*d"
  S = pdist2(mu,mu,'euclidean'); S(eye(k)>0)=inf;
  for i=1:k, for j=1:k, S(i,j)=S(i,j)/max(lam(i),lam(j)); end; end
  if(all(S(:)>=sep)), break; end; trial=trial+1; assert(trial<1000);
end

% generate uniformly distributed noise
if( frc~=0 )
  v=max(abs(X0(:))); if(n1), v=max(v,max(abs(X1(:)))); end
  % populate X0, H0
  X0j=(rand(nn0,d)-.5)*v*2.5; k0=length(H0);
  H0(k0+1:k0+nn0)=-1; X0(k0+1:k0+nn0,:)=X0j;
  k0=k0+nn0; p=randperm(k0); X0=X0(p,:); H0=H0(p);
  % populate X1, H1
  X1j=(rand(nn1,d)-.5)*v*2.5; k1=length(H1);
  H1(k1+1:k1+nn1)=-1; X1(k1+1:k1+nn1,:)=X1j;
  k1=k1+nn1; p=randperm(k1); X1=X1(p,:); H1=H1(p);
end

end
