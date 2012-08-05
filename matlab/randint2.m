function R = randint2( m, n, range )
% Faster but restricted version of randint.
%
% Generate matrix of uniformly distributed random integers.
% R=randint2(m,n,range) generates an m-by-n matrix of random integers
% between [range(1), range(2)]. Note that randint is part of the
% 'Communications Toolbox' and may not be available on all systems.
%
% To test speed:
%  tic, for i=1:1000; R = randint( 100, 10, [0 10] ); end; toc
%  tic, for i=1:1000; R = randint2( 100, 10, [0 10] ); end; toc
%
% USAGE
%  R = randint2( m, n, range )
%
% INPUTS
%  m      - m rows
%  n      - n cols
%  range  - range of ints
%
% OUTPUTS
%  R    - mxn matrix of integers
%
% EXAMPLE
%  R = randint2( 2, 5, [0 1] )
%
% See also RANDINT
%
% Piotr's Image&Video Toolbox      Version 2.12
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

R = rand( m, n );
R = range(1) + floor( (range(2)-range(1)+1)*R );
