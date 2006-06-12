function [Y, Y1, Y2] = ecocfwd(net, X)
% ECOCFWD - Forward propagation for a set of learners with ECOC
% 
%   Y = ECOCFWD(NET, X)
%   Given an error correcting output code wrapper NET, the class
%   predictions Y for a matrix of examples X (one example per row) are
%   computed. Y(I) is the class label for X(I,:), Y(I) is a number in the
%   range 1...NET.NCLASSES
%   [Y, Y1, Y2] = ECOCFWD(NET, X)
%   also returns a matrix Y1 of size [SIZE(X,1) NET.NCLASSES] that
%   contains the Hamming distance of example X(I,:) to the codeword for
%   class J in Y1(I,J). Y2 is a matrix of size [SIZE(X,1) NET.NBITS] with
%   the outputs of all bit learners for each example.
%
%   See also ECOC, ECOCTRAIN, ECOCLOAD
%

% 
% Copyright (c) by Anton Schwaighofer (2001)
% $Revision: 1.2 $ $Date: 2002/01/07 17:59:26 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

error(nargchk(2, 2, nargin));
error(consist(net, 'ecoc'));
if ~(iscell(net.learner) & length(net.learner)==net.nbits),
  error('NET.LEARNER must be a cell array with individual bit learners');
end

[N, d] = size(X);
% Matrix of outputs for each learner and each test point
Y2 = zeros([N net.nbits]);
for i = 1:net.nbits,
  if isa(net.learner{i}, 'numeric'),
    % Handle trivial +1/-1 hypothesis
    Y2(:,i) = net.learner{i};
  else
    % Compute output of each bit-learner for the test set
    fwdFunc = [net.learner{i}.type 'fwd'];
    Y2i = feval(fwdFunc, net.learner{i}, X);
    % For learners that produce 0/1 outputs: rescale to -1/+1
    if net.use01targets,
      Y2i = Y2i*2-1;
    end
    Y2(:,i) = Y2i;
  end
end
% Matrix of distance to each codeword for each test point
Y1 = zeros([N net.nclasses]);
for i = 1:net.nclasses,
  % Compute L1 distance of each line Y2(j,:) to codeword i
  Y1(:,i) = sum(abs(Y2-repmat(net.code(i,:), [N 1])), 2);
end
% Output: predict the class with minimum L1 distance
[dummy, Y] = min(Y1, [], 2);
