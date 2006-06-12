% Generates optimal ECOC codes when 3<=nclasses<=7.
%
% INPUTS
%   nclasses - number of classes
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also CLF_ECOC

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [C,nbits] = clf_ecoc_code( k )
    if( k<3 || k>7 )
        error( 'method only works if k is small: 3<=k<=7'); end;

    % create C
    C = ones(k,2^(k-1));
    for i=2:k
        partw = 2^(k-i);  nparts = 2^(i-2);
        row = [zeros(1,partw) ones(1,partw)];
        row = repmat( row, 1, nparts );
        C(i,:) = row;
    end
    C = C(:,1:end-1);
    nbits = size(C,2);
    
    % alter C to have entries [-1,1]
    C(C==0)=-1;
    
