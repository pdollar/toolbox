function B = fevalArrays( A, fHandle, varargin )
% Used to apply the same operation to a stack of array elements.
%
% The only constraint on the function specified in fHandle is that given
% two differrent input arrays a1 and a2, if a1 and a2 have the same
% dimensions then the outputs b1 and b2 must have the same dimensions. For
% long operations shows progress information.
%
% A can have arbitrary dimension.  Suppose A has size d1 x d2 ... x dn.
% Then for the purpose of this function A has dn elements, where
% A(:,:,...,i) is the ith element.  This function then applies the
% operation in fHandle, with paramters given in varargin, to each element
% in A. The results are returned in the array B, of size f1 x f2 x ... x fk
% x dn.  Each of the n element of B of the form B(:,:,...,i) is the the
% result of applying fHandle to A(:,:,...,i).  A may also be a cell array,
% see the last example.
%
% A limitation of fevalArrays is that it does not pass state information
% to fHandle.  For example, fHandle may want to know how many times it's
% been called.  This can be overcome by saving state information inside
% fHandle using 'persistent' variables.  For an example see imwrite2.
%
% USAGE
%  B = fevalArrays( A, fHandle, varargin )
%
% INPUTS
%  A        - input array
%  fHandle  - operation to apply to each 'element' of A
%  params   - [varargin] parameters for each operation specified by fHandle
%
% OUTPUTS
%  B        - output array
%
% EXAMPLE
%  B = fevalArrays( A, @rgb2gray );      % where A is MxNx3xR
%  B = fevalArrays( A, @imresize, .5 );  % where A is MxNxR
%  B = fevalArrays( A, @imNormalize );   % where A has arbitrary dims
%  B = fevalArrays( A, @(x) {imresize(x{1},.5)} ); % A is cell array
%
% See also FEVALIMAGES, FEVALMATS, ARRAYFUN
% IMWRITE2, PERSISTENT, TICSTATUS, 
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

nd = ndims(A);  siz = size(A);  n = siz(end);
indsA = {':'}; indsA = indsA(ones(nd-1,1));

ticId = ticStatus('fevalArrays',[],60);
for i=1:n
  % apply fHandle to each element of A
  b = feval( fHandle, A(indsA{:},i), varargin{:} );
  if( i==1 )
    ndb = ndims(b);
    if(ndb==2 && size(b,2)==1); ndb=1; end
    onesNdb = ones(1,ndb);
    B = repmat( b, [onesNdb,n] );
    indsB = {':'}; indsB = indsB(onesNdb);
  else
    B(indsB{:},i) = b;
  end;
  tocStatus( ticId, i/n );
end
