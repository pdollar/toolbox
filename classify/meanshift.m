% meanshift clustering algorithm.
%
% Based on code from Sameer Agarwal <sagarwal-at-cs.ucsd.edu>
%
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
% may require an increase in maxiter.  Increase maxiter until convergence
% occurs regularly for a given data set (versus the algorithm being cut off
% at maxiter).  
%
% Note the cluster means M do not refer to the actual mean of the points
% that belong to the same cluster, but rather the values to which the 
% meanshift algorithm converged for each given point (recall that cluster
% membership is based on the mean converging to the same value from
% different points).  Hence M is not the same as C, the centroid of the
% points [see kmeans2 for a definition of C].
%
% INPUTS
%   X           - column vector of data - N vectors of dimension p (X is Nxp)
%   radius      - the bandwidth (radius of the window)
%   rate        - [optional] gradient descent proportionality factor in (0,1]
%   maxiter     - [optional] maximum number of iterations
%   minCsize    - [optional] min size for a cluster (smaller clusters get eliminated)
%   blur        - [optional] if (blur==1) then at each iteration data is blurred 
%                 by the mean vector (the original data points move) - can
%                 cause 'incorrect' results
%
% OUTPUTS
%   IDX         - cluster membership [see kmeans2.m]
%   M           - cluster means [see above]
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MEANSHIFTIM, DEMOCLUSTER

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [IDX,M] = meanshift(X, radius, rate, maxiter, minCsize, blur )
    if( nargin<3 ) rate =.2; end;
    if( nargin<4 ) maxiter =100; end;
    if( nargin<5 ) minCsize = 1; end;
    if( nargin<6 ) blur =0; end;    
    if( rate<=0 || rate>1 ) error('rate must be between 0 and 1'); end;
    
    %%% OLD VERSION OF rate (gradient descent proportionality factor)
    %%% rate = rate * (size(X,2) + 2) / radius^2;

    % c code does the work 
    % requires X transposed (meanshift1 uses a different convention)
    [IDX,meansfinal] = meanshift1(X',radius,rate,maxiter,blur);
    meansfinal = meansfinal';  
    
    % calculate final cluster means per cluster
    [N,p] = size(X);  k = max(IDX);
    M = zeros(k,p); for i=1:k M(i,:) = mean( meansfinal(IDX==i,:), 1 ); end;

    % sort clusters [largest first] and remove all smaller then minCsize
    ccounts = zeros(1,k); for i=1:k ccounts(i) = sum( IDX==i ); end
    [ccounts,order] = sort( -ccounts ); ccounts = -ccounts; M = M(order,:);  
    IDX2 = IDX;  for i=1:k IDX2(IDX==order(i))=i; end; IDX = IDX2; 
    [v,loc] = min( ccounts>=minCsize ); 
    if( v==0 ) M( loc:end, : ) = []; IDX( IDX>=loc ) = -1; k = max(IDX); end;
    
