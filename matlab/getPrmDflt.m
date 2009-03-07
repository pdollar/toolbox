function varargout = getPrmDflt( prm, dfs, checkExtra )
% Helper to set default values (if not already set) of parameter struct.
%
% Takes input parameters and a list of 'name'/default pairs, and for each
% 'name' for which prm has no value (prm.(name) is not a field or 'name'
% does not appear in prm list), getPrmDflt assigns the given default
% value. If default value for variable 'name' is 'REQ', and value for
% 'name' is not given, an error is thrown. See below for usage details.
%
% USAGE (nargout==1)
%  prm = getPrmDflt( prm, dfs, [checkExtra] )
%
% USAGE (nargout>1)
%  [ param1 ... paramN ] = getPrmDflt( prm, dfs, [checkExtra] )
%
% INPUTS
%  prm          - param struct or cell of form {'name1' v1 'name2' v2 ...}
%  dfs          - cell of form {'name1' def1 'name2' def2 ...}
%  checkExtra   - [0] if 1 throw error if prm contains params not in dfs
%
% OUTPUTS (nargout==1)
%  prm    - parameter struct with fields 'name1' through 'nameN' assigned
%
% OUTPUTS (nargout>1)
%  param1 - value assigned to parameter with 'name1'
%   ...
%  paramN - value assigned to parameter with 'nameN'
%
% EXAMPLE
%  dfs = { 'x','REQ', 'y',0, 'z',[], 'eps',1e-3 };
%  prm = getPrmDflt( struct('x',1,'y',1), dfs )
%  [ x y z eps ] = getPrmDflt( {'x',2,'y',1}, dfs )
%
% See also INPUTPARSER
%
% Piotr's Image&Video Toolbox      Version 2.20
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if (mod(length(dfs),2)~=0); error('odd number of default parameters'); end
if nargin<=2; checkExtra = 0; end

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

if checkExtra
  prmName = fieldnames(prm);
  for i = 1 : length(prmName)
    if ~any(strcmp( prmName{i}, dfsField ))
      error( [ 'parameter ' prmName{i} ' is not a valid parameter.' ] );
    end
  end
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
