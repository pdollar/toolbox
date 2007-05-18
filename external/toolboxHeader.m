% One line description of function (will appear in file summary).   
%
% General commments explaining purpose of function [width is 75
% characters]. There may be multiple paragraphs.  
%
% Next come a series of sections, including USAGE, INPUTS, OUTPUTS,
% EXAMPLE, DATESTAMP and "See also".  Each of these fields should always
% appear, even if nothing follows (for example no inputs).  USAGE should
% usually be a copy of the first line of code (which begins with
% "function"), minus the word "function". Optional parameters are
% surrounded by brackets. Occasionally, there may be more than 1 distinct
% usage, in this case list additional usages.  In general try to avoid
% this.  INPUTS/OUTPUTS are self explanatory, however if there are multiple
% usages can be subdivided as below.  EXAMPLE should list 1 or more
% useful examples.  DATESTAMP is useful for keeping track of when a file
% was altered, should be manually updated after any tiny change to the
% file.  Main comment should all appear as one contiguous block.  Next a
% space, and then a short comment that includes the toolbox version.  All
% other comments should appear after the function begins.  
%
% In special cases some or all of these guidelines may need to be broken.
%
% USAGE
%  xsum = toolbox_header( x1, x2, [x3], [prm] )
%  [xprod, xdiff] = toolbox_header( x1, x2, [x3], [prm] )
%
% INPUTS
%  x1          - descr. of variable 1,
%  x2          - descr. of variable 2, keep spacing like this
%                if descr. spans multiple lines do this
%  x3          - [0] indicates an optional variable, put def val in []
%  prm         - [] param struct (preferred over key/value list)
%       .p1      - prm1 descr. 
%       .p2      - prm2 descr.
%
% OUTPUTS (usage 1)
%  xsum        - sum of xs
%
% OUTPUTS (usage 2)
%  xprod       - prod of xs
%  xdiff       - negative sum of xs
%
% EXAMPLE
%  y = toolbox_header( 1, 2 );
%
% See also FUNCTIONALLCAPS
%
% Piotr's Image&Video Toolbox      Version 1.03

% DATESTAMP  17-May-2007
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 

function [y1,y2] = toolbox_header( x1, x2, x3, prm )

% All indents should be set to two spaces.  

if( nargin < 3 ); x3=0; end;

if( nargout==1 )
  y1 = x1 + x2 + x3;
else
  y1 = x1 * x2 * x3;
  y2 = - x1 - x2 - x3;
end;

