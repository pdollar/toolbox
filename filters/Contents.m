% FILTERS
% See also
%
% Filters:
%   filterBinomial1d - 1D binomial filter (approximation to Gaussian filter)
%   filterDog2d      - Difference of Gaussian (Dog) Filter.
%   filterDoog       - n-dim difference of offset Gaussian DooG filter (Gaussian derivative).
%   filterGabor1d    - Creates an even/odd pair of 1D Gabor filters.
%   filterGabor2d    - Creates an even/odd pair of 2D Gabor filters.
%   filterGauss      - n-dimensional Gaussian filter.
%   filterSteerable  - Steerable 2D Gaussian derivative filter (for visualization).
%   filterVisualize  - Used to visualize a 1D/2D/3D filter.
%
% Operations involving a set of filters (a filter bank or FB):
%   FbApply2d        - Applies each of the filters in the filterbank FB to the image I.
%   FbCrop           - Crop a 2D filterbank (adjusting filter norms).
%   FbMake           - Various 1D/2D/3D filterbanks (hardcoded).
%   FbReconstruct2d  - Use to see how much image information is preserved in filter outputs.
%   FbVisualize      - Used to visualize a series of 1D/2D/3D filters. 
%
% Simple nonlinear filters:
%   medfilt1m        - One-dimensional adaptive median filtering with missing values.
%   modefilt1        - One-dimensional mode filtering.
