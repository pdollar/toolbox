% Fast routine for box filtering.
%
% Same effect as calling 'C=convn( I, ones(dims), shape)', except more efficient.
% Computes local sums by using running sums.
%
% INPUTS
%   I       - matrix to compute sum over
%   dims    - size of volume to compute sum over 
%   shape   - [optional] 'valid', 'full', or 'same', see conv2 help
%
% OUTPUTS
%   C       - matrix of sums
%
% EXAMPLE
%   A = rand(20); dim=31; shape='valid'; 
%   B = localsum(A,dim,shape); 
%   C = conv2(A,ones(dim),shape); 
%   diff=B-C; sum(abs(diff(:)))
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also LOCALSUM_BLOCK

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = localsum( I, dims, shape )
    if( nargin<3 ) shape='full'; end;
    I = nlfilt_sep( I, dims, shape, @rnlfilt_sum );

    
    
    
    
%%%%%%%%%%%%%%% OLD SLOWER VERSION THAT USED cumsum    
%    if (nd==2) %%% 2D (faster version)
%         m = dims(1); n = dims(2);
%         mX = siz(1); nX = siz(2);
%         C = [zeros(m,nX+2*n-1);
%              zeros(mX,n) X zeros(mX,n-1);
%              zeros(m-1,nX+2*n-1)];
%         C = cumsum(C,1);  C = C(1+m:end,:)-C(1:end-m,:);
%         C = cumsum(C,2);  C = C(:,1+n:end)-C(:,1:end-n);
%         
%     else %%% ARBITRARY DIMENSION
%         C = X; clear X;
%         inds = {':'}; inds = inds(:,ones(1,nd));       
%         for d=1:nd
%             siz1 = size(C); siz1(d)=dims(d);  
%             siz2 = size(C); siz2(d)=dims(d)-1;
%             C = cat(d, zeros(siz1), cat(d, C, zeros(siz2)) );
%             C = cumsum(C,d);
%         
%             inds1 = inds; inds1{ d } = 1+dims(d):size(C,d);
%             inds2 = inds; inds2{ d } = 1:size(C,d)-dims(d);
%             C = C(inds1{:})-C(inds2{:});                
%         end
%     end
%     
%     % crop to size
%     if(strcmp(shape,'valid'))
%         if( any(siz<dims) ) error('No valid area for localsum'); end;
%         if (nd==2) 
%             deltas = (dims-1); 
%             C = C( 1+deltas(1):end-deltas(1), 1+deltas(2):end-deltas(2) );
%         else
%             C = arraycrop2dims( C, siz-dims+1 );
%         end
%     elseif(strcmp(shape,'same'))
%         C = arraycrop2dims( C, siz );
%     elseif(~strcmp(shape,'full'))
%         error('unknown shape');
%     end
