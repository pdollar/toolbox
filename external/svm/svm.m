function net = svm(nin, kernel, kernelpar, C, use2norm, qpsolver, qpsize)
% SVM - Create a Support Vector Machine classifier
% 
%   NET = SVM(NIN, KERNEL, KERNELPAR, C, USE2NORM, QPSOLVER, QPSIZE)
%   (All parameters from KERNELPAR on are optional).
%   Initialise a structure NET containing the basic settings for a Support
%   Vector Machine (SVM) classifier. The SVM is assumed to have input of
%   dimension NIN, it works with kernel function KERNEL. If the kernel
%   function needs extra parameters, these must be given in the array
%   KERNELPAR. See function SVMKERNEL for a list of valid kernel
%   functions.
%
%   The structure NET has the following fields:
%   Basic SVM parameters:
%     'type' = 'svm'
%     'nin' = NIN   number of input dimensions
%     'nout' = 1   number of output dimensions
%     'kernel' = KERNEL   kernel function
%     'kernelpar' = KERNELPAR   parameters for the kernel function
%     'c' = C  Upper bound for the coefficients NET.alpha during
%       training. Depending on the size of NET.c, the value is
%       interpreted as follows:
%       LENGTH(NET.c)==1: Upper bound for all coefficients.
%       LENGTH(NET.c)==2: Different upper bounds for positive (+1) and
%       negative (-1) examples. NET.c(1) is the bound for the positive,
%       NET.c(2) is the bound for the negative examples.
%       LENGTH(NET.c)==N, where N is the number of examples that are
%       passed to SVMTRAIN: NET.c(i) is the upper bound for the
%       coefficient NET.alpha(i) associated with example i.
%       Default value: 1
%     'use2norm' = USE2NORM: If non-zero, the training procedure will use
%       an objective function that involves the 2norm of the errors on
%       the training points, otherwise the 1norm is used (standard
%       SVM). Default value: 0.
%
%   Fields that will be set during training with SVMTRAIN:
%     'nbexamples' = Number of training examples
%     'alpha' = After training, this field contains a column vector with
%       coefficients (weights) for each training example. NET.alpha is
%       not used in any subsequent SVM routines, it can be removed after
%       training.
%     'svind' = After training, this field contains the indices of those
%       training examples that are Support Vectors (those with a large
%       enough value of alpha)
%     'sv' = Contains all the training examples that are Support Vectors.
%     'svcoeff' = After training, this field is the product of NET.alpha
%       times the label of the corresponding training example, for all
%       examples that are Support Vectors. It is given in the same order
%       as the examples are given in NET.sv.
%     'bias' = The linear term of the SVM decision function.
%     'normalw' = Normal vector of the hyperplane that separates the
%       examples. This is only computed if a linear kernel
%       NET.kernel='linear' is used.
%
%   Parameters specifically for SVMTRAIN (rarely need to be changed):
%     'qpsolver' = QPSOLVER. QPSOLVER must be one of 'quadprog', 'loqo',
%       'qp' or empty for auto-detect. Name of the function that solves
%       the quadratic programming problems in SVMTRAIN.
%       Default value: empty (auto-detect).
%     'qpsize' =  QPSIZE. The maximum number of points given to the QP
%       solver. Default value: 50.
%     'alphatol' = Tolerance for all comparisons that involve the
%       coefficients NET.alpha. Default value: 1E-2.
%     'kkttol' = Tolerance for checking the KKT conditions (termination
%       criterion) Default value: 5E-2. Lower this when high precision is
%       required.
%
%   See also:
%   SVMKERNEL, SVMTRAIN, SVMFWD
%

% 
% Copyright (c) Anton Schwaighofer (2001)
% $Revision: 1.6 $ $Date: 2002/01/07 19:51:49 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

if nargin < 7,
  qpsize = 50;
end
if nargin < 6,
  qpsolver = '';
end
if nargin < 5,
  use2norm = 0;
end
if nargin < 4,
  C = 1;
end
if nargin < 3,
  kernelpar = [];
end

net.type = 'svm';
net.nin = nin;
net.nout = 1;
net.kernel = kernel;
net.kernelpar = kernelpar;
net.c = C;
net.use2norm = use2norm;

net.nbexamples = 0;
net.alpha = [];
net.svcoeff = [];
net.sv = [];
net.svind = [];
net.bias = [];
net.normalw = [];

net.qpsolver = qpsolver;
net.qpsize = qpsize;
net.alphatol = 1e-2;
net.kkttol = 5e-2;
net.chunksize = 500;
%     'chunksize' = Large matrix operations (for example when evaluating
%       the kernel functions) are split up into submatrices with maximum
%       size [NET.chunksize, NET.chunksize]. Default value: 500
net.recompute = Inf;
%     'recompute' = During training, the SVM outputs are updated
%       iteratively. After NET.recompute iterations the SVM outputs are
%       built again from scratch. Lower this when high precision is required.
