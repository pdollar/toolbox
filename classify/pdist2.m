function D = pdist2( X, Y, metric )
% Calculates the distance between sets of vectors.
%
% Let X be an m-by-p matrix representing m points in p-dimensional space
% and Y be an n-by-p matrix representing another set of points in the same
% space. This function computes the m-by-n distance matrix D where D(i,j)
% is the distance between X(i,:) and Y(j,:).  This function has been
% optimized where possible, with most of the distance computations
% requiring few or no loops.
%
% The metric can be one of the following:
%
% 'euclidean' / 'sqeuclidean':
%   Euclidean / SQUARED Euclidean distance.  Note that 'sqeuclidean'
%   is significantly faster.
%
% 'chisq'
%   The chi-squared distance between two vectors is defined as:
%    d(x,y) = sum( (xi-yi)^2 / (xi+yi) ) / 2;
%   The chi-squared distance is useful when comparing histograms.
%
% 'cosine'
%   Distance is defined as the cosine of the angle between two vectors.
%
% 'emd'
%   Earth Mover's Distance (EMD) between positive vectors (histograms).
%   Note for 1D, with all histograms having equal weight, there is a simple
%   closed form for the calculation of the EMD.  The EMD between histograms
%   x and y is given by the sum(abs(cdf(x)-cdf(y))), where cdf is the
%   cumulative distribution function (computed simply by cumsum).
%
% 'L1'
%   The L1 distance between two vectors is defined as:  sum(abs(x-y));
%
%
% USAGE
%  D = pdist2( X, Y, [metric] )
%
% INPUTS
%  X        - [m x p] matrix of m p-dimensional vectors
%  Y        - [n x p] matrix of n p-dimensional vectors
%  metric   - ['sqeuclidean'], 'chisq', 'cosine', 'emd', 'euclidean', 'L1'
%
% OUTPUTS
%  D        - [m x n] distance matrix
%
% EXAMPLE
%  % simple example where points cluster well
%  [X,IDX] = demoGenData(100,0,5,4,10,2,0);
%  D = pdist2( X, X, 'sqeuclidean' );
%  distMatrixShow( D, IDX );
%  % comparison to pdist
%  n=500; d=200; r=100; X=rand(n,d);
%  tic, for i=1:r, D1 = pdist( X, 'euclidean' ); end, toc
%  tic, for i=1:r, D2 = pdist2( X, X, 'euclidean' ); end, toc
%  D1=squareform(D1); del=D1-D2; sum(abs(del(:)))
% 
% See also pdist, distMatrixShow
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.52
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 || isempty(metric) ); metric=0; end;

switch metric
  case {0,'sqeuclidean'}
    D = distEucSq( X, Y );
  case 'euclidean'
    D = sqrt(distEucSq( X, Y ));
  case 'L1'
    D = distL1( X, Y );
  case 'cosine'
    D = distCosine( X, Y );
  case 'emd'
    D = distEmd( X, Y );
  case 'chisq'
    D = distChiSq( X, Y );
  otherwise
    error(['pdist2 - unknown metric: ' metric]);
end
D = max(0,D);
end

function D = distL1( X, Y )
m = size(X,1);  n = size(Y,1);
mOnes = ones(1,m); D = zeros(m,n);
for i=1:n
  yi = Y(i,:);  yi = yi( mOnes, : );
  D(:,i) = sum( abs( X-yi),2 );
end
end

function D = distCosine( X, Y )
p=size(X,2);
XX = sqrt(sum(X.*X,2)); X = X ./ XX(:,ones(1,p));
YY = sqrt(sum(Y.*Y,2)); Y = Y ./ YY(:,ones(1,p));
D = 1 - X*Y';
end

function D = distEmd( X, Y )
Xcdf = cumsum(X,2);
Ycdf = cumsum(Y,2);
m = size(X,1);  n = size(Y,1);
mOnes = ones(1,m); D = zeros(m,n);
for i=1:n
  ycdf = Ycdf(i,:);
  ycdfRep = ycdf( mOnes, : );
  D(:,i) = sum(abs(Xcdf - ycdfRep),2);
end
end

function D = distChiSq( X, Y )
% note: supposedly it's possible to implement this without a loop!
m = size(X,1);  n = size(Y,1);
mOnes = ones(1,m); D = zeros(m,n);
for i=1:n
  yi = Y(i,:);  yiRep = yi( mOnes, : );
  s = yiRep + X;    d = yiRep - X;
  D(:,i) = sum( d.^2 ./ (s+eps), 2 );
end
D = D/2;
end

function D = distEucSq( X, Y )
Yt = Y';
XX = sum(X.*X,2);
YY = sum(Yt.*Yt,1);
D = bsxfun(@plus,XX,YY)-2*X*Yt;
end

%%%% code from Charles Elkan with variables renamed
% function D = distEucSq( X, Y )
% m = size(X,1); n = size(Y,1);
% D = sum(X.^2, 2) * ones(1,n) + ones(m,1) * sum(Y.^2, 2)' - 2.*X*Y';
% end

%%% LOOP METHOD - SLOW
% [m p] = size(X);
% [n p] = size(Y);
% D = zeros(m,n);
% onesM = ones(m,1);
% for i=1:n
%   y = Y(i,:);
%   d = X - y(onesM,:);
%   D(:,i) = sum( d.*d, 2 );
% end

%%% PARALLEL METHOD THAT IS SUPER SLOW (slower than loop)!
% % From "MATLAB array manipulation tips and tricks" by Peter J. Acklam
% Xb = permute(X, [1 3 2]);
% Yb = permute(Y, [3 1 2]);
% D = sum( (Xb(:,ones(1,n),:) - Yb(ones(1,m),:,:)).^2, 3);

%%% USELESS FOR EVEN VERY LARGE ARRAYS X=16000x1000!! and Y=100x1000
% call recursively to save memory
% if( (m+n)*p > 10^5 && (m>1 || n>1))
%   if( m>n )
%     X1 = X(1:floor(end/2),:);
%     X2 = X((floor(end/2)+1):end,:);
%     D1 = distEucSq( X1, Y );
%     D2 = distEucSq( X2, Y );
%     D = cat( 1, D1, D2 );
%   else
%     Y1 = Y(1:floor(end/2),:);
%     Y2 = Y((floor(end/2)+1):end,:);
%     D1 = distEucSq( X, Y1 );
%     D2 = distEucSq( X, Y2 );
%     D = cat( 2, D1, D2 );
%   end
%   return;
% end

%%% L1 COMPUTATION WITH LOOP OVER p, FAST FOR SMALL p.
% function D = distL1( X, Y )
%
% m = size(X,1); n = size(Y,1); p = size(X,2);
% mOnes = ones(1,m); nOnes = ones(1,n); D = zeros(m,n);
% for i=1:p
%   yi = Y(:,i);  yi = yi( :, mOnes );
%   xi = X(:,i);  xi = xi( :, nOnes );
%   D = D + abs( xi-yi' );
% end
