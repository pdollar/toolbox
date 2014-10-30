function ps = normpdf2( xs, m, C )
% Normal prob. density function (pdf) with arbitrary covariance matrix.
%
% Evaluate the multi-variate density with mean vector m and covariance
% matrix C for the input vector xs.  Assumes that the N datapoints are d
% dimensional.  Then m is dx1 or 1xd, C is dxd, and xs is dxN or NxD where
% N is the number of samples to be evaluated.
%
% USAGE
%  ps = normpdf2( xs, m, C )
%
% INPUTS
%  xs  - points to evaluated (Nxd or dxN)
%  m   - mean vector (dx1 or 1xd)
%  C   - Covariance matrix (dxd)
%
% OUTPUTS
%  ps  - probability density at each x (Nx1)
%
% EXAMPLE
%  ps = normpdf2( randn(10,2), [0 0], eye(2) )
%
% See also NORMPDF
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.30
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get dimensions of data
d=length(m);
if( size(xs,1)~=d ); xs=xs'; end
N=size(xs,2);

if( d==1 ) % fast special case
  ps = 1/sqrt(2*pi*C) * exp(-(xs-m).*(xs-m)/(2*C))';
  
elseif( rcond(C)<eps ) % if matrix is badly conditioned
  warning('normpdf2: Covariance matrix close to singular.'); %#ok<WNTAG>
  ps = zeros(N,1);
  
else % get probabilities
  xs = (xs-m(:)*ones(1,N))';
  denom = (2*pi)^(d/2)*sqrt(abs(det(C)));
  mahal = sum( (xs/C).*xs, 2 );
  numer = exp(-0.5*mahal);
  ps = numer/denom;
end
