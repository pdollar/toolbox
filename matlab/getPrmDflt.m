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

if(mod(length(dfs),2)~=0); error('odd number of default parameters'); end

if (iscell(prm)) && (nargout~=1)
  if(mod(length(prm),2)~=0); error('odd number of parameters'); end

  varargout=dfs(2:2:end);

  for i=1:2:length(dfs)
    j = 0;
    for k=1:2:length(prm)
      if strcmp( dfs{i}, prm{k} )
        j=k; break;
      end
    end
    
    if j==0
      if strcmp('REQ',dfs{i+1})
        error(['Required field ''' dfs{i} ''' not specified.'] );
      end
    else
      varargout{(i+1)*0.5} = prm{j+1};
    end
  end
else
  if (iscell(prm)); prm = cell2struct( prm(2:2:end), prm(1:2:end), 2 ); end
  if(~isstruct(prm)); error('prm must be a struct'); end

  toDo = isfield( prm, dfs(1:2:end) );
  for i=find(~toDo)
    if(strcmp('REQ',dfs{2*i}))
      error(['Required field ''' dfs{i} ''' not specified.'] );
    else
      prm.(dfs{2*i-1})=dfs{2*i};
    end
  end

  if nargout==1
    varargout(1) = {prm};
  else
    try
      varargout = struct2cell( ordedrfields( prm, dfs ) );
    catch
      varargout=cell(1,nargout);
      for i=1:2:length(dfs)
        varargout((i+1)/2)={prm.(dfs{i})};
      end
    end
  end
end
