% Applies nonmaximal suppression on an image of arbitrary dimension.
%
% nonmaxsupr( I, ... ) returns the pixel location and values of local maximums - that is a
% location is returned only if it has a value greater then or equal to all pixels in the
% surrounding window of size radii. I can be smoothed first to make method more robust.
% The first output is an array of the subscript locations of maximal values in I and the
% second output contains the corresponding maximal values.  One can convert subs/vals back
% to an array representation using imsubs2array. Note that values are suppressed iff there
% are strictly greater values in the neighborhood.  Hences nonmaxsupr(ones(10),5) would
% not suppress any values.
%
% INPUTS 
%   I       - matrix to apply nonmaxsupr to
%   radii   - suppression window dimensions 
%   thresh  - [optional] minimum value below which not to look for maxes
%   maxn:   - [optional] return at most maxn of the largest vals 
%
% OUTPUTS
%   subs    - subscripts of non-suppressed point locations (n x d) 
%   vals    - values at non-suppressed point locations (n x 1)
%
% EXAMPLE
%   % example 1
%   G = filter_gauss_nD( [25 25], [13,13], 3*eye(2), 1 );
%   siz=[11 11]; G = filter_gauss_nD( siz, (siz+1)/2, eye(2), 1 ); 
%   [subs,vals] = nonmaxsupr( G, 1, eps );
%   figure(2); im( imsubs2array( subs, vals, siz ) );
%   [subs,vals] = nonmaxsupr_list( ind2sub2(siz,(1:prod(siz))'), G(:)',1 );
%   figure(3); im( imsubs2array( subs, vals, siz ) );
%   % example 2
%   siz=[30 30]; I=ones(siz); I(22,23)=I(22,23)+3;  
%   I(12,23)=I(12,23)+5; I(7,1)=I(7,1)-.5; figure(1); im(I); 
%   r=3; supr_eq = 1; maxn=[]; thresh=eps; 
%   [subs,vals] = nonmaxsupr(I,r,thresh,maxn); 
%   figure(2); im( imsubs2array( subs, vals, siz ) ); 
%   [subs,vals] = nonmaxsupr_window(subs,vals,[1 1]+6,siz-6);
%   figure(3); im( imsubs2array( subs, vals, siz ) ); 
%   [subs2,vals2] = nonmaxsupr_list( ind2sub2(siz,(1:prod(siz))'), ...
%                                            I(:)',r,thresh,maxn,supr_eq );
%   figure(4); im( imsubs2array( subs2, vals2, siz ) );
%
% DATESTAMP
%   05-May-2006  2:00pm
%
% See also IMSUBS2ARRAY, NONMAXSUPR_LIST, NONMAXSUPR_WINDOW

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 

function [subs,vals] = nonmaxsupr( I, radii, thresh, maxn )
    siz = size(I);  nd = ndims(I);  
     
    %%% default values [error checking done by nlfilter_max]
    if( nargin<3 || isempty(thresh)) thresh=min(I(:))-eps; end;
    if( nargin<4 || isempty(maxn)) maxn = 0; end;
    
    %%% all the work is really done by nlfilter_max.m
    IR = nlfilt_sep( I, 2*radii+1, 'same', @rnlfilt_max );   
    suprlocs = (I < IR) | (I <= thresh);
    
    %%% create output accordingly
    subs = find( suprlocs==0 );  vals = I( subs );
    [vals,order] = sort(-vals); vals=-vals; subs=subs(order);
    if( ~isempty(maxn) && maxn>0 && maxn<length(vals) )     
        subs = subs( 1:maxn ); vals = vals( 1:maxn ); 
    end
    subs = ind2sub2(size(I),subs);
    

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OLD VERSION - worked by finding the largest value in I, and suppressing
% values around it.  If maxn was small, or radii were very large, then only
% a few such operations would be required, and the code would be extremely
% fast.  Unfortunately in general it is O(n^2), and the code above is
% cleaner and much faster.
% function varargout = nonmaxsupr_old( I, radii, thresh, maxn, suprval )
%     siz = size(I);  nd = ndims(I);  minI = min(I(:)); 
%      
%     %%% default values [error checking done by nlfilter_max]
%     if (nargin<3 || isempty(thresh)) thresh=minI; end;
%     if (nargin<4) maxn = prod(siz); end;
%     if (nargin<5) suprval = minI; end;
%     if (thresh<=minI) thresh = minI; end;
%     
%     %%% convert to int32.  First might need to normalize I so it falls in
%     %%% range of int32 and so that it has only integer values. 
%     classname = class(I);  if( ~strcmp(classname,'int32') )
%         if (strcmp(classname,'single')) I = double(I); end;
%         if (strcmp(classname,'double')) maxI=max(abs(I(:))); else maxI=max(I(:)); end;
%         int32max = 2^31-1;  if( strcmp(classname,'double') || maxI > int32max )
%             if( ~strcmp(classname,'double') ) I=double(I); maxI=double(maxI); end;
%             convertratio = int32max / maxI;  I = I * convertratio;
%             suprval = suprval * convertratio;
%             thresh = thresh * convertratio;
%         else convertratio = 1;  end
%         I = int32(I); 
%         suprval=int32(suprval);
%         thresh=int32(thresh);
%     end; Iorig=I;
%     
%     %%% find maxes [MAIN LOOP]
%     Ibig = arraycrop2dims( I, siz+2*radii, minI );
%     sizbig = size(Ibig); IS = Ibig;  subs = [];  vals = [];  
%     nmaxes = 0; while( nmaxes < maxn )
% 
%         % get max nonsuppressed value and window around it
%         [v,ind] = max(IS(:)); 
%         if (v <= thresh) break; end;
%         sub = ind2sub2( sizbig, ind );  
%         for d=1:nd window_bounds{d} = sub(d)-radii(d):sub(d)+radii(d); end;
%         
%         % store v if it is biggest value in window
%         W = Ibig( window_bounds{:} );  w = max(W(:)); 
%         if( v==w ) subs = [subs; sub]; vals = [vals; v]; nmaxes = nmaxes + 1; end
%         
%         % suppress all values in that window regardless
%         IS( window_bounds{:} ) = minI;
%     end 
%     n = size( subs, 1 ); if (n>0) subs = subs - repmat( radii, [n,1] ); end;
%     
%     
%     %%% convert subs/vals to image format
%     if( nargout~=2 )
%         inds = sub2ind2( siz, subs );
%         IS = repmat( suprval, siz );
%         IS( inds ) = vals;
%     end;
%     
%     
%     %%% create output [possibly converting back to original type]
%     if( nargout==2 )    
%         if( ~strcmp(classname,'int32') )
%             if( convertratio~=1 ) vals = double(vals) / convertratio; end;
%             vals = feval( classname, vals );
%         end;    
%         varargout = {subs,vals};
%     else
%         if( ~strcmp(classname,'int32') )
%             if( convertratio~=1 ) IS = double(IS) / convertratio; end;
%             IS = feval( classname, IS );
%         end;    
%         varargout = {IS};
%     end    
