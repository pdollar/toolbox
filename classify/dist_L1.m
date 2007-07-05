% Calculates the L1 Distance between vectors (ie the City-Block distance).
%
% Assume X is an m-by-p matrix representing m points in p-dimensional space
% and Y is an n-by-p matrix representing another set of points in the same
% space. This function compute the m-by-n distance matrix D where D(i,j) is
% the L1 distance between X(i,:) and Y(j,:).  
%
% The L1 distance between two vectors is defined as:
%  d(x,y) = sum( abs(xi-yi) );
%
% USAGE
%  D = dist_L1( X, Y )
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
%  D = dist_L1( [X; Y], [X; Y] ); im(D)
%
% See also DIST_EUCLIDEAN

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function D = dist_L1( X, Y )

m = size(X,1);  n = size(Y,1);
m_ones = ones(1,m); D = zeros(m,n); 
for i=1:n  
  yi = Y(i,:);  yi = yi( m_ones, : );
  D(:,i) = sum( abs( X-yi),2 );
end