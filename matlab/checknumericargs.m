% Helper utility for checking numeric vector arguments.
%
% Runs a number of tests on the numeric array x.  Tests to see if x has all integer
% values, all positive values, and so on, depending on the values for integerflag and
% signflag. Also tests to see if the size of x matches siz (unless siz==[]).  If x is a
% scalar, x is converted to a array simply by creating a matrix of size siz with x in each
% entry.  This is why the function returns x.  siz=M is equivalent to siz=[M M]. 
%
% If x does not satisfy some criteria, an error message is returned in er. If x satisfied
% all the criteria er=''.  Note that error('') has no effect, so can always use: "[x,er] =
% checknumericargs( x, ... ); error(er);", which will throw an error only if something was
% wrong with x.
%
% INPUTS
%   x           - numeric array
%   siz         - [if []]: does not test size of x
%               - [if not []]: intended size for x
%   integerflag - [if -1]: no need for integer x
%                 [if  0]: error if non integer x
%                 [if  1]: error if non odd integers
%                 [if  2]: error if non even integers
%   signflag    - [if -2]: entires of x must be strictly negative
%                 [if -1]: entires of x must be negative
%                 [if  0]: no contstraints on sign of entries in x
%                 [if  1]: entires of x must be positive
%                 [if  2]: entires of x must be strictly positive
%
% OUTPUTS
%   x   - if x was a scalar it may have been replicated into a matrix 
%   er  - contains error msg if anything was wrong with x
%
% EXAMPLE
%   a=1;  [a,er] = checknumericargs( a, [1 3], 2, 0 ); a, error(er)
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [x,er] = checknumericargs( x, siz, integerflag, signflag )
    xname = inputname(1); er='';
    if( isempty(siz) ) siz = size(x); end;
    if( length(siz)==1 ) siz=[siz siz]; end;

    % first check that x is numeric 
    if( ~isnumeric(x) ) er = [xname ' not numeric']; return; end;

    % if x is a scalar, simply replicate it.
    xorig = x; if( length(x)==1) x = x(ones(siz)); end;

    % regardless, must have same number of x as n
    if( length(siz)~=ndims(x) || ~all(size(x)==siz) ) 
        msg = ['has size = [' num2str(size(x)) '], '];
        msg = [msg 'which is not the required size of [' num2str(siz) ']'];
        er = create_errormsg( xname, xorig, msg ); return;
    end

    % check that x are [integers] or [odd integers] or [even integers]
    switch integerflag
        case -1
            ;
        case 0
            if( ~all(mod(x,1)==0)) 
                er=create_errormsg( xname, xorig,'must have integer entries'); return; end;
        case 1
            if( ~all(mod(x,2)==1)) 
                er=create_errormsg( xname, xorig,'must have odd integer entries'); return; end;
        case 2
            if( ~all(mod(x,2)==0)) 
                er=create_errormsg( xname, xorig,'must have even integer entries'); return; end;
    end;

    % check sign of entries in x
    switch signflag
        case -2
            if( ~all(x<0))  
                er=create_errormsg( xname, xorig, 'must have strictly negative entries'); return; end;
        case -1
            if( ~all(x<=0)) 
                er=create_errormsg( xname, xorig, 'must have negative entries'); return; end;
        case 0
            ;
        case 1
            if( ~all(x>=0)) 
                er=create_errormsg( xname, xorig, 'must have positive entries'); return; end;
        case 2
            if( ~all(x>0))  
                er=create_errormsg( xname, xorig, 'must have strictly positive entries'); return; end;
    end;
    

    
    
function er = create_errormsg( xname, x, er )
    if(numel(x)<10)
        er = ['Numeric input argument ' xname '=[' num2str(x) '] ' er '.'];
    else
        er = ['Numeric input argument ' xname ' ' er '.'];
    end;

    
