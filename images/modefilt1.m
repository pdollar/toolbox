function y = modefilt1( x, s )
% One-dimensional mode filtering.
%
% Applies an order 2*r+1 one-dimensional mode filter to vector x.  That is
% each element of the output y(i) corresponds to the mode of
% x(i-s/2:i+s/2). At boundary regions, y is calculated on smaller windows,
% for example y(1) is calculated over x(1:1+s/2).  Note that for this
% function to make sense x should take on only a number of discrete values.
%
% This function is modeled after medfilt1, which is part of the 'Signal
% Processing Toolbox' and may not be available on all systems.
%
% USAGE
%  y = modefilt1( x, s )
%
% INPUTS
%  x   - length n vector
%  s   - filter size
%
% OUTPUTS
%  y   - filtered vector x
%
% EXAMPLE
%  x=[0, 1, 0, 0, 0, 3, 0, 1, 3, 1, 2, 2, 0, 1]; s=4;
%  ymedian = medfilt1( x, s ); % may not be available
%  ymode   = modefilt1( x, s );
%  [x; ymedian; ymode]
%
% See also MEDFILT1
%
% Piotr's Image&Video Toolbox      Version 2.12
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

[b,dis,inds] = unique(x(:)');
m = length(b); n = length(x);
if(m>256)
  warning('modefilt1: x takes on large number of diff vals'); %#ok<WNTAG>
end

% create quantized representation
A = zeros( m, n );
Ainds = sub2ind2( [m,n], [inds; 1:n]' );
A( Ainds ) = 1;

% apply localSum (or smooth?)
%A = gaussSmooth( A, [0 r/2-1], 'smooth' );
A = localSum( A, [0 s], 'same' );

% create y
[vs,inds] = max( A,[],1 );
y=b( inds );
