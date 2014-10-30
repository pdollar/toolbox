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
%  sep    - minimum separation degree between clusters (sep > 0)
%  ecc    - maximum eccentricity of clusters (0 < ecc < 1)
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
% Piotr's Computer Vision Matlab Toolbox      Version 3.20
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% generate mixing weights and adjust n0 and n1 for noise fraction
w=0; while(any(w<=1/(4*k))), w=rand(k,1); w=w/sum(w); end
if( nargin<7 ), frc=0; end; frc=max(0,min(frc,1));
n=floor(frc*n0); n0=n0-n; ns0=[ceil(n0*w); n];
n=floor(frc*n1); n1=n1-n; ns1=[ceil(n1*w); n];

% create sep-separated Gaussian clusters of maximum eccentricity ecc
for trial=1:1000
  lam = ones(k,1)/1000;
  n0=sum(ns0); X0=zeros(n0,d); H0=zeros(n0,1); n0=0;
  n1=sum(ns1); X1=zeros(n1,d); H1=zeros(n1,1); n1=0;
  mu = randn(k,d)*sqrt(k)*sqrt(sep)*trial/10;
  for i = 1:k
    % generate a random covariance matrix S=C'*C
    U=rand(d,d)-0.5; U=sqrtm(inv(U*U'))*U;
    L=diag(rand(d,1)*(ecc-1)+1).^2/100; C=chol(U*L*U');
    % populate X0, H0
    n=ns0(i); X0j=randn(n,d)*C + mu(ones(n,1)*i,:);
    H0(n0+1:n0+n)=i; X0(n0+1:n0+n,:)=X0j; n0=n0+n;
    if(n>1), lam(i) = sqrt(trace(cov(X0j))); end
    % populate X1, H1
    n=ns1(i); X1j=randn(n,d)*C + mu(ones(n,1)*i,:);
    H1(n1+1:n1+n)=i; X1(n1+1:n1+n,:)=X1j; n1=n1+n;
  end
  % check that degree of separation is sufficient (see Dasgupta 99)
  % use "lam=sqrt(trace(S))" instead of "lam=sqrt(eigs(S,1))*d"
  S = pdist2(mu,mu,'euclidean'); S(eye(k)>0)=inf;
  for i=1:k, for j=1:k, S(i,j)=S(i,j)/max(lam(i),lam(j)); end; end
  if(all(S(:)>=sep)), break; end
end; assert(trial<1000);

% add uniformly distributed noise and permute order
if( frc>0 )
  v=max(abs(X0(:))); if(n1), v=max(v,max(abs(X1(:)))); end
  % populate X0, H0
  n=ns0(k+1); X0j=(rand(n,d)-.5)*v*2.5;
  H0(n0+1:n0+n)=-1; X0(n0+1:n0+n,:)=X0j;
  n0=n0+n; p=randperm(n0); X0=X0(p,:); H0=H0(p);
  % populate X1, H1
  n=ns1(k+1); X1j=(rand(n,d)-.5)*v*2.5;
  H1(n1+1:n1+n)=-1; X1(n1+1:n1+n,:)=X1j;
  n1=n1+n; p=randperm(n1); X1=X1(p,:); H1=H1(p);
end

end
