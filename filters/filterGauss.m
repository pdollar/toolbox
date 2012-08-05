function G = filterGauss( dims, mu, C, show )
% n-dimensional Gaussian filter.
%
% Creates an image of a Gaussian with arbitrary covariance matrix. The
% dimensionality and size of the filter is determined by dims (eg dims=[10
% 10] creates a 2D filter of size 10x10). If mu==[], it is calculated to be
% the center of the n-dim image.  C can be a full nxn covariance matrix, or
% an nx1 vector of variance.  In the latter case C is calculated as
% C=diag(C). If C=[]; then C=(dims/6).^2, ie it is transformed into a
% vector of variances such that along each dimension the variance is equal
% to (siz/6)^2.
%
% USAGE
%  G = filterGauss( dims, [mu], [C], [show] )
%
% INPUTS
%  dims    - n element vector of dimensions of final Gaussian
%  mu      - [] n element vector specifying the mean
%  C       - [] nxn cov matrix, nx1 set of vars, or variance
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  G       - image of the created Gaussian
%
% EXAMPLE
%  g = filterGauss( 21, [], 4, 1); %1D
%  sig=3; G = filterGauss( 4*[sig sig] + 1, [], [sig sig].^2, 2 ); %2D
%  R = rotationMatrix( [1,1,0], pi/4 );
%  C = R'*[10^2 0 0; 0 5^2 0; 0 0 16^2]*R;
%  G3 = filterGauss( [51,51,51], [], C, 3 ); %3D
%
% See also NORMPDF2
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

nd = length( dims );
if( nargin<2 || isempty(mu)); mu=(dims+1)/2; end
if( nargin<3 || isempty(C)); C=(dims/6).^2; end
if( nargin<4 || isempty(show) ); show=0; end

if( length(mu)~=nd ); error('invalid mu'); end

if( nd==1 ) % fast special case
  xs = 1:dims(1);
  G = exp(-(xs-mu).*(xs-mu)/(2*C))';

else
  % make C have correct dimensions
  if( numel(C)==1 ); C=repmat(C,[1 nd]); end
  if( size(C,1)==1 || size(C,2)==1 ); C=diag(C); end
  if( any(size(C)~=nd)); error( 'invalid C'); end

  % get vector of grid locations
  temp = cell(1,nd);
  for d=1:nd; temp{d} = 1:dims(d); end
  [ temp{:}] = ndgrid( temp{:} );
  xs = zeros( nd, prod(dims) );
  for d=1:nd; xs( d, : ) = temp{d}(:)'; end

  % evaluate the Gaussian at those points
  G = normpdf2( xs, mu, C );
  if( nd>1 ); G = reshape( G, dims ); end
end

% suppress very small values and normalize
G(G<eps*max(G(:))*10) = 0;
G = G/sum(G(:));

% display
if( show );
  if( nd==3 )
    filterVisualize( G, show, .2 );
  else
    filterVisualize( G, show );
  end
end
