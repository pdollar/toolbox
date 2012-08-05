function ind = sub2ind2( siz, sub )
% Improved version of sub2ind.
%
% Almost the same as sub2ind, except always returns only a single output
% that contains all the subscript locations.  Also handles multiple linear
% subscripts at the same time more conveniently then matlab's version. See
% help for sub2ind for more info.
%
% USAGE
%  ind = sub2ind2( siz, sub )
%
% INPUTS
%  siz     - size of array into which sub is an index
%  sub     - sub(i,:) is the ith set of subscripts into the array.
%
% OUTPUTS
%  ind     - linear index (or vector of indicies) into given array
%
% EXAMPLE
%  ind = sub2ind2( [10,10], [10 2] )      % 20
%  ind = sub2ind2( [10,10], [9 2; 10 2] ) % 19, 20
%
% See also SUB2IND, IND2SUB2, SUBSTOARRAY
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if(isempty(sub)); ind=[]; return; end;
n = length(siz);

% error check (commented out to speed up substantially)
if( size(sub,2)~=n )
  error('Incorrect dimension for sub');
  % for i = 1:n; if( any( sub(:,i)<1 ) || any( sub(:,i)>siz(i) ) )
  %   error('subscript out of range'); end;
end

k = [1 cumprod(siz(1:end-1))];
ind = 1;
for i = 1:n; ind = ind + (sub(:,i)-1)*k(i); end
