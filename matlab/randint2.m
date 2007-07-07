% Faster but restricted version of randint.
%
% Generate matrix of uniformly distributed random integers.
% R=randint2(m,n,range) generates an m-by-n matrix of random integers
% between [range(1), range(2)].
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

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function R = randint2( m, n, range )

R = rand( m, n );
R = range(1) + floor( (range(2)-range(1)+1)*R );

