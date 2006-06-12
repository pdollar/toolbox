function net = ecoctrain(net, learner1, X, Y, varargin)
% ECOCTRAIN - Train multi class problem with ECOC
% 
%   NET = ECOCTRAIN(NET, LEARNER, X, Y)
%   For an error correcting output code wrapper NET, the bit learners
%   are trained given training data X (one example per row) with class
%   labels Y. Y(I) is the class label for X(I,:), Y(I) is a number in the
%   range 1...NET.NCLASSES
%   If LEARNER has size [1 1], it is assumed to be an initialised
%   template learning algorithm, for example SVM or MLP. This template
%   with its parameter setting is used to train all NET.NBITS bit
%   learners. If LEARNER is a cell array of length NET.NBITS, LEARNER{I}
%   is used as the template for bit learner I.
%   LEARNER is assumed to be standard Netlab structure. The name of the
%   training procedure is [LEARNER{I}.TYPE 'FWD']. Any additional
%   parameters ECOCTRAIN(NET, LEARNER, X, Y, VARARGIN) are passed on
%   directly to  the training procedure.
%   
%   See also ECOC, ECOCLOAD, ECOCFWD.
%

% 
% Copyright (c) by Anton Schwaighofer (2001)
% $Revision: 1.2 $ $Date: 2002/01/07 17:58:21 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

error(nargchk(4, Inf, nargin));
error(consist(net, 'ecoc'));

if all(size(learner1)==[1 1]) & isstruct(learner1),
  [learner{1:net.nbits}] = deal(learner1);
elseif length(learner1)==net.nbits & iscell(learner1),
  learner = learner1;
else
  error(['Input parameter LEARNER must be a cell array of length NET.NBITS' ...
         ' or a structure array']);
end

if any((Y<1) | (Y>net.nclasses))
  error('Invalid class labels');
end
if any((net.code~=1) & (net.code~=-1) & (net.code~=0)),
  error('Invalid code matrix. Entries must be +1, -1 or 0.');
end
if ~all(size(net.code)==[net.nclasses, net.nbits]),
  error('Code matrix must be of size [number of classes, number of bits]');
end

for i = 1:net.nbits,
  if net.verbosity>0, 
    fprintf('Training for code bit %i (out of %i)\n', i, net.nbits);
  end
  % Code column i gives the targets for learner i
  codei = net.code(:,i);
  Yi = Y;
  for j = 1:net.nclasses,
    Yi(Y==j) = codei(j);
  end
  % Squash out examples of those classes that have a 0 entry in the
  % current code bit
  Yi0 = Yi(Yi~=0);
  % Code trivial hypothesis directly
  if all(Yi0==-1),
    learner{i} = -1;
  elseif all(Yi0==1),
    learner{i} = 1;
  else
    % If necessary, convert the -1/+1 targets to 0/+1.
    if net.use01targets,
      Yi0 = (Yi0>0);
    end
    trainFunc = [learner{i}.type 'train'];
    learner{i} = feval(trainFunc, learner{i}, X(Yi~=0,:), Yi0, varargin{:});
  end
end
net.learner = learner;
