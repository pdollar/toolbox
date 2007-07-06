% Applies num2str to each element of an array X.
%
% USAGE
%  Y = num2strs( X, [varargin] )
%
% INPUTS
%  X           - array of number to convert to strings
%  varargin    - [] additional input to num2str
%
% OUTPUTS
%  Y           - cell array of strings
%
% EXAMPLE
%  Y = num2strs( [1.3 2.6; 3 11] )
%
% See also NUM2STR

% Piotr's Image&Video Toolbox      Version 1.03   PPD VR
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function Y = num2strs( X, varargin )

Y = cell(size(X));
for i=1:numel(X)
  Y{i} = num2str( X(i), varargin{:} );
end
