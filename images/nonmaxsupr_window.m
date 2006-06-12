% Nonmaximal suppression of values outside of a given window.
%
% Suppresses all location in subs that do not fall in given range (defined by start_locs
% and end_locs).  For example, if subs are 3D coordinates of maxes over an array of size
% siz,  "nonmaxsupr_window( subs, vals, [1,1,1]+10, siz-10 )" suppreses all locations
% within 10 pixels of the border of I.
%
% INPUTS
%   subs        - subscripts of point locations (m x d) 
%   vals        - values at point locations (m x 1)
%   start_locs  - locations at which to start cropping along each dim
%   end_locs    - locations at which to end cropping along each dim
%   thresh      - [optional] minimum value below which not to look fo
%   maxn        - [optional] return at most maxn of the largest vals 
%
% OUTPUTS
%   subs        - subscripts of non-suppressed point locations (n x d) 
%   vals        - values at non-suppressed point locations (n x 1)
%   keeplocs    - indicies of kept locations from subs (n x 1)
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also IMSUBS2ARRAY, NONMAXSUPR, NONMAXSUPR_LIST

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [subs,vals,keeplocs] = nonmaxsupr_window( subs, vals, ...
                                    start_locs, end_locs, thresh, maxn )
    vals = vals(:);  nvals = length(vals);  nd=size(subs,2);
    if( nargin<5 || isempty(thresh)) thresh=[]; end;     
    if( nargin<6 || isempty(maxn)) maxn = []; end;

    [start_locs,er] = checknumericargs( start_locs, [1 nd], 0, 0 ); error(er);    
    [end_locs,er]   = checknumericargs( end_locs,   [1 nd], 0, 0 ); error(er);    
    if (any(start_locs>end_locs)) error('start_locs must be <= end_locs'); end;
    
    % discard vals below thresh
    if (~isempty(thresh))
        keeplocs = vals > thresh;
    else
        keeplocs = logical( ones( nvals, 1 ) );
    end    
    
    % suppress all values outside of window defined by start and end locs
    for d=1:nd
        if (start_locs(d)>0)
            keeplocs_i = (subs(:,d)>=start_locs(d)) & (subs(:,d)<=end_locs(d));
            keeplocs = keeplocs & keeplocs_i;
        end
    end    
    
    % suppress all but the first maxn nonzero elts in keeplocs
    if( ~isempty(maxn) && maxn>0 && maxn<sum(keeplocs) ) 
        [discard, order] = sort( -vals ); [discard,unorder]=sort(order); 
        keeplocs = keeplocs(order);
        keeplocs( cumsum( keeplocs )>maxn ) = 0; 
        keeplocs = keeplocs(unorder);
    end    
    
    % discard locations where keeplocs==0
    vals = vals( keeplocs );  subs = subs( keeplocs, : );        
