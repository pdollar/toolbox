% Used to apply the same operation to a stack of array elements.
%
% The only constraint on the function specified in fhandle is that given two differrent
% input arrays a1 and a2, if a1 and a2 have the same dimensions then the outputs b1 and b2
% must have the same dimensions. For long operations shows progress information.
%
% A can have arbitrary dimension.  Suppose A has size d1 x d2 ... x dn. Then for the
% purpose of this function A has dn elements, where A(:,:,...,i) is the ith element.  This
% function then applies the operation in fhandle, with paramters given in varargin, to
% each element in A. The results are returned in the array B, of size f1 x f2 x ... x fk x
% dn.  Each of the n element of B of the form B(:,:,...,i) is the the result of applying
% fhandle to A(:,:,...,i).  A may also be a cell array, see the last example.
%
% This can be extremely useful.  Suppose A is an MxNxR collection of R MxN images.  Then
% "B = feval_arrays( A, @imresize, .5 )" resizes each of the R images in A by 1/2.  B has
% size M/2 x N/2 X R.  As another motivating example, suppose A is an MxNx3xR array of R
% MxN rgb images.  Then "B = feval_arrays( A, @rgb2gray )" converts each of the R color
% images to a grayscale image.  B has size M x N x R.
%
% A limitation of feval_arrays is that it does not pass state information to fhandle.  For
% example, fhandle may want to know how many times it's been called.  This can be overcome
% by saving state information inside fhandle using 'persistent' variables.  For an example
% see imwrite2. 
%
% INPUTS
%   A        - input array
%   fhandle  - operation to apply to each 'element' of A
%   params   - [varargin] parameters for each operation specified by fhandle
%
% OUTPUTS
%   B        - output array
%
% EXAMPLE
%   B = feval_arrays( A, @rgb2gray );      % where A is MxNx3xR
%   B = feval_arrays( A, @imresize, .5 );  % where A is MxNxR
%   B = feval_arrays( A, @imnormalize );   % where A has arbitrary dims
%   B = feval_arrays( A, @(x) {imresize(x{1},.5)} ); % resize each element in cell array
%
% DATESTAMP
%   25-Jan-2005  2:00pm
%
% See also FEVAL_IMAGES, IMWRITE2, PERSISTENT, TICSTATUS

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function B = feval_arrays( A, fhandle, varargin )
    nd = ndims(A);  siz = size(A); n = siz(end);  
    indsA = {':'}; indsA = indsA(ones(nd-1,1));

    ticstatusid = ticstatus('feval_arrays',[],60);
    for i=1:n
        % apply fhandle to each element of A
        b = feval( fhandle, A(indsA{:},i), varargin{:} );
        if (i==1) 
            ndb = ndims(b);  
            if(ndb==2 && size(b,2)==1) ndb=1; end;
            ones_ndb = ones(1,ndb);
            B = repmat( b, [ones_ndb,n] ); 
            indsB = {':'}; indsB = indsB(ones_ndb);
        else 
            B(indsB{:},i) = b;
        end;
        tocstatus( ticstatusid, i/n );
    end
    

    
    
    
    
    
    
    
    
    
    
