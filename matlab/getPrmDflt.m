% Helper to set default values (if not already set) of parameter struct.
%
% Takes a struct prm and a list of 'name'/default pairs, and for each
% 'name' for which prm has no value (prm.(name) is not a field)
% getPrmDflt assigns the given default value. If default value for
% variable 'name' is 'REQ', and prm.name is not a field, an error is
% thrown. See example below for usage details.
%
% USAGE
%  prm = getPrmDflt( prm, dfs )
%  [ param1 param2 ] = getPrmDflt({'param1' param1 'param2' param2},dfs)
%
% INPUTS
%  prm    - parameters struct, {parameter struct} (typically varargin)
%           or cell in the form:
%           {'name1',default1,'name2',default2,...}
%  dfs    - same format as above for prm
%
% OUTPUTS
%  prm    - updated parameters struct
%
% EXAMPLE
%  dfs = { 'x','REQ', 'y',0, 'z',[], 'eps',1e-3 };
%  prm.x = 1;  prm = getPrmDflt( prm, dfs )
%
%  dfs = { 'x','REQ', 'y',0, 'z',[], 'eps',1e-3 };
%  prm.x = 1;  [ x y z eps ] = getPrmDflt( prm, dfs )
%
% See also

% Piotr's Image&Video Toolbox      Version NEW
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

function varargout = getPrmDflt( prm, dfs )

if (mod(length(dfs),2)~=0); error('odd number of default parameters'); end

if iscell(prm)
  if length(prm)==1
    if ~isstruct(prm{1}); error('prm must be a struct or a cell');
    else prm = prm{1};
    end
  else
    if(mod(length(prm),2)~=0); error('odd number of parameters in prm');
    else prm = cell2struct( prm(2:2:end), prm(1:2:end), 2 );
    end
  end
else
  if(~isstruct(prm)); error('prm must be a struct or a cell'); end
end

if iscell(dfs)
  if length(dfs)==1
    if ~isstruct(dfs{1}); error('dfs must be a struct or a cell');
    else dfsField = fieldnames( dfs{1} ); dfsVal = struct2cell( dfs{1} );
    end
  else
    if(mod(length(dfs),2)~=0); error('odd number of parameters in dfs');
    else dfsField = dfs(1:2:end); dfsVal = dfs(2:2:end);
    end
  end
else
  if(~isstruct(dfs)); error('dfs must be a struct or a cell'); end
  dfsField = fieldnames( dfs ); dfsVal = struct2cell( dfs );
end

toDo = find( ~isfield( prm, dfsField ) );
if size(toDo,1)~=1; toDo = toDo'; end

for i = toDo
  if(strcmp('REQ',dfsVal{i}))
    error(['Required field ''' dfsField{i} ''' not specified.'] );
  else
    prm.(dfsField{i}) = (dfsVal{i});
  end
end

if nargout==1
  varargout(1) = {prm};
else
  varargout=cell(1,nargout);
  for i=1:nargout
    varargout(i)={prm.(dfsField{i})};
  end
end
