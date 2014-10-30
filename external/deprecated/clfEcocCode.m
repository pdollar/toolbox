function [C,nbits] = clfEcocCode( k )
% Generates optimal ECOC codes when 3<=nclasses<=7.
%
% USAGE
%  [C,nbits] = clfEcocCode( k )
%
% INPUTS
%  k      - number of classes
%
% OUTPUTS
%  C      - code
%  nbits  - number of bits
%
% EXAMPLE
%
% See also CLFECOC
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( k<3 || k>7 )
  error( 'method only works if k is small: 3<=k<=7'); end

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
