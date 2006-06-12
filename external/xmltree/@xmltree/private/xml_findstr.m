function k = xml_findstr(s,p,i,n)
%XML_FINDSTR Find one string within another
%   K = XML_FINDSTR(TEXT,PATTERN) returns the starting indices of any 
%   occurrences of the string PATTERN in the string TEXT.
%
%   K = XML_FINDSTR(TEXT,PATTERN,INDICE) returns the starting indices 
%   equal or greater than INDICE of occurrences of the string PATTERN
%   in the string TEXT. By default, INDICE equals to one.
%
%   K = XML_FINDSTR(TEXT,PATTERN,INDICE,NBOCCUR) returns the NBOCCUR 
%   starting indices equal or greater than INDICE of occurrences of
%   the string PATTERN in the string TEXT. By default, INDICE equals
%   to one and NBOCCUR equals to Inf.
%
%   Examples
%       s = 'How much wood would a woodchuck chuck?';
%       xml_findstr(s,' ') returns [4 9 14 20 22 32]
%       xml_findstr(s,' ',10) returns [14 20 22 32]
%       xml_findstr(s,' ',10,1) returns 14
%
%   See also STRFIND, FINDSTR

%   Guillaume Flandin
%   Copyright 2002 INRIA Sophia Antipolis
%   $Revision: 1.0 $  $Date: 2002/04/10 22:50:32 $
%   Implemented in a MATLAB mex file.

error(sprintf('Missing MEX-file: %s', mfilename));
