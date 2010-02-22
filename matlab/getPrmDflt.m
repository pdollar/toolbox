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
% Piotr's Image&Video Toolbox      Version 2.35
% Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if (mod(length(dfs),2)~=0); error('odd number of default parameters'); end
if nargin<=2; checkExtra = 0; end

% get the default values
dfsField = dfs(1:2:end); dfsVal = dfs(2:2:end);

% get the input parameters
if iscell(prm)
  if length(prm)==1
    if ~isstruct(prm{1}); error('prm must be a struct or a cell');
    else prmVal = struct2cell(prm{1}); prmField = fieldnames(prm{1});
    end
  else
    if(mod(length(prm),2)~=0); error('odd number of parameters in prm');
    else prmField = prm(1:2:end); prmVal = prm(2:2:end);
    end
  end
else
  if(~isstruct(prm)); error('prm must be a struct or a cell'); end
  prmVal = struct2cell(prm); prmField = fieldnames(prm);
end

% update the values to return
%[ disc dfsInd prmInd ] = intersect(dfsField, prmField );
% the above is slow so for loop ...
if checkExtra
  for i=1:length(prmField)
    ind = find(strcmp(prmField{i},dfsField));
    if isempty(ind)
      error( [ 'parameter ' prmField{1} ' is not a valid parameter.' ] );
    else
      dfsVal(ind) = prmVal(i);
    end
  end
else
  for i=1:length(prmField)
    dfsVal(strcmp(prmField{i},dfsField)) = prmVal(i);
  end
end

% check for missing values
cmpArray = strcmp('REQ',dfsVal);
if any(cmpArray)
  cmpArray = find(cmpArray);
  error(['Required field ''' dfsField(cmpArray(1)) ''' not specified.'] );
end

if nargout==1
  varargout(1) = {struct2cell(dfsField,dfsVal,2)};
else
  varargout = dfsVal;
end
