% Calculates Earth Mover's Distance (EMD) between positive vectors.
%
% Assume X is an m-by-p matrix representing m histograms with p bins each
% and Y is an n-by-p matrix representing another set of n histograms with p
% bins each.  Each histogram is assumed to have the same total weight. This
% function compute the m-by-n distance matrix D where D(i,j) is the Earth
% Mover's Distance (EMD) between X(i,:) and Y(j,:).
%
% Note for 1D, with all histograms having equal weight, there is a simple
% closed form for the calculation of the EMD.  The EMD between two
% histograms x and y is simply given by the sum(abs(cdf(x)-cdf(y))), where
% cdf is the cumulative distribution function (computed simply by cumsum).
%
% USAGE
%  D = dist_emd( X, Y )
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
%  D = dist_emd( [X; Y], [X; Y] ); im(D)
%
% See also DIST_EUCLIDEAN, DIST_CHISQUARED

% Piotr's Image&Video Toolbox      Version 1.5
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!
 
function D = dist_emd( X, Y )

Xcdf = cumsum(X,2);
Ycdf = cumsum(Y,2);

m = size(X,1);  n = size(Y,1);
m_ones = ones(1,m); D = zeros(m,n);
for i=1:n
  ycdf = Ycdf(i,:);
  ycdf_rep = ycdf( m_ones, : );
  D(:,i) = sum(abs(Xcdf - ycdf_rep),2);
end





