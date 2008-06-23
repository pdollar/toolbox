function [subs,vals,keepLocs] = nonMaxSuprList( subs, vals, radii, ...
  thresh, maxn, suprEq)
% Applies nonmaximal suppression to a list.
%
% See nonMaxSupr for more information.  Has the same effect as nonMaxSupr
% except it operates on a list of position/values pairs.  Running time is
% n^2 in the number of such pairs.  For comparison running time of
% nonMaxSupr is order( sum( size(I,d)*radii(d) ).
%
% This function has an additional parameter - suprEq that causes a value
% in a given window to be suppressed unless it is the UNIQUE maximum in the
% window.  This is if suprEq==1, then all locations that are not strictly
% the biggest in their window are suppressed.  This can be useful for large
% flat regions -- nonMaxSupr(ones(30),3) does no suppression since all
% values are equal in each window, but nonMaxSuprList(ones(30),3)
% suppresses all locations.
%
% USAGE
%  [subs,vals,keepLocs] = nonMaxSuprList( subs, vals, radii, ...
%                                        [thresh], [maxn], [suprEq] )
%
% INPUTS
%  subs       - subscripts of point locations (m x d)
%  vals       - values at point locations (m x 1)
%  radii      - suppression window dimensions
%  thresh     - [] minimum value below which not to look for (or [])
%  maxn       - [] return at most maxn of the largest vals
%  suprEq     - [] suppress equal vals (see above)
%
% OUTPUTS
%  subs       - subscripts of non-suppressed point locations (n x d)
%  vals       - values at non-suppressed point locations (n x 1)
%  keepLocs   - indicies of kept locations from subs (n x 1)
%
% EXAMPLE
%
% See also SUBSTOARRAY, NONMAXSUPR, NONMAXSUPRWIN
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<4 || isempty(thresh)); thresh=[]; end;
if( nargin<5 || isempty(maxn)); maxn=0; end;
if( nargin<6 || isempty(suprEq)); suprEq=0; end;

vals = vals(:); siz = max( subs ); nvals = length(vals);
[radii,er] = checkNumArgs( radii, size(siz), 0, 1 ); error(er);

% CAN ADD RECURSION TO SIGNIFICANTLY SPEED IT UP (under certain assump)
% simply divide into 2 eqal regions, (plus 3rd overlap region) using
% nonMaxSuprWin.  then & keepLocs results from all 3.
if( nvals>5000 ); error('Input too large - use nonMaxSupr.'); end;

% discard vals below thresh
if (~isempty(thresh))
  keepLocs = vals > thresh;
else
  keepLocs = true( nvals, 1 );
end

% now supress equals - for each (nonsuppressed) i, suppress it if any
% of its neighbors are greater then (or greater then or equal) to it.
radiiRep = repmat( radii, [nvals,1] );
for i=1:nvals
  if( keepLocs(i) )
    if( suprEq ); geqlocs = (vals >= vals(i)); geqlocs(i)=0;
    else geqlocs = (vals > vals(i)); end;
    ngeqlocs=sum(geqlocs);
    dists = abs( subs(geqlocs,:) - ones(ngeqlocs,1) * subs(i,:));
    if( any( all( dists <= radiiRep(1:ngeqlocs,:), 2 ) ) )
      keepLocs(i)=0;
    end
  end
end

% suppress all but the first maxn values in keepLocs
if( ~isempty(maxn) && maxn>0 && maxn<sum(keepLocs) )
  [discard, order] = sort( -vals ); [discard,unorder]=sort(order);
  keepLocs = keepLocs(order);
  keepLocs( cumsum( keepLocs )>maxn ) = 0;
  keepLocs = keepLocs(unorder);
end

% discard all vals/subs not in keepLocs
vals = vals( keepLocs );  subs = subs( keepLocs, : );
