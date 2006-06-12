function [fracSV, normW, nbSV, nbBoundSV, posSV, negSV, posBound, negBound] = svmstat(net, doDisplay)
% SVMSTAT - Support Vector Machine statistics
% 
%   [FRACSV,NORMW,NBSV,NBBOUNDSV,NBPOSSV,NBNEGSV,NBPOSBOUND,NBNEGBOUND]
%    = SVMSTAT(NET) 
%   For a trained SVM in structure NET the most important figures are
%   computed, that are
%   FRACSV (the fraction of Support Vectors in the training set)
%   NORMW (the norm of the separating hyperplane)
%   NBSV (the total number of Support Vectors)
%   NBBOUNDSV (number of SVs where the coefficient is at the upper bound,
%     these are the misclassified training examples)
%   POSSV (indices of Support Vectors from positive examples)
%   NEGSV (indices of Support Vectors from negative examples)
%   POSBOUND (indices of SVs from positive examples that are at the bound)
%   NEGBOUND (indices of SVs from negative examples that are at the bound)
%   If the SVM has been trained with the 2norm of the errors (slack
%   variables), then NBBOUNDSV, POSBOUND and NEGBOUND will be 0 resp. [].
%   All the indices are for use in NET.sv respectively NET.svind
%   SVMSTAT(NET,1) prints out all that values.
%
%   See also
%   SVM, SVMTRAIN, SVMFWD
%

% 
% Copyright (c) Anton Schwaighofer (2001)
% $Revision: 1.3 $ $Date: 2001/02/14 09:05:20 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

if nargin<2,
  doDisplay = 0;
end

nbSV = 0;
fracSV = 0;
nbPosSV = 0;
nbNegSV = 0;
normW = 0;
if (net.nbexamples<=0) | (size(net.svcoeff,1)==0),
  warning('The given SVM has not been trained yet');
  return;
end

if isfield(net, 'use2norm'),
  use2norm = net.use2norm;
else
  use2norm = 0;
end


posSV = find(net.svcoeff>0);
negSV = find(net.svcoeff<0);
% Indices of the positive and negative examples that have become Support
% Vectors
nbPosSV = length(posSV);
nbNegSV = length(negSV);
nbSV = nbPosSV+nbNegSV;
fracSV = nbSV/net.nbexamples;
if (nargout<2) & ~doDisplay,
  % shortcut to avoid the expensive computation of the norm
  return;
end

% Extract the upper bound for the examples that are Support Vectors
if length(net.c(:))==1,
  C = repmat(net.c, [length(net.svcoeff) 1]);
  % The same upper bound for all examples
elseif length(net.c(:))==2,
  C = zeros([length(net.svcoeff) 1]);
  C(posSV) = net.c(1);
  C(negSV) = net.c(2);
  % Different upper bounds C for the positive and negative examples
else
  C = net.c(net.svind);
end

if isfield(net, 'alphatol'),
  tol = net.alphatol;
else
  tol = net.accur;
  % old versions of SVM used only one field NET.accur
end
if use2norm,
  posBound = [];
  negBound = [];
else  
  posBound = find(abs(net.svcoeff(posSV))>(C(posSV)-tol));
  negBound = find(abs(net.svcoeff(negSV))>(C(negSV)-tol));
end
nbPosBound = length(posBound);
nbNegBound = length(negBound);
nbBoundSV = nbPosBound+nbNegBound;

if strcmp(net.kernel, 'linear') & isfield(net, 'normalw'),
  normW = norm(net.normalw);
  % linear kernel: norm of the separating hyperplane can be computed
  % directly
else
  if use2norm,
    alpha = abs(net.svcoeff);
    % For the 2norm SVM, the norm of the hyperplance is easy to compute
    normW = sqrt(sum(alpha)+sum((alpha.^2)./C));
  else
    % normal 1norm SVM:
    [dummy, svOutput] = svmfwd(net, net.sv);
    svOutput = svOutput-net.bias;
    % norm of the hyperplane is computed using the output
    % of the SVM for all Support Vectors without the bias term
    normW = sqrt(net.svcoeff'*svOutput);
    % norm is basically the quadratic term of the SVM objective function
  end
end

if doDisplay,
  fprintf('Number of Support Vectors (SV): %i\n', nbSV);
  fprintf('  (that is a fraction of %2.3f%% of the training examples)\n', ...
	  100*fracSV);
  if ~use2norm,
    fprintf('  %i of the SV have a coefficient ALPHA at the upper bound\n', ...
            nbBoundSV);
  end
  fprintf('  %i Support Vectors from positive examples\n', nbPosSV);
  if ~use2norm,
    fprintf('     %i of them have a coefficient ALPHA at the upper bound\n', ...
            nbPosBound);
  end
  fprintf('  %i Support Vectors from negative examples\n', nbNegSV);
  if ~use2norm,
    fprintf('     %i of them have a coefficient ALPHA at the upper bound\n', ...
            nbNegBound);
  end
  fprintf('Norm of the separating hyperplane: %g\n', normW);
end


