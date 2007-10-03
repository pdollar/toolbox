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
%   softMin            - Calculates the softMin of a vector.
%   pdist2             - Calculates the distance between sets of vectors.
%
% Principal components analysis:
%   pca                - Principal components analysis (alternative to princomp).
%   pcaApply           - Companion function to pca.
%   pcaRandVec         - Generate random vectors in PCA subspace.
%   pcaVisualize       - Visualization of quality of approximation of X given principal comp.
%   visualizeData      - Project high dim. data unto principal components (PCA) for visualization.
%
% Classification methods with a common interface:
%   demoClassify       - A demo used to test and demonstrate the usage of classifiers (clf*)
%   nfoldxval          - Runs n-fold cross validation on data with a given classifier.
%   confMatrix         - Generates a confusion matrix according to true and predicted data labels.
%   confMatrixShow     - Used to display a confusion matrix.
%   clfDecTree         - Wrapper for treefit that makes decision trees compatible with nfoldxval.
%   clfDecTreeFwd      - Apply the decision tree to data X.
%   clfDecTreeTrain    - Train a decision tree classifier.
%   clfEcoc            - Wrapper for ecoc that makes ecoc compatible with nfoldxval.
%   clfEcocCode        - Generates optimal ECOC codes when 3<=nclasses<=7.
%   clfKnn             - Create a k nearest neighbor classifier.
%   clfKnnDist         - k-nearest neighbor classifier based on a distance matrix D.
%   clfKnnFwd          - Apply a k-nearest neighbor classifier to X.
%   clfKnnTrain        - Train a k nearest neighbor classifier (memorization).
%   clfLda             - Create a Linear Discriminant Analysis (LDA) classifier.
%   clfLdaFwd          - Apply the Linear Discriminant Analysis (LDA) classifier to data X.
%   clfLdaTrain        - Train a Linear Discriminant Analysis (LDA) classifier.
%   clfSvm             - Wrapper for svm that makes svm compatible with nfoldxval.
%
% Radial Basis Functions (RBFs)
%   rbfComputeBasis    - Get locations and sizes of radial basis functions for use in rbf network.
%   rbfComputeFtrs     - Evaluate features of X given a set of radial basis functions.
%   rbfDemo            - Demonstration of rbf networks for regression.
