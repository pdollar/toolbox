% FILTERS
% See also
%
% Filters:
%   filterBinomial1d    - 1D binomial filter (approximation to Gaussian filter)
%   filterDog2d         - Difference of Gaussian (Dog) Filter.
%   filterDoog          - n-dim difference of offset Gaussian DooG filter (Gaussian derivative).
%   filterGabor1d       - Creates an even/odd pair of 1D Gabor filters.
%   filterGabor2d       - Creates an even/odd pair of 2D Gabor filters.
%   filterGauss         - n-dimensional Gaussian filter.
%   filterSteerable     - Steerable 2D Gaussian derivative filter (for visualization).
%   filter_visualize_1D - Used to visualize a 1D filter.
%   filter_visualize_2D - Used to visualize a 2D filter.
%   filter_visualize_3D - Used to visualize a 3D filter.
%
% Operations involving a set of filters (a filter bank or FB):
%   FB_apply_2D         - Applies each of the filters in the filterbank FB to the image I.
%   FB_crop             - Crop a 2D filterbank (adjusting filter norms).
%   FB_make_1D          - Various 1D filterbanks (hardcoded).
%   FB_make_2D          - Various 2D filterbanks (hardcoded).
%   FB_make_3D          - Various 3D filterbanks (hardcoded).
%   FB_reconstruct_2D   - Use to see how much image information is preserved in filter outputs.
%   FbVisualize         - Used to visualize a series of 1D/2D/3D filters. 
