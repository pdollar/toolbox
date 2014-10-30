function [y1,y2] = toolboxHeader( x1, x2, x3, prm )
% One line description of function (will appear in file summary).
%
% General commments explaining purpose of function [width is 75
% characters]. There may be multiple paragraphs. In special cases some or
% all of these guidelines may need to be broken.
%
% Next come a series of sections, including USAGE, INPUTS, OUTPUTS,
% EXAMPLE, and "See also". Each of these fields should always appear, even
% if nothing follows (for example no inputs). USAGE should usually be a
% copy of the first line of code (which begins with "function"), minus the
% word "function". Optional parameters are surrounded by brackets.
% Occasionally, there may be more than 1 distinct usage, in this case list
% additional usages. In general try to avoid this. INPUTS/OUTPUTS are
% self explanatory, however if there are multiple usages can be subdivided
% as below. EXAMPLE should list 1 or more useful examples. Main comment
% should all appear as one contiguous block. Next a blank comment line,
% and then a short comment that includes the toolbox version.
%
% USAGE
%  xsum = toolboxHeader( x1, x2, [x3], [prm] )
%  [xprod, xdiff] = toolboxHeader( x1, x2, [x3], [prm] )
%
% INPUTS
%  x1          - descr. of variable 1,
%  x2          - descr. of variable 2, keep spacing like this
%                if descr. spans multiple lines do this
%  x3          - [0] indicates an optional variable, put def val in []
%  prm         - [] param struct
%       .p1      parameter 1 descr
%       .p2      parameter 2 descr
%
% OUTPUTS - and whatever after the dash
%  xsum        - sum of xs
%
% OUTPUTS - usage 2
%  xprod       - prod of xs
%  xdiff       - negative sum of xs
%
% EXAMPLE - and whatever after the dash
%  y = toolboxHeader( 1, 2 );
%
% EXAMPLE - example 2
%  y = toolboxHeader( 2, 3 );
%
% See also GETPRMDFLT
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.10
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

% optional arguments x3 and prm
if( nargin<3 || isempty(x3) ), x3=0;  end
if( nargin<4 || isempty(prm) ), prm=[]; end %#ok<NASGU>

% indents should be set with Matlab's "smart indent" (with 2 spaces)
if( nargout==1 )
  y1 = add(x1,x2) + x3;
else
  y1 = x1 * x2 * x3;
  y2 = - x1 - x2 - x3;
end

function s=add(x,y)
% optional sub function comment
s=x+y;
