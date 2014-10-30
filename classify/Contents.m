% CLASSIFY
% See also
%
% Clustering:
%   demoCluster        - Clustering demo.
%   demoGenData        - Generate data drawn form a mixture of Gaussians.
%   kmeans2            - Fast version of kmeans clustering.
%   meanShift          - meanShift clustering algorithm.
%   meanShiftIm        - Applies the meanShift algorithm to a joint spatial/range image.
%   meanShiftImExplore - Visualization to help choose sigmas for meanShiftIm.
%
% Calculating distances efficiently:
%   distMatrixShow     - Useful visualization of a distance matrix of clustered points.
%   pdist2             - Calculates the distance between sets of vectors.
%   softMin            - Calculates the softMin of a vector.
%
% Principal components analysis:
%   pca                - Principal components analysis (alternative to princomp).
%   pcaApply           - Companion function to pca.
%   pcaRandVec         - Generate random vectors in PCA subspace.
%   pcaVisualize       - Visualization of quality of approximation of X given principal comp.
%   visualizeData      - Project high dim. data unto principal components (PCA) for visualization.
%
% Confusion matrix display:
%   confMatrix         - Generates a confusion matrix according to true and predicted data labels.
%   confMatrixShow     - Used to display a confusion matrix.
%
% Radial Basis Functions (RBFs):
%   rbfComputeBasis    - Get locations and sizes of radial basis functions for use in rbf network.
%   rbfComputeFtrs     - Evaluate features of X given a set of radial basis functions.
%   rbfDemo            - Demonstration of rbf networks for regression.
%
% Fast random fern/forest classification/regression code:
%   fernsClfApply      - Apply learned fern classifier.
%   fernsClfTrain      - Train random fern classifier.
%   fernsInds          - Compute indices for each input by each fern.
%   fernsRegApply      - Apply learned fern regressor.
%   fernsRegTrain      - Train boosted fern regressor.
%   forestApply        - Apply learned forest classifier.
%   forestTrain        - Train random forest classifier.
%
% Fast boosted decision tree code:
%   adaBoostTrain      - Train boosted decision tree classifier.
%   adaBoostApply      - Apply learned boosted decision tree classifier.
%   binaryTreeTrain    - Train binary decision tree classifier.
%   binaryTreeApply    - Apply learned binary decision tree classifier.
