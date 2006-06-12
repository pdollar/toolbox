% CLASSIFY
% See also
%
% Clustering:
%   democluster         - Clustering demo.
%   demogendata         - Generate data drawn form a mixture of Gaussians.
%   kmeans2             - Very fast version of kmeans clustering.
%   meanshift           - meanshift clustering algorithm.
%   meanshiftim         - Applies the meanshift algorithm to a joint spatial/range image.  
%   meanshiftim_explore - Visualization to help choose sigmas for meanshiftim.
%
% Calculating distances efficiently:
%   dist_L1             - Calculates the L1 Distance between vectors (ie the City-Block distance).
%   dist_chisquared     - Calculates the Chi Squared Distance between vectors (usually histograms).
%   dist_emd            - Calculates Earth Mover's Distance (EMD) between positive vectors.
%   dist_euclidean      - Calculates the Euclidean distance between vectors [FAST].
%   distmatrix_show     - Useful visualization of a distance matrix of clustered points.
%   softmin             - Calculates the softmin of a vector.
%
% Principal components analysis:
%   pca                 - principal components analysis (alternative to princomp).
%   pca_apply           - Companion function to pca.
%   pca_apply_large     - Wrapper for pca_apply that allows for application to large X.
%   pca_randomvector    - Generate random vectors in PCA subspace.
%   pca_visualize       - Visualization of quality of approximation of X given principal components.
%   visualize_data      - Project high dim. data unto principal components (PCA) for visualization.
%
% Classification methods with a common interface:
%   democlassify        - A demo used to test and demonstrate the usage of classifiers (clf_*)
%   nfoldxval           - Runs n-fold cross validation on data with a given classifier.
%   confmatrix          - Generates a confusion matrix according to true and predicted data labels.
%   confmatrix_show     - Used to display a confusion matrix.  
%   clf_dectree         - Wrapper for treefit that makes decision trees compatible with nfoldxval.
%   clf_dectree_fwd     - Apply the decision tree to data X.
%   clf_dectree_train   - Train a decision tree classifier.
%   clf_ecoc            - Wrapper for ecoc that makes ecoc compatible with nfoldxval.
%   clf_ecoc_code       - Generates optimal ECOC codes when 3<=nclasses<=7.
%   clf_knn             - Create a k nearest neighbor classifier.
%   clf_knn_dist        - k-nearest neighbor classifier based on a distance matrix D.
%   clf_knn_fwd         - Apply a k-nearest neighbor classifier to X.
%   clf_knn_train       - Train a k nearest neighbor classifier (memorization).
%   clf_lda             - Create a Linear Discriminant Analysis (LDA) classifier.
%   clf_lda_fwd         - Apply the Linear Discriminant Analysis (LDA) classifier to data X.
%   clf_lda_train       - Train a Linear Discriminant Analysis (LDA) classifier.
%   clf_svm             - Wrapper for svm that makes svm compatible with nfoldxval.
