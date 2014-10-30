function Y = num2strs( X, varargin )
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
%
% Piotr's Computer Vision Matlab Toolbox      Version 1.5
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

Y = cell(size(X));
for i=1:numel(X)
  Y{i} = num2str( X(i), varargin{:} );
end
