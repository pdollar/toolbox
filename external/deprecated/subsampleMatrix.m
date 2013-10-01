function [X,keeplocs] = subsampleMatrix( X, maxMegs )
% Samples elements of X so result uses at most maxMegs megabytes of memory.
%
% If X is m+1 dimensional, say of size [d1 x d2 x...x dm x n], each [d1 x
% d2 x...x dm] element is treated as one observation, and X is treated as
% having n such observations.  The subsampling then occurs over the last
% dimension n.  Different types of arrays require different amounts of
% memory.  Each double requries 8 bytes of memory, hence an array with
% 1.024 million elements of type double requires 8MB memory.  Each uint8
% requires 1 byte, so the same size array would require 1MB.  Note that
% when saved to .mat files arrays may take up more or less memory (due to
% compression, etc.)
% Different from Matlab randsample !
%
% Note, to see how much memory a variable x is using in memory, use:
%  s=whos('x'); mb=s.bytes/2^20
%
% USAGE
%  [X,keeplocs] = subsampleMatrix( X, maxMegs )
%
% INPUTS
%  X         - [d1 x ... x dm x n], treated as n [d1 x ... x dm] elements
%  maxMegs   - maximum number of megs Xsam is allowed to take up
%
% OUTPUTS
%  Xsam      - [d1 x ... x dm x n'] (n'<=n) Xsam=X(:,..,:,keeplocs);
%  keeplocs  - vector of indicies kept from X;
%
% EXAMPLE
%  % Xsam should have size: 1024xround(1024/10)
%  X = uint8(ones(2^10,2^10));
%  Xsam = subsampleMatrix( X, 1/10 );
%  % Xsam should have size: 100x10x~(1000/8)
%  X = rand(100,10,1000);
%  Xsam = subsampleMatrix( X, 1 );
%
% See Also
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

siz = size( X );  nd = ndims(X);
inds={':'};  inds=inds(:,ones(1,nd-1));
n=siz(end);   m=prod(siz(1:end-1));

% get the number of elements of X that fit per meg
s=whos('X'); nbytes=s.bytes/numel(X);
elsPerMeg = 2^20 / nbytes / m;

% sample if necessary
memUsed = n / elsPerMeg;
if( memUsed > maxMegs )
  nKeep = max(1,round(maxMegs*elsPerMeg));
  keeplocs = randperm(n);
  keeplocs = keeplocs(1:nKeep);
  X = X( inds{:}, keeplocs );
end
