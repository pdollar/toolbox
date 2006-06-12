% FILTERS
% See also
%
% Filters:
%   filter_DOG_2D       - Difference of Gaussian (Dog) Filter.
%   filter_DOOG_1D      - 1D difference of offset Gaussian (DooG) filters.
%   filter_DOOG_2D      - 2D difference of offset Gaussian (DooG) filters.
%   filter_DOOG_3D      - 3D difference of offset Gaussian (DooG) filters.
%   filter_binomial_1D  - 1D binomial filter (approximation to Gaussian filter)
%   filter_gabor_1D     - 1D Gabor Filters.
%   filter_gabor_2D     - 2D Gabor filters.
%   filter_gauss_1D     - 1D Gaussian filter.
%   filter_gauss_nD     - n-dimensional Gaussian filter. 
%   filter_steerable    - Steerable Gaussian derivative filter.
%   filter_visualize_1D - Used to help visualize the a 1D filter.
%   filter_visualize_2D - Used to help visualize a 2D filter.  
%   filter_visualize_3D - Used to help visualize a 3D filter. 
%
% Operations involving a set of filters (a filter bank or FB):
%   FB_apply_2D         - Applies each of the filters in the filterbank FB to the image I.
%   FB_crop             - Crop a 2D filterbank (adjusting filter norms).
%   FB_make_1D          - Various ways to make filterbanks.  See inside of this file for details.
%   FB_make_2D          - Various ways to make filterbanks.  See inside of this file for details.
%   FB_make_3D          - Various ways to make filterbanks.  See inside of this file for details.
%   FB_reconstruct_2D   - Use to see how much image information is preserved in filter outputs.
%   FB_visualize_1D     - Used to visualize the Fourier spectra of a series of 1D filters.  
%   FB_visualize_2D     - Used to visualize the Fourier spectra of a series of 2D filters.
