% CHANNELS
% See also
%
% Fast channel feature computation code based on the papers:
%  [1] P. Dollár, Z. Tu, P. Perona and S. Belongie
%   "Integral Channel Features", BMVC 2009.
%  [2] P. Dollár, S. Belongie and P. Perona
%   "The Fastest Pedestrian Detector in the West," BMVC 2010.
%  [3] P. Dollár, R. Appel and W. Kienzle
%   "Crosstalk Cascades for Frame-Rate Pedestrian Detection," ECCV 2012.
%  [4] P. Dollár, R. Appel, S. Belongie and P. Perona
%   "Fast Feature Pyramids for Object Detection", PAMI 2014.
% Please cite a subset of the above papers if you end up using the code.
% The PAMI 2014 paper has the most thorough and up to date descriptions.
% Code written and maintained by Piotr Dollar and Ron Appel.
%
% Channels:
%   chnsCompute  - Compute channel features at a single scale given an input image.
%   chnsPyramid  - Compute channel feature pyramid given an input image.
%   chnsScaling  - Compute lambdas for channel power law scaling.
%
% Constant time image smoothing:
%   convBox      - Extremely fast 2D image convolution with a box filter.
%   convMax      - Extremely fast 2D image convolution with a max filter.
%   convTri      - Extremely fast 2D image convolution with a triangle filter.
%
% Gradients and gradient histograms:
%   gradient2    - Compute numerical gradients along x and y directions.
%   gradientHist - Compute oriented gradient histograms.
%   gradientMag  - Compute gradient magnitude and orientation at each image location.
%   hog          - Efficiently compute histogram of oriented gradient (HOG) features.
%   hogDraw      - Create visualization of hog descriptor.
%   fhog         - Efficiently compute Felzenszwalb's HOG (FHOG) features.
%
% Miscellaneous:
%   imPad        - Pad an image along its four boundaries.
%   imResample   - Fast bilinear image downsampling/upsampling.
%   rgbConvert   - Convert RGB image to other color spaces (highly optimized).
