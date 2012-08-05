function y = medfilt1m( x, r, z )
% One-dimensional adaptive median filtering with missing values.
%
% Applies a width s=2*r+1 one-dimensional median filter to vector x, which
% may contain missing values (elements equal to z). If x contains no
% missing values, y(j) is set to the median of x(j-r:j+r). If x contains
% missing values, y(j) is set to the median of x(j-R:j+R), where R is the
% smallest radius such that sum(valid(x(j-R:j+R)))>=s, i.e. the number of
% valid values in the window is at least s (a value x is valid x~=z). Note
% that the radius R is adaptive and can vary as a function of j.
%
% This function uses a modified version of medfilt1.m from Matlab's 'Signal
% Processing Toolbox'. Note that if x contains no missing values,
% medfilt1m(x) and medfilt1(x) are identical execpt at boundary regions.
%
% USAGE
%  y = medfilt1m( x, r, [z] )
%
% INPUTS
%  x      - [nx1] length n vector with possible missing entries
%  r      - filter radius
%  z      - [NaN] element that represents missing entries
%
% OUTPUTS
%  y      - [nx1] filtered vector x
%
% EXAMPLE
%  x=repmat((1:4)',1,5)'; x=x(:)'; x0=x;
%  n=length(x); x(rand(n,1)>.8)=NaN;
%  y = medfilt1m(x,2); [x0; x; y; x0-y]
%
% See also MODEFILT1, MEDFILT1
%
% Piotr's Image&Video Toolbox      Version 2.35
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% apply medfilt1 (standard median filter) to valid locations in x
if(nargin<3 || isempty(z)), z=NaN; end; x=x(:)'; n=length(x);
if(isnan(z)), valid=~isnan(x); else valid=x~=z; end; v=sum(valid);
if(v==0), y=repmat(z,1,n); return; end
if(v<2*r+1), y=repmat(median(x(valid)),1,n); return; end
y=medfilt1(x(valid),2*r+1);

% get radius R needed at each location j to span s=2r+1 valid values
% get start (a) and end (b) locations and map back to location in y
C=[0 cumsum(valid)]; s=2*r+1; R=find(C==s); R=R(1)-2; pos=zeros(1,n);
for j=1:n, R0=R;
  R=R0-1; a=max(1,j-R); b=min(n,j+R);
  if(C(b+1)-C(a)<s), R=R0; a=max(1,j-R); b=min(n,j+R);
    if(C(b+1)-C(a)<s), R=R0+1; a=max(1,j-R); b=min(n,j+R); end
  end
  pos(j)=(C(b+1)+C(a+1))/2;
end
y=y(floor(pos));

end

function y = medfilt1( x, s )
% standard median filter (copied from medfilt1.m)
n=length(x); r=floor(s/2); indr=(0:s-1)'; indc=1:n;
ind=indc(ones(1,s),1:n)+indr(:,ones(1,n));
x0=x(ones(r,1))*0; X=[x0'; x'; x0'];
X=reshape(X(ind),s,n); y=median(X,1);
end

% function y = medfilt1( x, s )
% % standard median filter (slow)
% % get unique values in x
% [vals,disc,inds]=unique(x); m=length(vals); n=length(x);
% if(m>256), warning('x takes on large number of diff vals'); end %#ok<WNTAG>
% % create quantized representation [H(i,j)==1 iff x(j)==vals(i)]
% H=zeros(m,n); H(sub2ind2([m,n],[inds; 1:n]'))=1;
% % create histogram [H(i,j) is count of x(j-r:j+r)==vals(i)]
% H=localSum(H,[0 s],'same');
% % compute median for each j and map inds back to original vals
% [disc,inds]=max(cumsum(H,1)>s/2,[],1); y=vals(inds);
% end
