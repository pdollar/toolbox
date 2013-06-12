function [subs,vals,keep] = nonMaxSuprList( subs, vals, radii, ...
  thresh, maxn, flag)
% Applies nonmaximal suppression to a list.
%
% See nonMaxSupr for more information.  Has the same effect as nonMaxSupr
% except it operates on a list of position/values pairs.  Running time is
% n^2 in the number of such pairs.  For comparison running time of
% nonMaxSupr is ord( sum( size(I,d)*radii(d) ).
%
% This function has an additional parameter - flag. If flag==1, then all
% locations that are not strictly the biggest in their window are
% suppressed (ie, keeps max only if it is UNIQUE).  This can be useful for
% large flat regions -- nonMaxSupr(ones(30),3) does no suppression since
% all values are equal in each window, but nonMaxSuprList(ones(30),3) w
% flag==1 suppresses all locations. If flag==2 ties are broken randomly (in
% fact this allows for slightly faster execution).
%
% USAGE
%  [subs,vals,keep] = nonMaxSuprList( subs, vals, radii, ...
%    [thresh], [maxn], [flag] )
%
% INPUTS
%  subs       - subscripts of point locations (m x d)
%  vals       - values at point locations (m x 1)
%  radii      - suppression window dimensions
%  thresh     - [] minimum value below which not to look for (or [])
%  maxn       - [] return at most maxn of the largest vals
%  flag       - [] suppress equal vals (see above)
%
% OUTPUTS
%  subs       - subscripts of non-suppressed point locations (n x d)
%  vals       - values at non-suppressed point locations (n x 1)
%  keep       - indicies of kept locations from subs (n x 1)
%
% EXAMPLE
%
% See also SUBSTOARRAY, NONMAXSUPR, NONMAXSUPRWIN
%
% Piotr's Image&Video Toolbox      Version 2.12
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<4 || isempty(thresh)); thresh=[]; end;
if( nargin<5 || isempty(maxn)); maxn=0; end;
if( nargin<6 || isempty(flag)); flag=0; end;

vals=vals(:); siz=max(subs,[],1); nvals=length(vals); d=size(subs,2);
if(nvals==0 && isempty(subs)), keep=[]; return; end
[radii,er] = checkNumArgs( radii, size(siz), -1, 1 ); error(er);

% CAN ADD RECURSION TO SIGNIFICANTLY SPEED IT UP (under certain assump)
% simply divide into 2 equal regions, (plus 3rd overlap region) using
% nonMaxSuprWin.  then & keep results from all 3.
if( nvals>5000 ); error('Input too large - use nonMaxSupr.'); end;

% sort according to vals
if(flag==2), vals1=vals+randn(nvals,1)/10000; else vals1=vals; end
[~,ord]=sort(vals1,'descend'); [~,unord]=sort(ord);
vals0=vals; subs0=subs; vals=vals(ord); subs=subs(ord,:);

% discard vals below thresh
if(~isempty(thresh))
  nvalsd=sum(vals<=thresh); nvals=nvals-nvalsd;
  vals=vals(1:nvals); subs=subs(1:nvals,:);
  if(nvals==0), keep=zeros(nvalsd,1); return; end
end

% suppress each element that has a larger neighboring element
% close(i,j)=1 -> i,j neighbors, bigger(i,j) -> vals(i)>vals(j)
nOnes=ones(1,nvals); close=true(nvals,nvals);
for i=1:d
  subsi=subs(:,i); subsi=subsi(:,nOnes);
  close = close & abs(subsi-subsi')<=radii(i);
end
if(flag==2), bigger=triu(ones(nvals),1); else
  bigger=vals(:,nOnes); bigger=bigger'-bigger;
  if(flag), bigger=bigger<=0 & ~eye(nvals); else bigger=bigger<0; end
end
keep = ~any(close & bigger)';

% suppress all but the first maxn elements
if(~isempty(maxn) && maxn>0), keep(cumsum(keep)>maxn)=0; end

% adjust to original order, then discard all vals/subs not in keep
if(~isempty(thresh)), keep=[keep; false(nvalsd,1)]; end
vals=vals0; subs=subs0; keep=keep(unord);
vals = vals(keep); subs = subs(keep,:);
