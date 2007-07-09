% Applies nonmaximal suppression on an image of arbitrary dimension.
%
% nonMaxSupr( I, ... ) returns the pixel location and values of local
% maximums - that is a location is returned only if it has a value greater
% then or equal to all pixels in the surrounding window of size radii. I
% can be smoothed first to make method more robust. The first output is an
% array of the subscript locations of maximal values in I and the second
% output contains the corresponding maximal values.  One can convert
% subs/vals back to an array representation using imsubs2array. Note that
% values are suppressed iff there are strictly greater values in the
% neighborhood.  Hences nonMaxSupr(ones(10),5) would not suppress any
% values.
%
% USAGE
%  [subs,vals] = nonMaxSupr( I, radii, [thresh], [maxn] )
%
% INPUTS
%  I       - matrix to apply nonMaxSupr to
%  radii   - suppression window dimensions
%  thresh  - [] minimum value below which not to look for maxes
%  maxn:   - [0] return at most maxn of the largest vals
%
% OUTPUTS
%  subs    - subscripts of non-suppressed point locations (n x d)
%  vals    - values at non-suppressed point locations (n x 1)
%
% EXAMPLE - 1
%  G = filterGauss( [25 25], [13,13], 3*eye(2), 1 );
%  siz=[11 11]; G = filterGauss( siz, (siz+1)/2, eye(2), 1 );
%  [subs,vals] = nonMaxSupr( G, 1, eps );
%  figure(2); im( imsubs2array( subs, vals, siz ) );
%  [subs,vals] = nonMaxSuprList( ind2sub2(siz,(1:prod(siz))'), G(:)',1 );
%  figure(3); im( imsubs2array( subs, vals, siz ) );
%
% EXAMPLE - 2
%  siz=[30 30]; I=ones(siz); I(22,23)=I(22,23)+3;
%  I(12,23)=I(12,23)+5; I(7,1)=I(7,1)-.5; figure(1); im(I);
%  r=3; suprEq = 1; maxn=[]; thresh=eps;
%  [subs,vals] = nonMaxSupr(I,r,thresh,maxn);
%  figure(2); im( imsubs2array( subs, vals, siz ) );
%  [subs,vals] = nonMaxSuprWin(subs,vals,[1 1]+6,siz-6);
%  figure(3); im( imsubs2array( subs, vals, siz ) );
%  [subs2,vals2] = nonMaxSuprList( ind2sub2(siz,(1:prod(siz))'), ...
%                                           I(:)',r,thresh,maxn,suprEq );
%  figure(4); im( imsubs2array( subs2, vals2, siz ) );
%
% See also IMSUBS2ARRAY, NONMAXSUPRLIST, NONMAXSUPRWIN

% Piotr's Image&Video Toolbox      Version NEW
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function [subs,vals] = nonMaxSupr( I, radii, thresh, maxn )

% default values [error checking done by nlfilter_max]
if( nargin<3 || isempty(thresh)); thresh=min(I(:))-eps; end;
if( nargin<4 || isempty(maxn)); maxn = 0; end;

% all the work is really done by nlfilter_max.m
IR = nlfiltersep( I, 2*radii+1, 'same', @rnlfilt_max );
suprlocs = (I < IR) | (I <= thresh);

% create output accordingly
subs = find( suprlocs==0 );  vals = I( subs );
[vals,order] = sort(-vals); vals=-vals; subs=subs(order);
if( ~isempty(maxn) && maxn>0 && maxn<length(vals) )
  subs = subs( 1:maxn ); vals = vals( 1:maxn );
end
subs = ind2sub2(size(I),subs);
