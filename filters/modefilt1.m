function y = modefilt1( x, s )
% One-dimensional mode filtering.
%
% Applies a width s one-dimensional mode filter to vector x. That is each
% element of the output y(j) corresponds to the mode of x(j-r:j+r), where
% r~s/2. At boundary regions, y is calculated on smaller windows, for
% example y(1) is calculated over x(1:1+r).  Note that for this function to
% make sense x should take on only a small number of discrete values
% (running time is actually proportional to number of unique values of x).
% This function is modeled after medfilt1, which is part of Matlab's
% 'Signal Processing Toolbox'.
%
% USAGE
%  y = modefilt1( x, s )
%
% INPUTS
%  x   - length n vector
%  s   - filter size
%
% OUTPUTS
%  y   - filtered vector x
%
% EXAMPLE
%  x=[0 1 0 0 0 3 0 1 3 1 2 2 0 1]; s=3;
%  xmedian = medfilt1( x, s ); % may not be available
%  xmode = modefilt1( x, s );
%  [x; xmedian; xmode]
%
% See also MEDFILT1
%
% Piotr's Image&Video Toolbox      Version 2.35
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get unique values in x
[vals,~,inds]=unique(x(:)'); m=length(vals); n=length(x);
if(m>256), warning('x takes on large number of diff vals'); end %#ok<WNTAG>

% create quantized representation [H(i,j)==1 iff x(j)==vals(i)]
H=zeros(m,n); H(sub2ind2([m,n],[inds; 1:n]'))=1;

% create histogram [H(i,j) is count of x(j-r:j+r)==vals(i)]
H=localSum(H,[0 s],'same');

% compute mode for each j and map inds back to original vals
[~,inds]=max(H,[],1); y=vals(inds);

end
