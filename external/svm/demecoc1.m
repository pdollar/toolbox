function demecoc1()
% DEMECOC1 - Demo program for error correcting output codes
% 
%   DEMECOC1
%   Show a simple multi class problem (VOWEL-CONTEXT from UCI archive)
%   with ECOC and Support Vector Machine as the base learner.
%
%   See also ECOC, ECOCLOAD, ECOCTRAIN, ECOCFWD
%

% 
% Copyright (c) by Anton Schwaighofer (2001)
% $Revision: 1.2 $ $Date: 2002/01/07 20:52:34 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

load('demecoc1.mat', 'Xtrain', 'Ytrain', 'Xtest', 'Ytest');
[N, d] = size(Xtrain);

% 11 class problem, solve with 14 bit code
net = ecoc(11,14);
net.verbosity = 2;
% Load code matrix from given file
net = ecocload(net, 'code14-11');

% For a 12 class problem with 15 bit code, Dietterichs archive provides a
% code. This code can be loaded by
% net = ecoc(12, 15);
% net.codepath = '/some/path/to/' where ecoc-codes.tar.gz resides
% net = ecocload(net);

% Initialise an instance of the base learning algorithm
learner = svm(d, 'rbf', 0.5, 1);
learner.recompute = Inf;
% Train the individual bit learners, all starting out from the parameter
% setting in the SVM structure LEARNER
warning off;
fprintf('Starting the training.\n');
fprintf('This may take a while, since we need to train one SVM per bit ...\n');
net = ecoctrain(net, learner, Xtrain, Ytrain+1);
pred = ecocfwd(net, Xtest);
fprintf('Classification result on the test set: %i out of %i correct\n', ...
        length(find((Ytest+1)==pred)), length(Ytest));

