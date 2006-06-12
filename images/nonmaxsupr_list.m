% Applies nonmaximal suppression to a list.
%
% See nonmaxsupr for more information.  Has the same effect as nonmaxsupr except it
% operates on a list of position/values pairs.  Running time is n^2 in the number of such
% pairs.  For comparison running time of nonmaxsupr is order( sum( size(I,d)*radii(d) ).
% 
% This function has an additional parameter - supr_eq that causes a value in a given
% window to be suppressed unless it is the UNIQUE maximum in the window.  This is if
% supr_eq==1, then all locations that are not strictly the biggest in their window are
% suppressed.  This can be useful for large flat regions -- nonmaxsupr(ones(30),3) does no
% suppression since all values are equal in each window, but nonmaxsupr_list(ones(30),3)
% suppresses all locations. 
% 
% INPUTS
%   subs    - subscripts of point locations (m x d) 
%   vals    - values at point locations (m x 1)
%   radii   - suppression window dimensions 
%   thresh  - [optional] minimum value below which not to look for (or [])
%   maxn:   - [optional] return at most maxn of the largest vals 
%   supr_eq - [optional] suppress equal vals (see above)
%
% OUTPUTS
%   subs        - subscripts of non-suppressed point locations (n x d) 
%   vals        - values at non-suppressed point locations (n x 1)
%   keeplocs    - indicies of kept locations from subs (n x 1)
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also IMSUBS2ARRAY, NONMAXSUPR, NONMAXSUPR_WINDOW

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [subs,vals,keeplocs] = nonmaxsupr_list( subs, vals, radii, thresh, maxn, supr_eq)
    if( nargin<4 || isempty(thresh)) thresh=[]; end; 
    if( nargin<5 || isempty(maxn)) maxn=0; end;
    if( nargin<6 || isempty(supr_eq)) supr_eq=0; end;
    
    vals = vals(:); siz = max( subs ); nvals = length(vals); 
    [radii,er] = checknumericargs( radii, size(siz), 0, 1 ); error(er);    
    
    % CAN ADD RECURSION TO SIGNIFICANTLY SPEED IT UP (under certain assump)!
    % simply divide into 2 eqal regions, (plus 3rd overlap region) using
    % nonmaxsupr_window.  then & keeplocs results from all 3.
    if( nvals>5000 ) error('Input too large - use nonmaxsupr.'); end;
    
    % discard vals below thresh
    if (~isempty(thresh))
        keeplocs = vals > thresh;
    else
        keeplocs = logical( ones( nvals, 1 ) );
    end

    % now supress equals - for each (nonsuppressed) i, suppress it if any
    % of its neighbors are greater then (or greater then or equal) to it.   
    radii_rep = repmat( radii, [nvals,1] );
    for i=1:nvals if( keeplocs(i) )
        if( supr_eq ) geqlocs = (vals >= vals(i)); geqlocs(i)=0; 
            else geqlocs = (vals > vals(i)); end;
        ngeqlocs=sum(geqlocs);
        dists = abs( subs(geqlocs,:) - ones(ngeqlocs,1) * subs(i,:));
        if( any( all( dists <= radii_rep(1:ngeqlocs,:), 2 ) ) ) keeplocs(i)=0; end
    end; end;

    % suppress all but the first maxn values in keeplocs
    if( ~isempty(maxn) && maxn>0 && maxn<sum(keeplocs) ) 
        [discard, order] = sort( -vals ); [discard,unorder]=sort(order); 
        keeplocs = keeplocs(order);
        keeplocs( cumsum( keeplocs )>maxn ) = 0; 
        keeplocs = keeplocs(unorder);
    end    
    
    % discard all vals/subs not in keeplocs
    vals = vals( keeplocs );  subs = subs( keeplocs, : );        
