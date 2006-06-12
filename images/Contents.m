% IMAGE
% See also
%
% Display:
%   im                  - [2D] Function for displaying grayscale images.
%   montage2            - [3D] Used to display a stack of T images. 
%   montages            - [4D] Used to display R sets of T images each.
%   montages2           - [4D] Used to display R sets of T images each.  
%   filmstrip           - [3D] Used to display a stack of T images as a filmstrip. 
%   filmstrips          - [4D] Used to display R sets of filmstrips.
%   makemovie           - [3D] Used to convert a stack of T images into a movie.  
%   makemovies          - [4D] Used to convert R sets of equal length videos into a single movie. 
%   makemoviesets       - [5D] Used to convert S sets of R videos into a movie.
%   makemoviesets2      - [5D] Used to convert S sets of R videos into a movie.
%   playmovie           - [3D] shows the image sequence I as a movie.
%   playmovies          - [4D] shows R videos simultaneously as a movie.
%   clustermontage      - Used for visualization of clusters of images and videos.  
%   movie2images        - Creates a stack of images from a matlab movie M.
%
% Histograms:
%   assign2bins         - Quantizes I according to values in edges.  
%   histc_1D            - Generalized, version of histc (histogram count), allows weighted values.
%   histc_image         - Calculates histograms at every point in an array I.  
%   histc_nD            - Generalized, multidimensional version of normalized histc (histogram count).
%   histc_sift          - Creates a series of locally position dependent histograms of the values in I.
%   histc_sift_nD       - Creates a series of locally position dependent histograms.
%   histmontage         - Used to display multiple 1D histograms.
%
% Convolution:
%   convn_fast          - Fast convolution, replacement for both conv2 and convn. 
%   gauss_smooth        - Applies Gaussian smoothing to a (multidimensional) image.
%
% Generalized correlation:
%   normxcorrn          - Normalized n-dimensional cross-correlation.
%   normxcorrn_fg       - Normalized n-dimensional cross-correlation with a mask.
%   xcorrn              - n-dimensional cross-correlation.  Generalized version of xcorr2.
%   xeucn               - n-dimensional euclidean distance between each window in A and template T.
%
% Image deformation:
%   apply_homography    - Applies the homography defined by H on the image I.  
%   texture_map         - Maps texture in I according to row_dest and col_dest.
%   imnormalize         - Various ways to normalize a (multidimensional) image.
%   imrotate2           - Custom version of imrotate that demonstrates use of apply_homography.
%   imtranslate         - Translate an image to subpixel accuracy.
%   imshrink            - Used to shrink a multidimensional array I by integer amount.
%   imsubs2array        - Converts subs/vals image representation to array representation.
%   imsubs_resize       - Resizes subs in subs/vals image representation by resizevals.
%
% Generalized nonmaximal suppression:
%   nonmaxsupr          - Applies nonmaximal suppression on an image of arbitrary dimension.
%   nonmaxsupr_list     - Applies nonmaximal suppression to a list.
%   nonmaxsupr_window   - Nonmaximal suppression of values outside of a given window.
%
% Optical Flow:
%   optflow_corr        - Calculate optical flow using cross-correlation.
%   optflow_horn        - Calculate optical flow using Horn & Schunck.
%   optflow_lucaskanade - Calculate optical flow using Lucas & Kanade.  Fast, parallel code.
%
% Miscellaneous:
%   imageMLG            - Calculates maximum likelihood parameters of gaussian that gave rise to image G.
%   imwrite2            - Similar to imwrite, except follows a strict naming convention.
%   imwrite2split       - Writes/reads a large set of images into/from multiple directories.
%   jitter_image        - Creates multiple, slightly jittered versions of an image.
%   jitter_video        - Creates multiple, slightly jittered versions of a video.
%   localsum            - Fast routine for box filtering.
%   localsum_block      - Calculates the sum in non-overlapping blocks of I of size dims.  
%   mask_circle         - Creates an image of a 'pie slice' of a circle.
%   mask_ellipse        - Creates a binary image of an ellipse.
%   mask_gaussians      - Divides a volume into softly overlapping gaussian windows.
%   modefilt1           - One-dimensional mode filtering.
