% Calculates the Chi Squared Distance between vectors (usually histograms).
%
% Assume X is an m-by-p matrix representing m points in p-dimensional space
% and Y is an n-by-p matrix representing another set of points in the same
% space. This function compute the m-by-n distance matrix D where D(i,j) is
% the chi-squared distance between X(i,:) and Y(j,:).  
%
% The chi-squared distance between two vectors is defined as:
%   d(x,y) = sum( (xi-yi)^2 / (xi+yi) ) / 2;
% The chi-squared distance is useful when comparing histograms.
%
% USAGE
%  D = dist_chisquared( X, Y )
%
% INPUTS
%  X   - [m x p] matrix of m p-dimensional vectors 
%  Y   - [n x p] matrix of n p-dimensional vectors 
%
% OUTPUTS
%  D   - [m x n] distance matrix
%
% EXAMPLE
%  X = [randn(100,5)]; Y=randn(40,5)+2;
%  D = dist_chisquared( abs([X; Y]), abs([X; Y]) ); im(D)
%
% See also DIST_EUCLIDEAN, DIST_EMD

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function D = dist_chisquared( X, Y )

%%% supposedly it's possible to implement dist_chisquared without a loop!

m = size(X,1);  n = size(Y,1);
m_ones = ones(1,m); D = zeros(m,n); 
for i=1:n  
  yi = Y(i,:);  yi_rep = yi( m_ones, : );
  s = yi_rep + X;    d = yi_rep - X;
  D(:,i) = sum( d.^2 ./ (s+eps), 2 );
end
D = D/2;