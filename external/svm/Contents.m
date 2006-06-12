% Support Vector Machine toolbox
% Version 2.51, January 2002
% 
% SVM functions:
%    svm - create a support vector machine classifier
%    svmfwd - forward propagation through svm
%    svmkernel - compute svm kernel function
%    svmtrain - train a svm using decomposition algorithm
%    svmstat - svm statistics
%    svmcv - simple parameter selection via cross validation
%
% Extension to multi class case via error correcting output codes (ECOC)
%    ecoc - create a ECOC wrapper
%    ecocload - load code matrix from archive ecoc-codes.tar.gz
%    ecoctrain - train ECOC classifier
%    ecocfwd - forward propagation through ECOC classifier
%
% Data files:
%    ecoc-codes.tar.gz - Tom Dietterich's collection of code matrices
%
% Files for PRLOQO code:
%    loqo.c  (C) by Steve Gunn
%    pr_loqo.c  (C) by Alex Smola
%    pr_loqo.h  (C) by Alex Smola
%
% Demo programs:
%    demsvm1 - demonstrate basic support vector machine classification
%    demsvm2 - demonstrate advanced support vector machine features
%    demsvm3 - sample code for parameter selection via cross validation
%    demecoc1 - solving a simple multi-class problem with SVMs
%
% Copyright (c) Anton Schwaighofer (2002) 
% mailto:anton.schwaighofer@gmx.net
%
% This program is released unter the GNU General Public License.
%

%
% $Revision: 1.10 $ $Date: 2002/01/09 12:12:23 $
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
% 

