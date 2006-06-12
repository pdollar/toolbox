% Used to shrink a multidimensional array I by integer amount.
%
% ratios specifies the block dimensions.  For example, ratios=[2 3 4] shrinks a 3
% dimensional array I by a factor of 2 along the first dimension, 3 along the secong and 4
% along the third.  ratios must be strictly positive integers.  A value of 1 means no
% shrinking is done along a given dimension. 
%
% Can handle very large arrays in a memory efficient manner.
% All the work is done by localsum_block.
%
% INPUTS
%   I       - k dimensional input array 
%   ratios  - k element vector of shrinking factors
%
% OUTPUTS
%   I   - shrunk version of input
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also IMRESIZE, LOCALSUM_BLOCK

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = imshrink( I, ratios )
    siz = size(I);  nd = ndims(I);
    while( length(ratios)>nd && ratios(end)==1 ) ratios=ratios(1:end-1); end;
    [ratios,er] = checknumericargs( ratios, [1 nd], 0, 2 ); error(er);

    % trim I to have integer number of blocks
    ratios = min(ratios,siz); siz = siz - mod( siz, ratios ); 
    if (~all( siz==size(I))) I = arraycrop_full( I, ones(1,nd), siz ); end;

    % if memory is large, recursively call on subparts and recombine
    if( prod(siz)*8e-6 > 200 ) % set max at 200MB, splits add overhead
        d = randint(1,1,[1 nd]);  nblocks = siz(d)/ratios(d);
        if( nblocks==1 ) I = imshrink( I, ratios ); return; end;
        midblock = floor(nblocks/2) * ratios(d);
        inds = {':'}; inds = inds(:,ones(1,nd));       
        inds1 = inds; inds1{d}=1:midblock;
        inds2 = inds; inds2{d}=midblock+1:siz(d);
        I1 = imshrink( I(inds1{:}), ratios ); 
        I2 = imshrink( I(inds2{:}), ratios ); 
        I = cat( d, I1, I2 ); return;
    end
    
    % run localsum_block then divide by prod( ratios )
    classname = class( I );
    I = double(I);
    I = localsum_block( I, ratios );
    I = I * (1/prod( ratios ));
    I = feval( classname, I );
        
        
    

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% SLOW / BROKEN - gaussian version of above    
% gauss controls whether the smoothing is done by a gaussian or
% averaging window.  Using an averaging window (gauss==0) is equivalent to
% dividing the array into non-overlapping cube shaped blocks.  Using a
% gaussian is equivalent to using slightly overlapping elliptical blocks.
% In this case the standard deviations of the gaussians are automatically
% determined from ratios.  NOTE: sigmas are set to ratios/2/1.6.  Is this ideal?
%
% The array is first smoothed, then it is subsampled.  An equivalent way to
% think of this operation is that the array is divided into a series of
% blocks (with minimal or no overlap), and then each block is replaced by
% its average.   
%        
%     if(gauss)
%         % get smoothed version of I
%         sigmas = ratios/2 / 1.6; sigmas(ratios==1)=0; %is this an ideal value of sigmas?
%         I = gauss_smooth( I, sigmas, 'full' );
%         I = arraycrop2dims( I, siz-ratios+1 );
% 
%         % now subsample smoothed I
%         sizsum = size(I);
%         extract={}; for d=1:nd extract{d}=1:ratios(d):sizsum(d); end;
%         I = I( extract{:} ); 
%     end
