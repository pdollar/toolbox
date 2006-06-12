
Support Vector Machine toolbox for Matlab
Version 2.51, January 2002


Contents.m contains a brief description of all parts of this toolbox.

Main features are:

- Except for the QP solver, all parts are written in plain Matlab. This
  guarantees for easy modification. Special kinds of kernels that require
  much computation (such as the Fisher kernel, which is based on a model of
  the data) can easily be incorporated.

- Extension to multi-class problems via error correcting output codes is
  included.

- Unless many other SVM toolboxes, this one can handle SVMs with 1norm
  or 2norm of the slack variables.

- For both cases, a decomposition algorithm is implemented for the training
  routine, together with efficient working set selection strategies.
  The training algorithm uses many of the ideas proposed by Thorsten
  Joachims for his SVMlight. It thus should exhibit a scaling behaviour that
  is comparable to SVMlight.



This toolbox optionally makes use of a Matlab wrapper for an interior point
code in LOQO style (Matlab wrapper by Steve Gunn, LOQO code by Alex Smola).
To compile the wrapper, run
  mex loqo.c pr_loqo.c
Make sure you have turned on the compiler optimizations in mexopts.sh
The LOQO code can be retrieved from
  http://www.kernel-machines.org/code/prloqo.tar.gz
The wrapper comes directly from Steve Gunn.


Copyright (c) Anton Schwaighofer (2001) 
mailto:anton.schwaighofer@gmx.net

This program is released unter the GNU General Public License.
See License.txt for details.

Changes in version 2.51:
- fixed bug in SVMTRAIN that prevented correct initialisation with
  NET.recompute==Inf

Changes in version 2.5:
- Handling of multi-class problems with ECOC
- NET.recompute is set to Inf by default, thus all training is done
  incrementally by default.
- Handling the case of all training examples being -1 or +1 correctly

Changes in version 2.4:
- Better selection of the initial working set
- Added workaround for a (rare) Matlab quadprog bug with badly conditioned
  matrices
- There is now a new kernel function 'rbffull' where a full matrix
  ("covariance matrix") C may be put into an RBF kernel:
  K(X1,X2) = exp(-(X1-X2)'*C*(X1-X2))

Changes in version 2.3:
- slightly more compact debug output

Changes in version 2.2:
- New default values for parameter qpsize that make the whole toolbox
  *much* faster
- Workaround for a Matlab bug with sparse matrices
- Changed the definition of the RBF-Kernel: from |x-y|^2/(2*nin*param^2)
  to |x-y|^2/(nin*param). This means that all parameter settings for old
  versions need to be updated!
- A few minor things I can't remember

Changes in version 2.1:
Fixed a nasty bug at the KKT check

Changes in version 2.0:
All relevant routines have been updated to allow the use of a SVM with
2norm of the slack variables (NET.use2norm==1).
