function meanShiftImExplore( I, X, sigSpt, sigRng, show )
% Visualization to help choose sigmas for meanShiftIm.
%
% Displays the original image I, and prompts user to select a point on the
% image.  For given point, calculates the distance (both spatial and range)
% to every other point in the image.   It shows the results in a number of
% panes, which include 1) the original image I, 2) Srange - similarity
% based on range only, 3) Seuc - similarity based on Euclidean distance
% only, and 4) overall similarity.  Finally, in each image the green dot
% (possibly occluded) shows the original point, and the blue dot shows the
% new mean of the window after 1 step of meanShift.
%
% USAGE
%  meanShiftImExplore( I, X, sigSpt, sigRng, [show] )
%
% INPUTS
%  I       - MxN image for display
%  X       - MxNxP data array, P may be 1 (X may be same as I)
%  sigSpt  - integer specifying spatial standard deviation
%  sigRng  - value specifying the standard deviation of the range data
%  show    - [1] will display results in figure(show)
%
% OUTPUTS
%
% EXAMPLE
%  I=double(imread('cameraman.tif'))/255;
%  meanShiftImExplore( I, I, 5, .2, 1 );
%
% See also MEANSHIFTIM
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

if( nargin<5 ); show = 1; end
[mrows, ncols, p] = size(X);

%%% get input point
figure(show); clf; im(I);
[c,r] = ginput(1);
r=round(r); c=round(c);

%%% get D and S
[gridRs, gridCs] = ndgrid( 1:mrows, 1:ncols );
Deuc = ((gridRs-r).^2 + (gridCs-c).^2) / sigSpt^2;
x = X(r,c,:); x = x(:)';  Xflat = reshape(X,[],p);
Drange = pdist2( x, Xflat );
Drange = reshape( Drange, mrows, ncols ) / sigRng^2;
D = Drange + Deuc;

S = exp( -D );
Srange = exp( -Drange );
Seuc = exp( -Deuc );

%%% new c and r [stretched for display]
c2 = (gridCs .* S); c2 = sum( c2(:) ) / sum(S(:));
r2 = (gridRs .* S); r2 = sum( r2(:) ) / sum(S(:));
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
