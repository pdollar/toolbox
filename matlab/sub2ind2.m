% Improved version of sub2ind.
% 
% Almost the same as sub2ind, except always returns only a single output that contains all
% the subscript locations.  Also handles multiple linear subscripts at the same time more
% conviniently then matlab's version.  
%
% See help for sub2ind for more info.
%
% INPUTS
%   siz     - size of array into which sub is an index
%   sub     - sub(i,:) is the ith set of subscripts into the array.
% 
% OUTPUTS   
%   ind     - linear index (or vector of indicies) into given array
%
% EXAMPLE
%   ind = sub2ind2( [10,10], [10 2] );
%   ind = sub2ind2( [10,10], [9 2; 10 2] );
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also SUB2IND, IND2SUB2

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function ind = sub2ind2(siz,sub)
    if(isempty(sub)) ind=[]; return; end;
    n = length(siz);  nsub = size(sub,1);
    
    % error check (comment out to speed up substantially)
    if( size(sub,2)~=n ) 
        error('Incorrect dimension for sub'); end;
    %for i = 1:n if( any( sub(:,i)<1 ) || any( sub(:,i)>siz(i) ) )
    %        error('subscript out of range'); end; end;
    
    k = [1 cumprod(siz(1:end-1))];
    ind = 1;
    for i = 1:n,
      ind = ind + (sub(:,i)-1)*k(i);
    end
    
