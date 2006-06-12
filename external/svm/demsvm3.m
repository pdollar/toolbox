function demsvm3()
% DEMSVM3 - Sample code for the use of SVMCV (parameter selection) 
% 
%   This function is not meant to be executed!
%
%   Given a data set with examples X and labels Y.
%   First, create the SVM structure: Use RBF kernel with initial
%   parameter value 1.
%     NET = SVM(size(X, 2), 'rbf', [1], 1);
%   Select best RBF parameter in the range [0.1 10]:
%     NET = SVMCV(NET, X, Y, [0.1 10]);
%   Make a more accurate search in the parameter space:
%     NET = SVMCV(NET, X, Y, [0.4 0.8], 1.1);
%   If you want to test only a few points:
%     NET = SVMCV(NET, X, Y, [0.1 0.5 1 5 10]);
%   The default setting is to use 10fold cross validation. You might want
%   to use 7fold CV, by running
%     NET = SVMCV(NET, X, Y, [0.1 0.5 1 5 10], 0, 7);
%   If you are lucky and have some extra validation data XVAL, YVAL
%   available and want to set the parameter based on the validation set
%   error:
%     NET = SVMCV(NET, X, Y, [0.1 0.5 1 5 10], 0, 1, XVAL, YVAL);
%
% See also SVM, SVMTRAIN
%

% 
% Copyright (c) by Anton Schwaighofer (2001)
% $Revision: 1.1 $ $Date: 2001/08/30 13:23:41 $
% mailto:anton.schwaighofer@gmx.net
% 
% This program is released unter the GNU General Public License.
% 

fprintf(['This function is not meant to be executed!\n' ...
         'Have a look at the help text instead...\n']);
