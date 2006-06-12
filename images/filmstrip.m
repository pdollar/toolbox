% [3D] Used to display a stack of T images as a filmstrip. 
%
% INPUTS
%  I          - MxNxT or MxNx1xT or MxNx3xT array (of bw or color images)
%  overlap    - amount of overlap between successive frames
%  delta      - amount to shift each successive frame upward
%  border     - width of black border around each frame
%
% EXAMPLE
%   load images;
%   F = filmstrip( video(:,:,1:15), 10, 2, 5 ); 
%   figure(1); im(F);
%
% DATESTAMP
%   07-Oct-2005  5:00pm
%
% See also MONTAGE2, FILMSTRIPS

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function F = filmstrip( I, overlap, delta, border )
    I = double(I); I = I/max(I(:));
        
    if( ndims(I)==3 ) % bw images
        I = padarray( I, [border border 0], 0, 'both' );
        [mrows,ncols,nframes] = size(I);
        siz = [mrows+delta*(nframes-1), nframes*ncols-overlap*(nframes-1)];
        F = ones( siz ) * double(max(I(:))); 
        row = 1; col = siz(2);
        for f=[nframes:-1:1]
            F( row:(row+mrows-1), (col-ncols+1):col ) = I(:,:,f);
            row = row + delta;
            col = col - ncols + overlap;
        end;

    elseif( ndims(I)==4 ) % color images
        I = padarray( I, [border border 0 0], 0, 'both' );
        [mrows,ncols,ncolors,nframes] = size(I);
        siz = [mrows+delta*(nframes-1), nframes*ncols-overlap*(nframes-1)];
        F = ones( [siz 3] ) * double(max(I(:))); 
        row = 1; col = siz(2);
        for f=[nframes:-1:1]
            F( row:(row+mrows-1), (col-ncols+1):col, : ) = I(:,:,:,f);
            row = row + delta;
            col = col - ncols + overlap;
        end;
    else
        error( ['Incorrect number of dimensions: ' int2str(ndims(I)) ] );
    end;
    
    
