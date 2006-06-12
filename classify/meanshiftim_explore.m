% Visualization to help choose sigmas for meanshiftim.
%
% Displays the original image I, and prompts user to select a point on the image.  For
% given point, calculates the distance (both spatial and range) to every other point in
% the image.   It shows the results in a number of panes, which include 1) the original
% image I, 2) Srange - similarity based on range only, 3) Seuc - similarity based on
% Euclidean distance only, and 4) overall similarity.  Finally, in each image the green
% dot (possibly occluded) shows the original point, and the blue dot shows the new mean of
% the window after 1 step of meanshift.
%
% INPUTS
%   I       - MxN image for display
%   X       - MxNxP data array, P may be 1 (X may be same as I)
%   sig_spt - integer specifying spatial standard deviation
%   sig_rng - value specifying the standard deviation of the range data
%   show    - [optional] will display results in figure(show)
%
% EXAMPLE
%   I=double(imread('cameraman.tif'))/255;
%   meanshiftim_explore( I, I, 5, .2, 1 );
%
% DATESTAMP
%   25-Oct-2005  4:00pm
%
% See also MEANSHIFTIM

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function meanshiftim_explore( I, X, sig_spt, sig_rng, show )
    if( nargin<5 ) show = 1; end;
    [mrows, ncols, p] = size(X);

    %%% get input point
    figure(show); clf; im(I);
    [c,r] = ginput(1);
    r=round(r); c=round(c);

    %%% get D and S
    [grid_rs grid_cs] = ndgrid( 1:mrows, 1:ncols );
    Deuc = ((grid_rs-r).^2 + (grid_cs-c).^2) / sig_spt^2;
    x = X(r,c,:); x = x(:)';  Xflat = reshape(X,[],p);
    Drange = dist_euclidean( x, Xflat );
    Drange = reshape( Drange, mrows, ncols ) / sig_rng^2;
    D = Drange + Deuc;      
    
    S = exp( -D );  
    Srange = exp( -Drange );  
    Seuc = exp( -Deuc );  
    
    %%% new c and r [stretched for display]
    c2 = (grid_cs .* S); c2 = sum( c2(:) ) / sum(S(:));
    r2 = (grid_rs .* S); r2 = sum( r2(:) ) / sum(S(:));
    %c2 = c+(c2-c)*2; r2 = r+(r2-r)*2;
    
    %%% show
    figure(show); clf;
    subplot(2,2,1); im(I);  
    hold('on'); plot( c, r, '.g' ); plot( c2, r2, '.b' ); hold('off');
    subplot(2,2,2); im(Srange);
    hold('on'); plot( c, r, '.g' ); plot( c2, r2, '.b' ); hold('off');
    subplot(2,2,3); im(Seuc);
    hold('on'); plot( c, r, '.g' ); plot( c2, r2, '.b' ); hold('off');
    subplot(2,2,4); im(S);
    hold('on'); plot( c, r, '.g' ); plot( c2, r2, '.b' ); hold('off');    

