function I = imShrink( I, ratios )
% Used to shrink a multidimensional array I by integer amount.
%
% ratios specifies block dimensions. For example, ratios=[2 3 4] shrinks a
% 3 dimensional array I by a factor of 2 along the first dimension, 3 along
% the secong and 4 along the third. ratios must be positive integers. A
% value of 1 means no shrinking is done along a given dimension. Can handle
% very large arrays in a memory efficient manner. All the work is done by
% localSum with the 'block' shape flag. Note that for downsampling by 2x or
% 4x for 2D arrays imResample is much faster.
%
% USAGE
%  I = imShrink( I, ratios )
%
% INPUTS
%  I       - k dimensional input array
%  ratios  - k element int vector of shrinking factors
%
% OUTPUTS
%  I       - shrunk version of input
%
% EXAMPLE
%  load trees; I=ind2gray(X,map);
%  I2 = imShrink( I, [2 2] );
%  figure(1); im(I); figure(2); im(I2);
%
% See also imResample, localSum
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.00
% Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( all(ratios==1) ); return; end
siz = size(I);  nd = ndims(I);
while( length(ratios)>nd && ratios(end)==1 ); ratios=ratios(1:end-1); end
[ratios,er] = checkNumArgs( ratios, [1 nd], 0, 2 ); error(er);

% trim I to have integer number of blocks
ratios = min(ratios,siz); siz = siz - mod( siz, ratios );
if (~all( siz==size(I))); I = arrayCrop( I, ones(1,nd), siz ); end

% if memory is large, recursively call on subparts and recombine
if( prod(siz)*8e-6 > 200 ) % set max at 200MB, splits add overhead
  d = randint2(1,1,[1 nd]);  nblocks = siz(d)/ratios(d);
  if( nblocks==1 ); I = imShrink( I, ratios ); return; end
  midblock = floor(nblocks/2) * ratios(d);
  inds = {':'}; inds = inds(:,ones(1,nd));
  inds1 = inds; inds1{d}=1:midblock;
  inds2 = inds; inds2{d}=midblock+1:siz(d);
  I1 = imShrink( I(inds1{:}), ratios );
  I2 = imShrink( I(inds2{:}), ratios );
  I = cat( d, I1, I2 ); return;
end

% run localSum then divide by prod( ratios )
classname = class( I );
I = double(I);
I = localSum( I, ratios, 'block' );
I = I * (1/prod( ratios ));
I = feval( classname, I );

% SLOW / BROKEN - gaussian version of above gauss controls whether the
% smoothing is done by a gaussian or averaging window.  Using an averaging
% window (gauss==0) is equivalent to dividing the array into
% non-overlapping cube shaped blocks.  Using a gaussian is equivalent to
% using slightly overlapping elliptical blocks. In this case the standard
% deviations of the gaussians are automatically determined from ratios.
% NOTE: sigmas are set to ratios/2/1.6.  Is this ideal?
%
% The array is first smoothed, then it is subsampled.  An equivalent way to
% think of this operation is that the array is divided into a series of
% blocks (with minimal or no overlap), and then each block is replaced by
% its average.
%
% if(gauss)
%   % get smoothed version of I
%   sigmas = ratios/2 / 1.6; sigmas(ratios==1)=0; %is this ideal sigmas?
%   I = gaussSmooth( I, sigmas, 'full' );
%   I = arrayToDims( I, siz-ratios+1 );
%
%   % now subsample smoothed I
%   sizsum = size(I);
%   extract={}; for d=1:nd extract{d}=1:ratios(d):sizsum(d); end;
%   I = I( extract{:} );
% end
