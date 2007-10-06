% One line description of function (will appear in file summary).
%
% General commments explaining purpose of function [width is 75
% characters]. There may be multiple paragraphs.  In special cases some or
% all of these guidelines may need to be broken.
%
% Next come a series of sections, including USAGE, INPUTS, OUTPUTS,
% EXAMPLE, and "See also".  Each of these fields should always appear, even
% if nothing follows (for example no inputs).  USAGE should usually be a
% copy of the first line of code (which begins with "function"), minus the
% word "function". Optional parameters are surrounded by brackets.
% Occasionally, there may be more than 1 distinct usage, in this case list
% additional usages.  In general try to avoid this.  INPUTS/OUTPUTS are
% self explanatory, however if there are multiple usages can be subdivided
% as below.  EXAMPLE should list 1 or more useful examples.  Main comment
% should all appear as one contiguous block.  Next a space, and then a
% short comment that includes the toolbox version.  All other comments
% should appear after the function begins.
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
%  prm         - [] param struct (preferred over key/value list)
%       .p1      parameter 1 descr.
%       .p2      parameter 2 descr.
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
% See also FUNCTIONALLCAPS

% Piotr's Image&Video Toolbox      Version 1.5
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Liscensed under the Lesser GPL [see external/lgpl.txt]

function [y1,y2] = toolboxHeader( x1, x2, x3, prm ) %#ok<INUSD>

% A Blank line right after the function delclaration
% All indents should be set using "smart indent" from Matlab (2 spaces)

if( nargin < 3 ); x3=0;  end

if( nargout==1 )
  y1 = add(x1,x2) + x3;
else
  y1 = x1 * x2 * x3;
  y2 = - x1 - x2 - x3;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all the way for sub-functions
function s=add(x,y)

s=x+y;
