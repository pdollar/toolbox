% FILTERS
% See also
%
% Filters:
%   filter_binomial_1D  - 1D binomial filter (approximation to Gaussian filter)
%   filter_DOG_2D       - Difference of Gaussian (Dog) Filter.
%   filter_DooG_nD      - n-dim difference of offset Gaussian DooG filter (Gaussian derivative). 
%   filter_gabor_1D     - Creates an even/odd pair of 1D Gabor filters.
%   filter_gabor_2D     - Creates an even/odd pair of 2D Gabor filters.
%   filter_gauss_1D     - 1D Gaussian filter.
%   filter_gauss_nD     - n-dimensional Gaussian filter. 
%   filter_steerable    - Steerable 2D Gaussian derivative filter (for visualization).
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
%   FB_visualize        - Used to visualize a series of 1D/2D/3D filters. 
