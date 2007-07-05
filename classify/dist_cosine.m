% Defines distance as 1-cosine of angle between two vectors [FAST].
%
% Let X be an m-by-p matrix representing m points in p-dimensional space
% and Y be an n-by-p matrix representing another set of points in the same
% space. This function computes the m-by-n distance matrix D where D(i,j)
% is the cosine of the angle between X(i,:) and Y(j,:). Running time
% is O(m*n*p). 
%
% USAGE
%  D = dist_cosine( X, Y )
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
%  D = dist_cosine( [X; Y], [X; Y] ); im(D)
%
% See also DIST_EUCLIDEAN

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 

function D = dist_cosine( X, Y )

if( ~isa(X,'double') || ~isa(Y,'double'))
  error( 'Inputs must be of type double'); end;

p=size(X,2);
XX = sqrt(sum(X.*X,2)); X = X ./ XX(:,ones(1,p));
YY = sqrt(sum(Y.*Y,2)); Y = Y ./ YY(:,ones(1,p));
D = 1 - X*Y';


%%%% LOOP METHOD - SLOW
% m = size(X,1); n = size(Y,1); 
% D = eye(m, n);
% for i = 1 : m
%   for j = i+1 : n
%     d1 = norm(X(i, :), 2);
%     d2 = norm(Y(j, :), 2);
%     D(i, j) = 1 - dot(X(i, :), Y(j, :))/(d1*d2);
%     D(j, i) = D(i, j);
%   end
% end
