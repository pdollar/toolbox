function net = ecoc(nclasses, nbits, code, use01targets)
% ECOC - Create wrapper for error correcting output codes
% 
%   NET = ECOC(NCLASSES, NBITS)
%   Initialize a wrapper for error correcting output codes for a
%   multiclass problem with NCLASSES classes. Each class is associated
%   a bit string with NBITS bits.
%   ECOC(NCLASSES, NBITS, CODE) sets the code matrix to be CODE. A valid
%   code matrix is of size [NCLASSES, NBITS]. Each entry may either be
%   +1, -1 or 0, where 0 means that examples of a certain class are not
%   used in training the correspoding classifier.
%   ECOC(NCLASSES, NBITS, CODE, USE01TARGETS)
%   By default, it is assumed that the individual bit learners accept
%   targets with values +1 and -1. By using USE01TARGETS==1, the bit
%   learners are given targets with values 0 and 1 (for example, for
%   multi layer perceptrons MLP with 'logistic' loss function).
%
%   See also ECOCTRAIN, ECOCLOAD, ECOCFWD, MLP
%

% 
% Copyright (c) by Anton Schwaighofer (2001)
% $Revision: 1.3 $ $Date: 2002/01/07 20:53:17 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

error(nargchk(2, 4, nargin));
if nargin<4,
  use01targets = 0;
end
if nargin<3,
  code = zeros([nclasses nbits]);
end
if ~all(size(code)==[nclasses, nbits]),
  error('Code matrix must be of size [number of classes, number of bits]');
end
net.type = 'ecoc';
net.nclasses = nclasses;
net.nbits = nbits;
net.code = code;
net.learner = [];
net.use01targets = use01targets;
net.codepath = '';
net.verbosity = 1;
