% MATLAB
% See also
%
% Quick clear:
%   c                    - clc - clear command window.
%   cc                   - close all, clc
%   ccc                  - clear, close all, clc, clear global
%
% Convenient [but no faster] replacement of "for loops":
%   feval_arrays         - Used to apply the same operation to a stack of array elements.
%   feval_images         - Used to apply the same operation to all images in given directory.
%   feval_mats           - Used to apply the same operation to all .mat files in given directory.
%
% Timing:
%   ticstatus            - Used to display the progress of a long process.
%   tocstatus            - Used to display the progress of a long process.
%
% Array manipulation:
%   arraycrop2dims       - Pads or crops I appropriately so that size(IC)==dims.
%   arraycrop_full       - Used to crop a rectangular region from an n dimensional array.
%   cell2array           - Flattens a cell array of regular arrays into a regular array.
%   mat2cell2            - Break matrix up into a cell array of same sized matrices.
%
% Display:
%   imlabel              - Improved method for labeling figure axes.
%   plotEllipse          - Adds an ellipse to the current plot.
%   plotGaussEllipses    - Plots 2D ellipses derived from 2D Gaussians specified by mus & Cs.
%   text2                - Wrapper for text.m that ensures displayed text fits in figure.
%   figureResized        - Creates a figures that takes up certain area of screen.
%
% Miscellaneous:
%   checkNumArgs         - Helper utility for checking numeric vector arguments.
%   gauss2ellipse        - Creates an ellipse representing the 2D Gaussian distribution.
%   getPrmDflt           - Helper to set default values (if not already set) of parameter struct.
%   ind2sub2             - Improved version of ind2sub.
%   int2str2             - Convert integer to string of given length; improved version of int2str.
%   isfield2             - More comprehensive version of isfield.
%   normpdf2             - Normal prob. density function (pdf) with arbitrary covariance matrix.
%   num2strs             - Applies num2str to each element of an array X.
%   randint2             - Faster but restricted version of randint.
%   randomsample         - Samples elements of X so result uses at most maxMegs megabytes of memory.
%   rotationMatrix       - Performs different operations dealing with a rotation matrix
%   simplecache          - A very simply cache that can be used to store results of computations.
%   sub2ind2             - Improved version of sub2ind.
%
% Thin plate splines:
%   tps_getwarp          - Given two sets of corresponding points, calculates warp between them.
%   tps_interpolate      - Apply warp (obtained by tps_getwarp) to a set of new points.
%   tps_interpolateimage - Interpolate Isrc according to the warp from Isrc->Idst.
%   tps_random           - Obtain a random warp with the same bending energy as the original.
