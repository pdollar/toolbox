function tf = isfield2( S, fs, isinit )
% Similar to isfield but also test whether fields are initialized.
%
% A more comprehensive test of what fields are present [and optionally
% initialized] in a stuct S.  fs is either a single field name or a cell
% array of field names.  The presence of all fields in fs are tested for in
% S, tf is true iif all fs are present. Additionally, if isinit==1, then tf
% is true iff every field fs of every element of S is nonempty (test done
% using isempty).
%
% USAGE
%  tf = isfield2( S, fs, [isinit] )
%
% INPUTS
%  S        - struct array
%  fs       - cell of string name or string
%  isinit   - [0] if true additionally test if all fields are initialized
%
% OUTPUTS
%  tf      - true or false, depending on results of above tests
%
% EXAMPLE
%  isfield2( struct('a',1,'b',2), {'a','b'}, 1 )
%
% See also ISFIELD
%
% Piotr's Computer Vision Matlab Toolbox      Version 2.10
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

tf = all( isfield(S,fs) );
if( ~tf || nargin<3 || ~isinit ); return; end

% now optionally check if fields are initialized
if( iscell(fs) )
  for i=1:length(fs)
    for j=1:numel(S)
      if( isempty(S(j).(fs{i})) ); tf=false; return; end;
    end;
  end;
else
  for j=1:numel(S)
    if( isempty(S(j).(fs)) ); tf=false; return; end;
  end;
end
