% Convert integer to string of given length; improved version of int2str.  
%
% Pads string with zeros on the left.  If input n is an array, output is a cell array of
% strings of the same dimension as n.
% 
% INPUTS
%   n           - integer to convert to string
%   ndigits     - minimum number of digits to use
%
%
% OUTPUTS
%   nstr    - string representation of n (or cell array of strings in n is an array)
%
% EXAMPLE
%   s = int2str2( 3, 3 )
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also INT2STR

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function nstr = int2str2( n, ndigits )
    if( nargin<2 ) ndigits=0; end;

    nel = numel( n );
    negvals=(n<0); n=abs(n);
    if( nel==1 ) % for a single int
        nstr = num2str( n );
        if( ndigits > size(nstr,2) ) 
            nstr = [repmat( '0', 1, ndigits-size(nstr,2) ), nstr]; 
        end;
        if(negvals) nstr=['-' nstr]; end;
    else % for array of ints
        nstr = cell(size(n));
        for i=1:nel
            nstr{i} = num2str( n(i) );
            if( ndigits > size(nstr{i},2) ) 
                nstr{i} = [repmat( '0', 1, ndigits-size(nstr{i},2) ), nstr{i}]; 
            end;
            if(negvals(i)) nstr{i}=['-' nstr{i}]; end;
        end;
    end;
