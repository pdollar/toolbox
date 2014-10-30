function f = filterBinomial1d( r, show )
% 1D binomial filter (approximation to Gaussian filter)
%
% Creates a binomial filter of size 2*r+1 x 1.  This can be used to
% approximate the Gaussian distribution with sigma=sqrt((2*r+1)/4). For
% large r, should give same output as:
%  g = fspecial( 'Gaussian', [2*r+1,1],sqrt((2*r+1)/4) );
% Given sigma, use r ~= 2*sigma^2.
%
% Use F = f*f' to get the equivalent 2d filter.
%
% USAGE
%  f = filterBinomial1d( r, [show] )
%
% INPUTS
%  r       - mask will have length 2r+1 and var=(2*r+1)/4
%  show    - [0] figure to use for optional display
%
% OUTPUTS
%  f       - 1D binomial filter
%
% EXAMPLE
%  r = 10;
%  fbinom = filterBinomial1d( r, 1 );
%  fgauss = filterGauss( 2*r+1, [], (2*r+1)/4, 2);
%
% See also FILTERGAUSS
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 ); show=0; end;
if( mod(r,1)~=0 ); error( 'r must be an integer'); end;

f = diag(fliplr(pascal(2*r+1))) / 4^r;

% display
if(show); filterVisualize( f, show ); end;
