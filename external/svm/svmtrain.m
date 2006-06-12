function net = svmtrain(net, X, Y, alpha0, dodisplay)
% SVMTRAIN - Train a Support Vector Machine classifier
%
%   NET = SVMTRAIN(NET, X, Y)
%   Train the SVM given by NET using the training data X with target values
%   Y. X is a matrix of size (N,NET.nin) with N training examples (one per
%   row). Y is a column vector containing the target values (classes) for
%   each example in X. Each element of Y that is >=0 is treated as class
%   +1, each element <0 is treated as class -1.
%   SVMTRAIN normally uses L1-norm of all training set errors in the
%   objective function. If NET.use2norm==1, L2-norm is used.
%
%   All training parameters are given in the structure NET. Relevant
%   parameters are mainly NET.c, for fine-tuning also NET.qpsize,
%   NET.alphatol and NET.kkttol. See function SVM for a description of
%   these fields.
%
%   NET.c is a weight for misclassifying a particular example. NET.c may
%   either be a scalar (where all errors have the same weights), or it may
%   be a column vector (size [N 1]) where entry NET.c(i) corresponds to the
%   error weight for example X(i,:). If NET.c is e vector of length 2,
%   NET.c(1) specifies the error weight for all positive examples, NET.c(2)
%   is the error weight for all negative examples. Specifying a different
%   weight for each example may be used for imbalanced data sets.
%
%   NET = SVMTRAIN(NET, X, Y, ALHPA0) uses the column vector ALPHA0 as
%   the initial values for the coefficients NET.alpha. ALPHA0 may result
%   from a previous training with different parameters.
%   NET = SVMTRAIN(NET, X, Y, ALPHA0, 1) displays information on the
%   training progress (number of errors in the current iteration, etc)
%   SVMTRAIN uses either the function LOQO (Matlab-Interface to Smola's
%   LOQO code) or the routines QP/QUADPROG from the Matlab Optimization
%   Toolbox to solve the quadratic programming problem.
%
%   See also:
%   SVM, SVMKERNEL. SVMFWD
%

% 
% Copyright (c) Anton Schwaighofer (2001)
% $Revision: 1.19 $ $Date: 2002/01/09 12:11:41 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

% Training a SVM involves solving a quadratic programming problem that
% scales quadratically with the number of examples. SVMTRAIN uses the
% decomposed training algorithm proposed by Osuna, Freund and Girosi, where
% the maximum size of a quadratic program is constant.
% (ftp://ftp.ai.mit.edu/pub/cbcl/nnsp97-svm.ps)
% For selecting the working set, the approximation proposed by Joachims
% (http://www-ai.cs.uni-dortmund.de/DOKUMENTE/joachims_99a.ps.gz) is used.


% Check arguments for consistency
errstring = consist(net, 'svm', X, Y);
if ~isempty(errstring);
  error(errstring);
end
[N, d] = size(X);
if N==0,
  error('No training examples given');
end
net.nbexamples = N;
if nargin<5,
  dodisplay = 0;
end
if nargin<4,
  alpha0 = [];
elseif (~isempty(alpha0)) & (~all(size(alpha0)==[N 1])),
  error(['Initial values ALPHA0 must be a column vector with the same length' ...
	 ' as X']); 
end

% Find the indices of examples from class +1 and -1
class1 = logical(uint8(Y>=0));
class0 = logical(uint8(Y<0));

if length(net.c(:))==1,
  C = repmat(net.c, [N 1]);
  % The same upper bound for all examples
elseif length(net.c(:))==2,
  C = zeros([N 1]);
  C(class1) = net.c(1);
  C(class0) = net.c(2);
  % Different upper bounds C for the positive and negative examples
else
  C = net.c;
  if ~all(size(C)==[N 1]),
    error(['Upper bound C must be a column vector with the same length' ...
	   ' as X']); 
  end
end
if min(C)<net.alphatol,
  error('NET.C must be positive and larger than NET.alphatol');
end

if ~isfield(net, 'use2norm'),
  net.use2norm = 0;
end

if ~isfield(net, 'qpsolver'),
  net.qpsolver = '';
end
qpsolver = net.qpsolver;
if isempty(qpsolver),
  % QUADPROG is the fastest solver for both 1norm and 2norm SVMs, if
  % qpsize is around 10-70 (loqo is best for large 1norm SVMs)
  checkseq = { 'loqo','quadprog','qp'};
  i = 1;
  while (i <= length(checkseq)),
    e = exist(checkseq{i});
    if (e==2) | (e==3),
      qpsolver = checkseq{i};
      break;
    end
    i = i+1;
  end
  if isempty(qpsolver),
    error('No quadratic programming solver (QUADPROG,LOQO,QP) found.');
  end
end


% Mind that there may occur problems with the QUADPROG solver. At least in
% early versions of Matlab 5.3 there are severe numerical problems somewhere
% deep in QUADPROG

% Turn off all messages coming from quadprog, increase the maximum number
% of iterations from 200 to 500 - good for low-dimensional problems
if strcmp(qpsolver, 'quadprog') & (dodisplay==0),
  quadprogopt = optimset('Display', 'off', 'MaxIter', 500);
else
  quadprogopt = [];
end

% Actual size of quadratic program during training may not be larger than
% the number of examples
QPsize = min(N, net.qpsize);
chsize = net.chunksize;

% SVMout contains the output of the SVM decision function for each
% example. This is updated iteratively during training.
SVMout = zeros(N, 1);

% Make sure there are no other values in Y than +1 and -1
Y(class1) = 1;
Y(class0) = -1;
if dodisplay>0,
  fprintf('Training set: %i examples (%i positive, %i negative)\n', ...
	  length(Y), length(find(class1)), length(find(class0)));
end

% Start with a vector of zeros for the coefficients alpha, or the
% parameter ALPHA0, if it is given. Those values will be used to perform
% an initial working set selection, by assuming they are the true weights
% for the training set at hand.
if ~any(alpha0),
  net.alpha = zeros([N 1]);
  % If starting with a zero vector: randomize the first working set search
  randomWS = 1;
else
  randomWS = 0;
  % for 1norm SVM: make the initial values conform to the upper bounds
  if ~net.use2norm,
    net.alpha = min(C, alpha0);
  end
end
alphaOld = net.alpha;

if length(find(Y>0))==N,
  % only positive examples
  net.bias = 1;
  net.svcoeff = [];
  net.sv = [];
  net.svind = [];
  net.alpha = zeros([N 1]);
  return;
elseif length(find(Y<0))==N,
  % only negative examples
  net.bias = 1;
  net.svcoeff = [];
  net.sv = [];
  net.svind = [];
  net.alpha = zeros([N 1]);
  return;
end

iteration = 0;
workset = logical(uint8(zeros(N, 1)));
sameWS = 0;
net.bias = 0;

while 1,

  if dodisplay>0,
    fprintf('\nIteration %i: ', iteration+1);
  end

  % Step 1: Determine the Support Vectors.
  [net, SVthresh, SV, SVbound, SVnonbound] = findSV(net, C);
  if dodisplay>0,
    fprintf(['Working set of size %i: %i Support Vectors, %i of them at' ...
	     ' bound C\n'], length(find(workset)), length(find(workset & SV)), ...
	    length(find(workset & SVbound))); 
    fprintf(['Whole training set: %i Support Vectors, %i of them at upper' ...
	     ' bound C.\n'], length(net.svind), length(find(SVbound)));
    if dodisplay>1,
      fprintf('The Support Vectors (threshold %g) are the examples\n', ...
	      SVthresh);
      fprintf(' %i', net.svind);
      fprintf('\n');
    end
  end

  
  % Step 2: Find the output of the SVM for all training examples
  if (iteration==0) | (mod(iteration, net.recompute)==0),
    % Every NET.recompute iterations the SVM output is built from
    % scratch. Use all Support Vectors for determining the output.
    changedSV = net.svind;
    changedAlpha = net.alpha(changedSV);
    SVMout = zeros(N, 1);
    if strcmp(net.kernel, 'linear'),
      net.normalw = zeros([1 d]);
    end
  else
    % A normal iteration: Find the coefficients that changed and adjust
    % the SVM output only by the difference of old and new alpha
    changedSV = find(net.alpha~=alphaOld);
    changedAlpha = net.alpha(changedSV)-alphaOld(changedSV);
  end
  
  if strcmp(net.kernel, 'linear'),
    chunks = ceil(length(changedSV)/chsize);
    % Linear kernel: Build the normal vector of the separating
    % hyperplane by computing the weighted sum of all Support Vectors
    for ch = 1:chunks,
      ind = (1+(ch-1)*chsize):min(length(changedSV), ch*chsize);
      temp = changedAlpha(ind).*Y(changedSV(ind));
      net.normalw = net.normalw+temp'*X(changedSV(ind), :);
    end
    % Find the output of the SVM by multiplying the examples with the
    % normal vector
    SVMout = zeros(N, 1);
    chunks = ceil(N/chsize);
    for ch = 1:chunks,
      ind = (1+(ch-1)*chsize):min(N, ch*chsize);
      SVMout(ind) = X(ind,:)*(net.normalw');
    end
  else
    % A normal kernel function: Split both the examples and the Support
    % Vectors into small chunks
    chunks1 = ceil(N/chsize);
    chunks2 = ceil(length(changedSV)/chsize);
    for ch1 = 1:chunks1,
      ind1 = (1+(ch1-1)*chsize):min(N, ch1*chsize);
      for ch2 = 1:chunks2,
	% Compute the kernel function for a chunk of Support Vectors and
        % a chunk of examples
	ind2 = (1+(ch2-1)*chsize):min(length(changedSV), ch2*chsize);
	K12 = svmkernel(net, X(ind1, :), X(changedSV(ind2), :));
	% Add the weighted kernel matrix to the SVM output. In update
        % cycles, the kernel matrix is weighted by the difference of
        % alphas, in other cycles it is weighted by the value alpha alone.
	coeff = changedAlpha(ind2).*Y(changedSV(ind2));
	SVMout(ind1) = SVMout(ind1)+K12*coeff;
      end
      if dodisplay>2,
	K1all = svmkernel(net, X(ind1,:), X(net.svind,:));
	coeff2 = net.alpha(net.svind).*Y(net.svind);
	fprintf('Maximum error due to matrix partitioning: %g\n', ...
		max((SVMout(ind1)-K1all*coeff2)'));
      end
    end
  end

  
  % Step 3: Compute the bias of the SVM decision function.
  if net.use2norm,
    % The bias can be found from the SVM output for Support Vectors. For
    % those vectors, the output should be 1-alpha/C resp -1+alpha/C.
    workSV = find(SV & workset);
    if ~isempty(workSV),
      net.bias = mean((1-net.alpha(workSV)./C(workSV)).*Y(workSV)- ...
                      SVMout(workSV));
    end
  else
    % normal 1norm SVM:
    % The bias can be found from Support Vector whose value alpha is not at
    % the upper bound. For those vectors, the SVM output should be +1
    % resp. -1.
    workSV = find(SVnonbound & workset);
    if ~isempty(workSV),
      net.bias = mean(Y(workSV)-SVMout(workSV));
    end
  end
  % The nasty case that no SVs to determine the bias have been found.
  % The only sensible thing do to is to leave the bias unchanged.
  if isempty(workSV) & (dodisplay>0),
    disp('No Support Vectors in the current working set.');
    disp('Leaving the bias unchanged.');
  end

  
  % Step 4: Compute the values of the Karush-Kuhn-Tucker conditions
  % of the quadratic program. If no violations of these conditions are
  % found, the optimal solution has been found, and we are finished.
  % KKT describes how correct each example is classified. KKT must be
  %   positive for all examples that are on the correct side and that are
  %     not Support Vectors
  %   0 for all Support Vectors
  %   negative for all examples on the wrong side of the hyperplane
  if net.use2norm,
    KKT = (SVMout+net.bias).*Y-1+net.alpha./C;
    KKTviolations = logical(uint8((SV & (abs(KKT)>net.kkttol)) | ...
                                  (~SV & (KKT<-net.kkttol))));
  else
    KKT = (SVMout+net.bias).*Y-1;
    KKTviolations = logical(uint8((SVnonbound & (abs(KKT)>net.kkttol)) | ...
                                  (SVbound & (KKT>net.kkttol)) | ...
                                  (~SV & (KKT<-net.kkttol))));
  end
  ind = find(KKTviolations & workset);
  if ~isempty(ind),
    % The coefficients alpha for the current working set have just been
    % optimised, non of those should violate the KKT conditions.
    if dodisplay>0,
      fprintf('KKT conditions not met in working set (value %g)', ...
              max(abs(KKT(ind))));
    end
  end
  if dodisplay>0,
    fprintf('%i violations of the KKT conditions.\n', ... 
	    length(find(KKTviolations)));
    fprintf(['(%i violations from positive examples, %i from negative' ...
	     ' examples)\n'], length(find(KKTviolations & class1)), ...
	    length(find(KKTviolations & class0)));
    if (dodisplay>1) & ~isempty(find(KKTviolations)),
      disp('The following examples violate the KKT conditions:');
      fprintf(' %i', find(KKTviolations));
      fprintf('\n');
    end
  end
  % Check how many violations of the KKT-conditions have been found. If
  % none, we are finished.
  if length(find(KKTviolations)) == 0,
    break;
  end
  
  % Step 5: Determine a new working set. To this aim, a linear
  % approximation of the objective function is made. The new working set
  % constitutes of the QPSIZE largest elements of the gradient of the
  % linear approximation. The gradient of the linear approximation can be
  % expressed using the ouput of the SVM on all training examples.
  if net.use2norm,
    searchDir = SVMout+Y.*(net.alpha./C-1);
    set1 = logical(uint8(SV | class0));
    set2 = logical(uint8(SV | class1));
  else
    searchDir = SVMout-Y;
    set1 = logical(uint8((SV | class0) & (~SVbound | class1)));
    set2 = logical(uint8((SV | class1) & (~SVbound | class0)));
  end
  % During the very first iteration: If no initial values for net.alpha
  % are given, perform a random working set selection
  if randomWS,
    searchDir = rand([N 1]);
    set1 = class1;
    set2 = class0;
    randomWS = 0;
  end

  % Step 6: Select the working set.
  % Goal is to select an equal number of examples from set1 and set2
  % (QPsize/2 examples from set1, QPsize/2 from set2). The examples from
  % set1 are the QPsize/2 highest elements of searchDir for set1,
  % the examples from set2 are the QPsize/2 smallest elements of searchDir
  % for set2.
  worksetOld = workset;
  workset = logical(uint8(zeros(N, 1)));
  if length(find(set1 | set2)) <= QPsize,
    workset(set1 | set2) = 1;
    % Less than QPsize examples to select from: Use them all
  elseif length(find(set1)) <= floor(QPsize/2),
    workset(set1) = 1;
    % set1 has less than half QPsize examples: Use all of set1, fill the
    % rest with examples from set2 starting with the ones that have low
    % values for searchDir
    set2 = find(set2 & ~workset);
    [dummy, ind] = sort(searchDir(set2));
    from2 = min(length(set2), QPsize-length(find(workset)));
    workset(set2(ind(1:from2))) = 1;
  elseif length(find(set2)) <= floor(QPsize/2),
    % set2 has less than half QPsize examples: Use all of set2, fill the
    % rest with examples from set1 starting with the ones that have high
    % values for searchDir
    workset(set2) = 1;
    set1 = find(set1 & ~workset);
    [dummy, ind] = sort(-searchDir(set1));
    from1 = min(length(set1), QPsize-length(find(workset)));
    workset(set1(ind(1:from1))) = 1;
  else
    set1 = find(set1);
    [dummy, ind] = sort(-searchDir(set1));
    from1 = min(length(set1), floor(QPsize/2));
    workset(set1(ind(1:from1))) = 1;
    % Use the QPsize/2 highest values for searchDir from set1
    set2 = find(set2 & ~workset);
    % Make sure that no examples are added twice
    [dummy, ind] = sort(searchDir(set2));
    from2 = min(length(set2), QPsize-length(find(workset)));
    workset(set2(ind(1:from2))) = 1;
    % Use the QPsize/2 lowest values for searchDir from set2
  end
  worksetind = find(workset);
  % Workaround for Matlab bug when indexing sparse arrays with logicals:
  % use index set instead
  
  % Emergency exit: If we end up with the same work set in 2 subsequent
  % iterations, something strange must have happened (for example, the
  % accuracy of the QP solver is insufficient as compared to the required
  % precision given by NET.alphatol and NET.kkttol)
  % Exit immediately if 'loqo' is used, since loqo ignores the start
  % values, so another iteration will not improve the results.
  if all(workset==worksetOld),
    sameWS = sameWS+1;
    if ((sameWS==3) | strcmp(qpsolver, 'loqo')),
      warnstr = 'Working set not changed - check accuracy. Exiting.';
      if dodisplay>0,
        disp(warnstr);
      end
      %warning(warnstr); %PPD - this kept going off?
      break;
    end
  else
    sameWS = 0;
  end
  worksize = length(find(workset));
  nonworkset = ~workset;
  if dodisplay>1,
    disp('Working set consists of examples ');
    fprintf(' %i', find(workset));
    fprintf('\n');
  end

  
  % Step 7: Determine the linear part of the quadratic program. We have
  % determined the working set already. The linear term of the quadratic
  % program is made up of all the kernel evaluations  K(Support Vectors
  % outside of the working set, Support Vectors in the working set)
  nonworkSV = find(nonworkset & SV);
  % All Support Vectors outside of the working set
  qBN = 0;
  if length(nonworkSV)>0,
    % The nonworkSV may be a very large matrix. Split up into smaller
    % chunks.
    chunks = ceil(length(nonworkSV)/chsize);
    for ch = 1:chunks,
      % Indices of the current chunk in NONWORKSV
      ind = (1+(ch-1)*chsize):min(length(nonworkSV), ch*chsize);
      % Evaluate kernel function for working set and the current chunk of
      % non-working set
      Ki = svmkernel(net, X(worksetind, :), X(nonworkSV(ind), :));
      % The linear term qBN for the quadratic program is a column vector
      % given by summing up the kernel evaluations multiplied by the
      % corresponding alpha's and the class labels.
      qBN = qBN+Ki*(net.alpha(nonworkSV(ind)).*Y(nonworkSV(ind)));
    end
    qBN = qBN.*Y(workset);
  end
  % Second linear term is a vector of one's
  f = qBN-ones(worksize, 1);

  
  % Step 8: Solve the quadratic program. The quadratic term of the
  % objective function is made of the examples in the working set, the
  % linear term comes from examples outside of the working set. The so
  % found values WORKALPHA replace the old values NET.alpha for the
  % examples in the working set.
  % Quadratic term H is given by the kernel evaluations for the working
  % set
  H = svmkernel(net, X(worksetind,:), X(worksetind,:));
  if net.use2norm,
    % with 2norm of the slack variables: the quadratic program has values
    % 1/C in the diagonal. Additionally, this makes H better conditioned.
    H = H+diag(1./C(workset));
  else
    % Suggested by Mathworks support for improving the condition
    % number. Condition number should should not be much larger than
    % 1/sqrt(eps) to avoid numerical problems. Condition number of H will
    % now be < eps^(-2/3)
    H = H+diag(ones(worksize, 1)*eps^(2/3));
  end
  H = H.*(Y(workset)*Y(workset)');
  % Matrix A for the equality constraint
  A = Y(workset)';
  % If there are Support Vectors outside of the working set, the equality
  % constraint must give the weighted class labels of all these
  % vectors. Otherwise the equality constraint gives zero.
  if length(nonworkSV)>0,
    eqconstr = -net.alpha(nonworkSV)'*Y(nonworkSV);
  else
    eqconstr = 0;
  end
  % Lower and upper bound for the coefficients alpha in the
  % current working set
  VLB = zeros(worksize, 1);
  if net.use2norm,
    % no upper bound in the 2norm case
    VUB = [];
  else
    % normal 1norm SVM: error weights C are the upper bounds
    VUB = C(workset);
  end
  tic;
  % Solve the quadratic program with 1 equality constraint.
  % Initial guess for the solution of the QP problem.
  startVal = net.alpha(workset);
  switch qpsolver
    case 'quadprog'
      workalpha = quadprog(H, f, [], [], A, eqconstr, VLB, VUB, startVal, ...
                           quadprogopt);
      case 'qp'
      workalpha = qp(H, f, A, eqconstr, VLB, VUB, startVal, 1);
    case 'loqo'
      if isempty(VUB),
        % LOQO crashes if upper bound is missing
        % Use a relatively low value (instead of Inf) for faster
        % convergence
        VUB = repmat(1e7, size(VLB));
      end
      workalpha = loqo(H, f, A, eqconstr, VLB, VUB, startVal, 1);
  end
  t = toc;
  if dodisplay>1,
    fprintf('QP subproblem solved after %i minutes, %2.1f seconds.\n', ...
	  floor(t/60), mod(t, 60));
  end
  % Sometime QUADPROG returns a solution with small imaginary part
  % (usually with ill-posed problems, badly conditioned H)
  if any(imag(workalpha)>0),
    warning(['The QP solver returned a complex solution. '...
             'Check condition number cond(H).']);
    workalpha = real(workalpha);
  end
  % Update the newly found coefficients in NET.alpha
  alphaOld = net.alpha;
  net.alpha(workset) = workalpha;
  
  iteration = iteration+1;
end

% Finished! Store the Support Vectors and the coefficient given by
% NET.alpha and the corresponding label.
net.svcoeff = net.alpha(net.svind).*Y(net.svind);
net.sv = X(net.svind, :);

if dodisplay>0,
  fprintf('\n\n\nTraining finished.\n');
  disp('Information about the trained Support Vector Machine:');
  svmstat(net,1);
  % output statistics over SVs and separating hyperplane
end



function [net, SVthresh, SV, SVbound, SVnonbound] = findSV(net, C)
% FINDSV - Select the Support Vectors from the current coefficients NET.alpha

% Threshold for selecting Support Vectors
maxalpha = max(net.alpha);
if maxalpha > net.alphatol,
  % For most cases, net.alphatol is a reasonable choice (approx 1e-2)
  SVthresh = net.alphatol;
else
  % For complex kernel on small data sets: all alphas will be very small.
  % Use the mean between the minimum and maximum logarithm of values
  % NET.alpha as a threshold.
  SVthresh = exp((log(max(eps,maxalpha))+log(eps))/2);
end
% All examples that have a value of NET.alpha above this threshold are
% assumed to be Support Vectors.
SV = logical(uint8(net.alpha>=SVthresh));
% All Support Vectors that have a value at their upper bound C
if net.use2norm,
  % There is no such thing in the 2norm case!
  SVbound = logical(repmat(uint8(0), size(net.alpha)));
else
  SVbound = logical(uint8(net.alpha>(C-net.alphatol)));
end
% The Support Vectors not at the upper bound
SVnonbound = SV & (~SVbound);
% The actual indices of the Support Vectors in the training set
net.svind = find(SV);
