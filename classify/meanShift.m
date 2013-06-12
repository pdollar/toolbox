function [IDX,M] = meanShift(X, radius, rate, maxIter, minCsize, blur )
% meanShift clustering algorithm.
%
% Based on code from Sameer Agarwal <sagarwal-at-cs.ucsd.edu>.
% For a broad discussion see:
% Y. Cheng, Mean-shift, mode seeking, and clustering, IEEE Transactions on
% Pattern Analysis and Machine Intelligence, Vol.17, 1995, pp. 790-799
%
% The radius or bandwidth is tied to the 'width' of the distribution and is
% data dependent.  Note that the data should be normalized first so that
% all the dimensions have the same bandwidth.  The rate determines how
% large the gradient decent steps are.  The smaller the rate, the more
% iterations are needed for convergence, but the more likely minima are not
% overshot.  A reasonable value for the rate is .2.  Low value of the rate
% may require an increase in maxIter.  Increase maxIter until convergence
% occurs regularly for a given data set (versus the algorithm being cut off
% at maxIter).
%
% Note the cluster means M do not refer to the actual mean of the points
% that belong to the same cluster, but rather the values to which the
% meanShift algorithm converged for each given point (recall that cluster
% membership is based on the mean converging to the same value from
% different points).  Hence M is not the same as C, the centroid of the
% points [see kmeans2 for a definition of C].
%
% USAGE
%  [IDX,M] = meanShift(X, radius, [rate], [maxIter], [minCsize], [blur] )
%
% INPUTS
%  X           - column vector of data - N vectors of dim p (X is Nxp)
%  radius      - the bandwidth (radius of the window)
%  rate        - [] gradient descent proportionality factor in (0,1]
%  maxIter     - [] maximum number of iterations
%  minCsize    - [] min cluster size (smaller clusters get eliminated)
%  blur        - [] if blur then at each iter data is 'blurred', ie the
%                original data points move (can cause 'incorrect' results)
%
% OUTPUTS
%  IDX         - cluster membership [see kmeans2.m]
%  M           - cluster means [see above]
%
% EXAMPLE
%
% See also MEANSHIFTIM, DEMOCLUSTER
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<3 ); rate =.2; end
if( nargin<4 ); maxIter =100; end
if( nargin<5 ); minCsize = 1; end
if( nargin<6 ); blur =0; end
if( rate<=0 || rate>1 ); error('rate must be between 0 and 1'); end

% OLD VERSION OF rate (gradient descent proportionality factor)
% rate = rate * (size(X,2) + 2) / radius^2;

% c code does the work  (meanShift1 requires X')
[IDX,meansFinal] = meanShift1(X',radius,rate,maxIter,blur);
meansFinal = meansFinal';

% calculate final cluster means per cluster
p = size(X,2);  k = max(IDX);
M = zeros(k,p); for i=1:k; M(i,:) = mean( meansFinal(IDX==i,:), 1 ); end

% sort clusters [largest first] and remove all smaller then minCsize
ccounts = zeros(1,k); for i=1:k; ccounts(i) = sum( IDX==i ); end
[ccounts,order] = sort( -ccounts ); ccounts = -ccounts; M = M(order,:);
IDX2 = IDX;  for i=1:k; IDX2(IDX==order(i))=i; end; IDX = IDX2;
[v,loc] = min( ccounts>=minCsize );
if( v==0 ); M( loc:end, : ) = []; IDX( IDX>=loc ) = -1; end
