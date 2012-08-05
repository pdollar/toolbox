function [subs,vals] = nonMaxSupr( I, radii, thresh, maxn )
% Applies nonmaximal suppression on an image of arbitrary dimension.
%
% nonMaxSupr( I, ... ) returns the pixel location and values of local
% maximums - that is a location is returned only if it has a value greater
% then or equal to all pixels in the surrounding window of size radii. I
% can be smoothed first to make method more robust. The first output is an
% array of the subscript locations of maximal values in I and the second
% output contains the corresponding maximal values.  One can convert
% subs/vals back to an array representation using subsToArray. Note that
% values are suppressed iff there are strictly greater values in the
% neighborhood.  Hences nonMaxSupr(ones(10),5) would not suppress any
% values. See also Example 3 for a trick for making nonMaxSupr fast (but
% possibly innacurate) for large radii (for n small).
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
%  figure(2); im( subsToArray( subs, vals, siz ) );
%  [subs,vals] = nonMaxSuprList( ind2sub2(siz,(1:prod(siz))'), G(:)',1 );
%  figure(3); im( subsToArray( subs, vals, siz ) );
%
% EXAMPLE - 2
%  siz=[30 30]; I=ones(siz); I(22,23)=I(22,23)+3;
%  I(12,23)=I(12,23)+5; I(7,1)=I(7,1)-.5; figure(1); im(I);
%  r=3; suprEq = 1; maxn=[]; thresh=eps;
%  [subs,vals] = nonMaxSupr(I,r,thresh,maxn);
%  figure(2); im( subsToArray( subs, vals, siz ) );
%  [subs,vals] = nonMaxSuprWin(subs,vals,[1 1]+6,siz-6);
%  figure(3); im( subsToArray( subs, vals, siz ) );
%  [subs2,vals2] = nonMaxSuprList( ind2sub2(siz,(1:prod(siz))'), ...
%    I(:)',r,thresh,maxn,suprEq );
%  figure(4); im( subsToArray( subs2, vals2, siz ) );
%
% EXAMPLE - 3
%  I=abs(randn(1000)*50); I=I/max(I(:));
%  I=gaussSmooth(I,10,'same',4); %note large radius
%  figure(1); clf; im(I); hold on; radii=[50 50];
%  tic, [subs1,vals1]=nonMaxSupr(I,[1 1],.1); toc
%  tic, [subs1,vals1]=nonMaxSuprList(subs1,vals1,radii); toc
%  plot(subs1(:,2),subs1(:,1),'+r');
%  tic, [subs2,vals2]=nonMaxSupr(I,radii,.1); toc
%  plot(subs2(:,2),subs2(:,1),'ob');
%
% See also SUBSTOARRAY, NONMAXSUPRLIST, NONMAXSUPRWIN
%
% Piotr's Image&Video Toolbox      Version 2.12
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% default values [error checking done by nlfiltersep_max]
if( nargin<3 || isempty(thresh)); thresh=min(I(:))-eps; end;
if( nargin<4 || isempty(maxn)); maxn = 0; end;

% all the work is really done by nlfiltersep_max.m
IR = nlfiltersep( I, 2*radii+1, 'same', @nlfiltersep_max );
suprlocs = (I < IR) | (I <= thresh);

% create output accordingly
subs = find( suprlocs==0 );  vals = I( subs );
[vals,order] = sort(-vals); vals=-vals; subs=subs(order);
if( ~isempty(maxn) && maxn>0 && maxn<length(vals) )
  subs = subs( 1:maxn ); vals = vals( 1:maxn );
end
subs = ind2sub2(size(I),subs);
