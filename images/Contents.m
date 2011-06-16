% IMAGE
% See also
%
% Display:
%   clusterMontage    - Used for visualization of clusters of images and videos.
%   im                - Function for displaying grayscale images.
%   filmStrip         - Used to display R stacks of T images as a "filmstrip".
%   makeGif           - Writes a matlab movie to an animated GIF.
%   montage2          - Used to display collections of images and videos.
%   movieToImages     - Creates a stack of images from a matlab movie M.
%   playMovie         - Shows/makes an/several movie(s) from an image sequence.
%
% Histograms:
%   assignToBins      - Quantizes A according to values in edges.
%   histc2            - Multidimensional histogram count with weighted values.
%   histcImWin        - Calculates local histograms at every point in an image I.
%   histcImLoc        - Creates a series of locally position dependent histograms.
%   histMontage       - Used to display multiple 1D histograms.
%
% Generalized correlation:
%   normxcorrn        - Normalized n-dimensional cross-correlation.
%   xcorrn            - n-dimensional cross-correlation.  Generalized version of xcorr2.
%   xeucn             - n-dimensional euclidean distance between each window in A and template T.
%
% Image deformation:
%   imNormalize       - Various ways to normalize a (multidimensional) image.
%   imResample        - Fast bilinear image downsampling/upsampling.
%   imShrink          - Used to shrink a multidimensional array I by integer amount.
%   imtransform2      - Applies a linear or nonlinear transformation to an image I.
%   textureMap        - Maps texture in I according to rsDst and csDst.
%
% Generalized nonmaximal suppression:
%   nonMaxSupr        - Applies nonmaximal suppression on an image of arbitrary dimension.
%   nonMaxSuprList    - Applies nonmaximal suppression to a list.
%   nonMaxSuprWin     - Nonmaximal suppression of values outside of a given window.
%
% Optical Flow:
%   optFlowCorr       - Calculate optical flow using cross-correlation.
%   optFlowHorn       - Calculate optical flow using Horn & Schunck.
%   optFlowLk         - Calculate optical flow using Lucas & Kanade.  Fast, parallel code.
%
% Seq files:
%   seqIo             - Utilities for reading and writing seq files.
%   seqReaderPlugin   - Plugin for seqIo and videoIO to allow reading of seq files.
%   seqWriterPlugin   - Plugin for seqIo and videoIO to allow writing of seq files.
%   seqPlayer         - Simple GUI to play seq files.
%
% Object bounding box utilities and labeling tools:
%   bbApply           - Functions for manipulating bounding boxes (bb).
%   bbGt              - Bounding box (bb) annotations struct, evaluation and sampling routines.
%   bbLabeler         - Bounding box or ellipse labeler for static images.
%   bbNms             - Bounding box (bb) non-maximal suppression (nms).
%
% Behavior annotation for seq files:
%   behaviorAnnotator - Caltech Behavior Annotator.
%   behaviorData      - Retrieve and manipulate behavior annotation of a video.
%
% Binary mask creation:
%   maskCircle        - Creates an image of a 'pie slice' of a circle.
%   maskEllipse       - Creates a binary image of an ellipse.
%   maskGaussians     - Divides a volume into softly overlapping gaussian windows.
%   maskSphere        - Creates an 'image' of a n-dimensional hypersphere.
%
% Linear filtering:
%   convnFast         - Fast convolution, replacement for both conv2 and convn.
%   gaussSmooth       - Applies Gaussian smoothing to a (multidimensional) image.
%   localSum          - Fast routine for box filtering.
%
% Miscellaneous:
%   hog               - Efficiently compute histogram of oriented gradient (HOG) features.
%   hogDraw           - Create visualization of hog descriptor.
%   imagesAlign       - Fast and robust estimation of homography relating two images.
%   imMlGauss         - Calculates max likelihood params of Gaussian that gave rise to image G.
%   imrectLite        - A 'lite' version of imrect [OBSOLETE: use imrectRot].
%   imRectRot         - Create a draggable, resizable, rotatable rectangle or ellipse.
%   imwrite2          - Similar to imwrite, except follows a strict naming convention.
%   jitterImage       - Creates multiple, slightly jittered versions of an image.
%   kernelTracker     - Kernel Tracker from Comaniciu, Ramesh and Meer PAMI 2003.
