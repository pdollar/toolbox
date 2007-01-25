% Helper to set default values (if not already set) of parameter struct.
% 
% Takes a struct prm and a list of 'name'/default pairs, and for each
% 'name' for which prm has no value (prm.(name) is not a field)
% getParamDefaults assigns the given default value. If default value for
% variable 'name' is 'REQ', and prm.name is not a field, an error is
% thrown. See example below for usage details.  
%
% USAGE
%  prm = getParamDefaults( prm, dfs ) 
%
% INPUT
%  prm    - parameters struct
%  dfs    - cell of form {name1,default1,name2,default2,...}
%
% OUTPUT 
%  prm    - updated parameters struct
%
% EXAMPLE
%  prm.x = 1; 
%  dfs = { 'x','REQ', 'y',0, 'z',[], 'eps',1e-3 };
%  prm = getParamDefaults( prm, dfs )
% 
% DATESTAMP
%   24-Jan-2007  5:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 

function prm = getParamDefaults( prm, dfs ) 
  if(mod(length(dfs),2)~=0); error('incorrect num dfs'); end;
  for i=1:2:length(dfs)
    if(~isfield2(prm,dfs{i},1)); 
      if(strcmp('REQ',dfs{i+1}))
        error(['Required field ' dfs{i} ' not specified.'] );
      else
        prm.(dfs{i})=dfs{i+1}; 
      end;
    end
  end