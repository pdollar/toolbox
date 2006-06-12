% Improved version of ind2sub.
% 
% Almost the same as ind2sub, except always returns only a single output that contains all
% the index locations.  Also handles multiple linear indicies at the same time.
%
% See help for ind2sub for mor info.
%
% INPUTS
%   siz     - size of array into which ind is an index
%   ind     - linear index (or vector of indicies) into given array
% 
% OUTPUTS   
%   sub     - sub(i,:) is the ith set of subscripts into the array.
%
% EXAMPLE
%   sub = ind2sub2( [10,10], 20 )
%   sub = ind2sub2( [10,10], [19 20] )
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also IND2SUB, SUB2IND2

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function sub = ind2sub2(siz,ind)
    if( any(ind>prod(siz)) ) 
        error('index out of range'); end;

    % taken almost directly from ind2sub.m
    ind = ind(:);
    nd = length(siz);
    k = [1 cumprod(siz(1:end-1))];
    ind = ind - 1;
    for i = nd:-1:1
        sub(:,i) = floor(ind/k(i))+1;
        ind = rem(ind,k(i));
    end
