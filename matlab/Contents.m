% MATLAB
% See also
%
% Embarrassingly parallel function evaluation:
%   fevalArrays       - Used to apply the same operation to a stack of array elements.
%   fevalDistr        - Wrapper for embarrassingly parallel function evaluation.
%   fevalDistrDisk    - Helper for fevalDistr (do no call directly).
%   fevalImages       - Used to apply the same operation to all images in given directory.
%   fevalMats         - Used to apply the same operation to all .mat files in given directory.
%
% Timing:
%   ticStatus         - Used to display the progress of a long process.
%   tocStatus         - Used to display the progress of a long process.
%
% Array manipulation:
%   arrayCrop         - Used to crop a rectangular region from an n dimensional array.
%   arrayToDims       - Pads or crops I appropriately so that size(IC)==dims.
%   cell2array        - Flattens a cell array of regular arrays into a regular array.
%   mat2cell2         - Break matrix up into a cell array of same sized matrices.
%
% Display:
%   c                 - clc - clear command window.
%   cc                - close all, clc
%   ccc               - clear, close all, clc, clear global
%   char2img          - Convert ascii text to a binary image using pre-computed templates.
%   dispMatrixIm      - Display a Matrix with non-negative entries in image form.
%   figureResized     - Creates a figures that takes up certain area of screen.
%   imLabel           - Improved method for labeling figure axes.
%   plotEllipse       - Adds an ellipse to the current plot.
%   plotGaussEllipses - Plots 2D ellipses derived from 2D Gaussians specified by mus & Cs.
%   text2             - Wrapper for text.m that ensures displayed text fits in figure.
%   txt2img           - Convert text string to a binary image.
%
% Miscellaneous:
%   checkNumArgs      - Helper utility for checking numeric vector arguments.
%   dijkstra          - Runs Dijkstra's shortest path algorithm on a distance matrix.
%   dirSynch          - Synchronize two directory trees (or show differences between them).
%   diskFill          - Fill a harddisk with garbage files (useful before discarding disk).
%   gauss2ellipse     - Creates an ellipse representing the 2D Gaussian distribution.
%   getPrmDflt        - Helper to set default values (if not already set) of parameter struct.
%   ind2sub2          - Improved version of ind2sub.
%   isfield2          - Similar to isfield but also test whether fields are initialized.
%   int2str2          - Convert integer to string of given length; improved version of int2str.
%   medianw           - Fast weighted median.
%   multiDiv          - Matrix divide each submatrix of two 3D arrays without looping.
%   multiTimes        - Matrix multiply each submatrix of two 3D arrays without looping.
%   normpdf2          - Normal prob. density function (pdf) with arbitrary covariance matrix.
%   num2strs          - Applies num2str to each element of an array X.
%   plotRoc           - Function for display of rocs (receiver operator characteristic curves).
%   randint2          - Faster but restricted version of randint.
%   randSample        - Generate values sampled uniformly without replacement from 1:n.
%   rotationMatrix    - Performs different operations dealing with a rotation matrix
%   simpleCache       - A simple cache that can be used to store results of computations.
%   spBlkDiag         - Creates a sparse block diagonal matrix from a 3D array.
%   sub2ind2          - Improved version of sub2ind.
%   subsToArray       - Converts subs/vals image representation to array representation.
%   uniqueColors      - Generate m*n visually distinct RGB colors suitable for display.
%
% Thin plate splines:
%   tpsGetWarp        - Given two sets of corresponding points, calculates warp between them.
%   tpsInterpolate    - Apply warp (obtained by tpsGetWarp) to a set of new points.
%   tpsInterpolateIm  - Interpolate Isrc according to the warp from Isrc->Idst.
%   tpsRandom         - Obtain a random warp with the same bending energy as the original.
