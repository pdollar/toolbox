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
%  prm    - parameters struct or cell (in the form described below)
%  dfs    - cell of form {name1,default1,name2,default2,...}
%
% OUTPUTS
%  prm    - updated parameters struct
%
% EXAMPLE
%  dfs = { 'x','REQ', 'y',0, 'z',[], 'eps',1e-3 };
%  prm.x = 1;  prm = getPrmDflt( prm, dfs )
%
% See also

% Piotr's Image&Video Toolbox      Version 2.0
% Copyright (C) 2007 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Liscensed under the Lesser GPL [see external/lgpl.txt]

function varargout = getPrmDflt( prm, dfs )

if (iscell(prm)); prm = cell2struct( prm(2:2:end), prm(1:2:end), 2 ); end
if(~isstruct(prm)); error('prm must be a struct'); end
if(mod(length(dfs),2)~=0); error('incorrect num dfs'); end

for i=1:2:length(dfs)
  if( ~isfield(prm,dfs{i}) || isempty(prm.(dfs{i})) )
    if(strcmp('REQ',dfs{i+1}))
      error(['Required field ''' dfs{i} ''' not specified.'] );
    else
      prm.(dfs{i})=dfs{i+1};
    end
  end
end
if nargout==1; varargout(1)={prm}; return; end
varargout=cell(1,nargout);
for i=1:2:length(dfs)
  varargout((i+1)/2)={prm.(dfs{i})};
end
