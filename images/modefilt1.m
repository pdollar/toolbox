% One-dimensional mode filtering.
%
% Applies an order 2*r+1 one-dimensional mode filter to vector x.  That is each element of
% the output y(i) corresponds to the mode of x(i-s/2:i+s/2). At boundary regions, y is
% calculated on smaller windows, for example y(1) is calculated over x(1:1+s/2).  Note
% that for this function to make sense x should take on only a number of discrete values.
%
% INPUTS
%   x   - length n vector 
%   s   - filter size
%
% OUTPUTS
%   y   - filtered vector x
% 
% EXAMPLE
%   x=[0, 1, 0, 0, 0, 3, 0, 1, 3, 1, 2, 2, 0, 1]; s=4;
%   ymedian = medfilt1( x, s );
%   ymode   = modefilt1( x, s );
%   [x; ymedian; ymode]
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also MEDFILT1

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function y = modefilt1( x, s )
    [b,dis,inds] = unique(x(:)');
    m = length(b); n = length(x);
    if(m>256) warning( 'modefilt1: x takes on a large number of different values'); end;

    % create quantized representation
    A = zeros( m, n );
    Ainds = sub2ind2( [m,n], [inds; 1:n]' );
    A( Ainds ) = 1;
    
    % apply local_sum (or smooth?)
    %A = gauss_smooth( A, [0 r/2-1], 'smooth' );
    A = localsum( A, [0 s], 'same' );

    % create y
    [vs,inds] = max( A,[],1 );
    y=b( inds );
