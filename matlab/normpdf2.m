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
%  ps = normpdf2( randn(10,1), 0, 1 )
%
% See also NORMPDF

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!
 
function ps = normpdf2( xs, m, C )

% get dimensions of data
d=length(m);
if( size(xs,1)~=d ); xs=xs'; end
N=size(xs,2);

if( rcond(C)<eps )
  % if matrix is badly conditioned
  warning('normpdf2: Covariance matrix close to singular.'); %#ok<WNTAG>
  ps = zeros(N,1);

else
  % get probabilities
  m=m(:);
  M=m*ones(1,N);
  detC = det(C);
  denom=(2*pi)^(d/2)*sqrt(abs(detC));
  mahal=sum(((xs-M)'*inv(C)).*(xs-M)',2);   % Chris Bregler's trick
  numer=exp(-0.5*mahal);
  ps = numer/denom;
end

