function nstr = int2str2( n, nDigits )
% Convert integer to string of given length; improved version of int2str.
%
% Pads string with zeros on the left.  For integers similar to
%  sprintf( '%03i', n ); %for nDigits=3
% If input n is an array, output is a cell array of strings of the same
% dimension as n.  Works also for non integers (pads to given length).
%
% USAGE
%  nstr = int2str2( n, [nDigits] )
%
% INPUTS
%  n        - integer to convert to string
%  nDigits  - [0] minimum number of digits to use
%
% OUTPUTS
%  nstr     - string repr. of n (or cell array of strings if n is array)
%
% EXAMPLE
%  s = int2str2( 3, 3 ) % s='003'
%
% See also INT2STR
%
% Piotr's Image&Video Toolbox      Version 1.5
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<2 ); nDigits=0; end

nel = numel( n );
negvals=(n<0); n=abs(n);
if( nel==1 ) % for a single int
  nstr = num2str( n );
  if( nDigits > size(nstr,2) )
    nstr = [repmat( '0', 1, nDigits-size(nstr,2) ), nstr];
  end;
  if(negvals); nstr=['-' nstr]; end

else % for array of ints
  nstr = cell(size(n));
  for i=1:nel
    nstr{i} = num2str( n(i) );
    if( nDigits > size(nstr{i},2) )
      nstr{i} = [repmat( '0', 1, nDigits-size(nstr{i},2) ), nstr{i}];
    end;
    if(negvals(i)); nstr{i}=['-' nstr{i}]; end
  end
end
