% [4D] Used to display R sets of filmstrips.
%
% INPUTS
%  I          - MxNxTxR or MxNx1xTxR or MxNx3xTxR array 
%  overlap    - amount of overlap between successive frames
%  delta      - amount to shift each successive frame upward
%  border     - width of black border around each frame
%
% EXAMPLE
%   load images;
%   F = filmstrips( videos(:,:,:,1:10), 5, 2, 3 ); 
%   figure(1); im(F);
%
% DATESTAMP
%   07-Oct-2005  5:00pm
%
% See also MONTAGES, FILMSTRIP

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function F = filmstrips( I, overlap, delta, border )
    nd = ndims(I); 
    if(~(nd==4 || nd==5 ))
        error( ['Incorrect number of dimensions: ' int2str(nd) ] );
    end;
    inds = {':'}; inds = inds(:,ones(1,nd-1));   
    n = size(I,nd); h = 1; nframes = size(I,nd-1);
    
    for( i=1:n )
        Fi = filmstrip( I(inds{:},i), overlap, delta, border );
        if( i==1 )
            sizFi = size(Fi);  nrows = sizFi(1);
            sizFi(1) = nrows*n - ((nframes-1)*delta-2*delta)*(n-1);
            F = ones( sizFi );
        end;
        Fc = F( h:(h+nrows-1), :  ); % ok even if F is 3D
        locs = (Fc==1);
        Fc( locs ) = Fi( locs );
        F( h:(h+nrows-1), :  ) = Fc;
        h = h + nrows - ((nframes-1)*delta-2*delta);
    end;
    
    
