% Helper to set default values (if not already set) of parameter struct.
% 
% Takes a struct prm and a list of name/default pairs and for each name
% that prm has no value (prm.(name) is not a field) assigns the given
% default value.  Useful helper; see example below for usage details. 
%
% USAGE
%  prm = getParamDefaults( prm, dfs ) 
%
% INPUTS
%  prm    - parameters struct
%  dfs    - cell of form {name1,default1,name2,default2,...}
%
% EXAMPLE
%  prm.x = 1; 
%  dfs = { 'x',0, 'y',0, 'z',[], 'eps',1e-3 };
%  prm = getParamDefaults( prm, dfs )
%
% DATESTAMP
%   19-Jan-2007  12:00am

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 

function prm = getParamDefaults( prm, dfs ) 
  if(mod(length(dfs),2)~=0); error('incorrect num dfs'); end;
  for i=1:2:length(dfs)
    if(~isfield2(prm,dfs{i},1)); prm.(dfs{i})=dfs{i+1}; end; 
  end