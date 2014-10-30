function m = medianw( x, w, dim )
% Fast weighted median.
%
% Computes the weighted median of a set of samples.
%  http://en.wikipedia.org/wiki/Weighted_median
% "A weighted median of a sample is the 50% weighted percentile."
% For matrices computes median along each column (or dimension dim).
% If all weights are equal to 1 gives identical results to median.
%
% USAGE
%  m = medianw( x, w, [dim] )
%
% INPUTS
%  x      - vector or array of samples
%  w      - vector or array of weights
%  dim    - dimension along which to compute median
%
% OUTPUTS
%  m      - weighted median value of x
%
% EXAMPLE - simple toy example
%  x=[1 2 3]; w=[1 1 5]; medianw(x,w)
%
% EXAMPLE - comparison to median
%  n=randi(100); m=randi(100);
%  x=rand(n,m); w=ones(n,m);
%  m1=median(x); m2=medianw(x,w);
%  assert(isequal(m1,m2))
%
% See also median
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.24
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(nargin<3), dim=find(size(x)~=1,1); end
d=dim; nd=ndims(x); n=numel(x);

if( n==1 || size(x,d)==1 )
  m=x;
elseif( length(x)==n )
  [x,o]=sort(x); w=w(o); w=cumsum(w);
  w=w/w(end); [~,j]=min(w<=.5);
  if(j==1 || w(j-1)~=.5), m=x(j);
  else m=(x(j-1)+x(j))/2; end
else
  if(d>1), p=[d 1:d-1 d+1:nd]; x=permute(x,p); w=permute(w,p); end
  [x,o]=sort(x); w=w(o); w=cumsum(w); is={':'}; is=is(ones(1,nd-1));
  w=bsxfun(@rdivide,w,w(end,is{:})); [~,j]=min(w<=.5);
  s=size(x); s=reshape(((1:n/s(1))-1)*s(1),size(j));
  j0=max(1,j-1); j0=j0+s; j=j+s;
  same=w(j0)~=.5; j0(same)=j(same); m=(x(j0)+x(j))/2;
  if(d>1), p=[2:d 1 d+1:nd]; m=permute(m,p); end
end

end
