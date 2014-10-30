function [ x, er ] = checkNumArgs( x, siz, intFlag, signFlag )
% Helper utility for checking numeric vector arguments.
%
% Runs a number of tests on the numeric array x.  Tests to see if x has all
% integer values, all positive values, and so on, depending on the values
% for intFlag and signFlag. Also tests to see if the size of x matches siz
% (unless siz==[]).  If x is a scalar, x is converted to a array simply by
% creating a matrix of size siz with x in each entry.  This is why the
% function returns x.  siz=M is equivalent to siz=[M M]. If x does not
% satisfy some criteria, an error message is returned in er. If x satisfied
% all the criteria er=''.  Note that error('') has no effect, so can use:
%  [ x, er ] = checkNumArgs( x, ... ); error(er);
% which will throw an error only if something was wrong with x.
%
% USAGE
%  [ x, er ] = checkNumArgs( x, siz, intFlag, signFlag )
%
% INPUTS
%  x           - numeric array
%  siz         - []: does not test size of x
%              - [if not []]: intended size for x
%  intFlag     - -1: no need for integer x
%                 0: error if non integer x
%                 1: error if non odd integers
%                 2: error if non even integers
%  signFlag    - -2: entires of x must be strictly negative
%                -1: entires of x must be negative
%                 0: no contstraints on sign of entries in x
%                 1: entires of x must be positive
%                 2: entires of x must be strictly positive
%
% OUTPUTS
%  x   - if x was a scalar it may have been replicated into a matrix
%  er  - contains error msg if anything was wrong with x
%
% EXAMPLE
%  a=1; [a, er]=checkNumArgs( a, [1 3], 2, 0 ); a, error(er)
%
% See also NARGCHK
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.0
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

xname = inputname(1); er='';
if( isempty(siz) ); siz = size(x); end;
if( length(siz)==1 ); siz=[siz siz]; end;

% first check that x is numeric
if( ~isnumeric(x) ); er = [xname ' not numeric']; return; end;

% if x is a scalar, simply replicate it.
xorig = x; if( length(x)==1); x = x(ones(siz)); end;

% regardless, must have same number of x as n
if( length(siz)~=ndims(x) || ~all(size(x)==siz) )
  er = ['has size = [' num2str(size(x)) '], '];
  er = [er 'which is not the required size of [' num2str(siz) ']'];
  er = createErrMsg( xname, xorig, er ); return;
end

% check that x are the right type of integers (unless intFlag==-1)
switch intFlag
  case 0
    if( ~all(mod(x,1)==0))
      er = 'must have integer entries';
      er = createErrMsg( xname, xorig, er); return;
    end;
  case 1
    if( ~all(mod(x,2)==1))
      er = 'must have odd integer entries';
      er = createErrMsg( xname, xorig, er); return;
    end;
  case 2
    if( ~all(mod(x,2)==0))
      er = 'must have even integer entries';
      er = createErrMsg( xname, xorig, er ); return;
    end;
end;

% check sign of entries in x (unless signFlag==0)
switch signFlag
  case -2
    if( ~all(x<0))
      er = 'must have strictly negative entries';
      er = createErrMsg( xname, xorig, er ); return;
    end;
  case -1
    if( ~all(x<=0))
      er = 'must have negative entries';
      er = createErrMsg( xname, xorig, er ); return;
    end;
  case 1
    if( ~all(x>=0))
      er = 'must have positive entries';
      er = createErrMsg( xname, xorig, er ); return;
    end;
  case 2
    if( ~all(x>0))
      er = 'must have strictly positive entries';
      er = createErrMsg( xname, xorig, er ); return;
    end
end

function er = createErrMsg( xname, x, er )
if(numel(x)<10)
  er = ['Numeric input argument ' xname '=[' num2str(x) '] ' er '.'];
else
  er = ['Numeric input argument ' xname ' ' er '.'];
end
