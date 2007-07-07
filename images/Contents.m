% IMAGE
% See also
%
% Display:
%   im                  - [2D] Function for displaying grayscale images.
%   montage2            - [3D] Used to display a stack of T images.
%   montages            - [4D] Used to display R sets of T images each.
%   filmstrip           - [3D] Used to display a stack of T images as a filmstrip.
%   filmstrips          - [4D] Used to display R sets of filmstrips.
%   makemovie           - [3D] Used to convert a stack of T images into a movie.
%   makemovies          - [4D] Used to convert R sets of equal length videos into a single movie.
%   makemoviesets       - [5D] Used to convert S sets of R videos into a movie.
%   makemoviesets2      - [5D] Used to convert S sets of R videos into a movie.
%   playmovie           - [3D] shows the image sequence I as a movie.
%   clustermontage      - Used for visualization of clusters of images and videos.
%   movie2images        - Creates a stack of images from a matlab movie M.
%
% Histograms:
%   assign2bins         - Quantizes I according to values in edges.
%   histc_1D            - Generalized, version of histc (histogram count), allows weighted values.
%   histc_image         - Calculates histograms at every point in an array I.
%   histc_nD            - Generalized, multidimensional version of normalized histc
%   histc_sift          - Creates a series of locally position dependent histograms of values in I.
%   histc_sift_nD       - Creates a series of locally position dependent histograms.
%   histmontage         - Used to display multiple 1D histograms.
%
% Generalized correlation: PPD
%   normxcorrn          - Normalized n-dimensional cross-correlation.
%   xcorrn              - n-dimensional cross-correlation.  Generalized version of xcorr2.
%   xeucn               - n-dimensional euclidean distance between each window in A and template T
%
% Image deformation:
%   imNormalize         - Various ways to normalize a (multidimensional) image.
%   imShrink            - Used to shrink a multidimensional array I by integer amount.
%   imsubs2array        - Converts subs/vals image representation to array representation.
%   imsubs_resize       - Resizes subs in subs/vals image representation by resizVals.
%   imtransform2        - Applies a general/special homography on an image I
%   textureMap          - Maps texture in I according to rowDst and colDst.
%
% Generalized nonmaximal suppression: PPD
%   nonMaxSupr          - Applies nonmaximal suppression on an image of arbitrary dimension.
%   nonMaxSuprList      - Applies nonmaximal suppression to a list.
%   nonMaxSuprWin       - Nonmaximal suppression of values outside of a given window.
%
% Optical Flow:
%   optflow_corr        - Calculate optical flow using cross-correlation.
%   optflow_horn        - Calculate optical flow using Horn & Schunck.
%   optflow_lucaskanade - Calculate optical flow using Lucas & Kanade.  Fast, parallel code.
%
% Miscellaneous:
%   convnFast           - Fast convolution, replacement for both conv2 and convn.
%   gaussSmooth         - Applies Gaussian smoothing to a (multidimensional) image.
%   imageMLG            - Calculates max likelihood params of Gaussian that gave rise to image G.
%   imwrite2            - Similar to imwrite, except follows a strict naming convention.
%   imwrite2split       - Writes/reads a large set of images into/from multiple directories.
%   jitterImage         - Creates multiple, slightly jittered versions of an image.
%   jitterVideo         - Creates multiple, slightly jittered versions of a video.
%   localSum            - Fast routine for box filtering.
%   maskCircle          - Creates an image of a 'pie slice' of a circle.
%   maskEllipse         - Creates a binary image of an ellipse.
%   maskGaussians       - Divides a volume into softly overlapping gaussian windows.
%   maskSphere          - Creates an 'image' of a n-dimensional hypersphere.
%   modefilt1           - One-dimensional mode filtering.
