function [subs,vals,keepLocs] = nonMaxSuprWin( subs, vals, ...
  strLocs, endLocs, thresh, maxn )
% Nonmaximal suppression of values outside of a given window.
%
% Suppresses all location in subs that do not fall in given range (defined
% by strLocs and endLocs).  For example, if subs are 3D coordinates of
% maxes over an array of size siz,  "nonMaxSuprWin( subs, vals,
% [1,1,1]+10, siz-10 )" suppreses all locations within 10 pixels of the
% border of I.
%
% USAGE
%  [subs,vals,keepLocs] = nonMaxSuprWin( subs, vals, ...
%                                      strLocs, endLocs, thresh, maxn )
%
% INPUTS
%  subs        - subscripts of point locations (m x d)
%  vals        - values at point locations (m x 1)
%  strLocs     - locations at which to start cropping along each dim
%  endLocs     - locations at which to end cropping along each dim
%  thresh      - [] minimum value below which not to look fo
%  maxn        - [] return at most maxn of the largest vals
%
% OUTPUTS
%  subs        - subscripts of non-suppressed point locations (n x d)
%  vals        - values at non-suppressed point locations (n x 1)
%  keepLocs    - indicies of kept locations from subs (n x 1)
%
% EXAMPLE
%
% See also SUBSTOARRAY, NONMAXSUPR, NONMAXSUPRLIST
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

vals = vals(:);  nvals = length(vals);  nd=size(subs,2);
if( nargin<5 || isempty(thresh)); thresh=[]; end
if( nargin<6 || isempty(maxn)); maxn = []; end

[strLocs,er] = checkNumArgs( strLocs, [1 nd], 0, 0 ); error(er);
[endLocs,er] = checkNumArgs( endLocs, [1 nd], 0, 0 ); error(er);
if (any(strLocs>endLocs)); error('strLocs must be <= endLocs'); end

% discard vals below thresh
if (~isempty(thresh))
  keepLocs = vals > thresh;
else
  keepLocs = true( nvals, 1 );
end

% suppress all values outside of window defined by start and end locs
for d=1:nd
  if (strLocs(d)>0)
    keepLocsi = (subs(:,d)>=strLocs(d)) & (subs(:,d)<=endLocs(d));
    keepLocs = keepLocs & keepLocsi;
  end
end

% suppress all but the first maxn nonzero elts in keepLocs
if( ~isempty(maxn) && maxn>0 && maxn<sum(keepLocs) )
  [~,order] = sort( -vals ); [~,unorder]=sort(order);
  keepLocs = keepLocs(order);
  keepLocs( cumsum( keepLocs )>maxn ) = 0;
  keepLocs = keepLocs(unorder);
end

% discard locations where keepLocs==0
vals = vals( keepLocs ); subs = subs( keepLocs, : );
