/* Filename: loqo.c
 * 
 * Description: MATLAB interface for LOQO Optimiser
 * 
 * Comments: Quadratic and Linear Programming
 * 
 * Author: Steve Gunn (S.R.Gunn@ecs.soton.ac.uk)
 */

#include <math.h>
#include <stdio.h>
#include "mex.h"
#include "pr_loqo.h"

#define Inf 1e30

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
    double *c=NULL, *b=NULL, *A=NULL, *Q=NULL, *H=NULL, *l=NULL, *u=NULL, *x=NULL, *lambda=NULL, *x0=NULL, *primal=NULL, *dual=NULL;
    double *tmpdp=NULL;
    double big=Inf;
    unsigned int neq=0;
    long nmat=0, mmat=0;
    long how=0;
    int i;
    unsigned int verb = 0;
    double sigfig_max = 8;
    int counter_max = 100000;
    double margin = 0.95;
    double bound = 10; 
    int restart = 0;

    static char *str[] = {
		"STILL_RUNNING",
		"OPTIMAL_SOLUTION",
		"SUBOPTIMAL_SOLUTION",
		"ITERATION_LIMIT",
		"PRIMAL_INFEASIBLE",
		"DUAL_INFEASIBLE",
		"PRIMAL_AND_DUAL_INFEASIBLE",
		"INCONSISTENT",
		"PRIMAL_UNBOUNDED",
		"DUAL_UNBOUNDED",
		"TIME_LIMIT"};

    if (nrhs > 9 || nrhs < 1) {
	    mexErrMsgTxt("Usage: [x,lambda,how] = loqo(H,c,A,b,l,u,x0,neqcstr,verbosity)");
	    return;
    }
    switch (nrhs) {
    case 9:
		if (mxGetM(prhs[8]) != 0 || mxGetN(prhs[8]) != 0) {
		    if (!mxIsNumeric(prhs[8]) || mxIsComplex(prhs[8]) 
		     ||  mxIsSparse(prhs[8])
		     || !(mxGetM(prhs[8])==1 && mxGetN(prhs[8])==1)) {
			 mexErrMsgTxt("Ninth argument (display) must be "
				      "an integer scalar.");
			 return;
		    }
		    verb = (unsigned int)*mxGetPr(prhs[8]);
	    }
    case 8:
		if (mxGetM(prhs[7]) != 0 || mxGetN(prhs[7]) != 0) {
		    if (!mxIsNumeric(prhs[7]) || mxIsComplex(prhs[7]) 
		     ||  mxIsSparse(prhs[7])
		     || !(mxGetM(prhs[7])==1 && mxGetN(prhs[7])==1)) {
			 mexErrMsgTxt("Eighth argument (neqcstr) must be "
				      "an integer scalar.");
			 return;
		    }
		    neq = (unsigned int)*mxGetPr(prhs[7]);
	    }
    case 7:
		if (mxGetM(prhs[6]) != 0 || mxGetN(prhs[6]) != 0) {
			if (!mxIsNumeric(prhs[6]) || mxIsComplex(prhs[6]) 
			 ||  mxIsSparse(prhs[6])
			 || !mxIsDouble(prhs[6]) 
			 ||  mxGetN(prhs[6])!=1 ) {
			 mexErrMsgTxt("Seventh argument (x0) must be "
					  "a column vector.");
			 return;
			}
			x0 = mxGetPr(prhs[6]);
			nmat = mxGetM(prhs[6]);
        }
    case 6:
	    if (mxGetM(prhs[5]) != 0 || mxGetN(prhs[5]) != 0) {
		    if (!mxIsNumeric(prhs[5]) || mxIsComplex(prhs[5]) 
		     ||  mxIsSparse(prhs[5])
		     || !mxIsDouble(prhs[5]) 
		     ||  mxGetN(prhs[5])!=1 ) {
			 mexErrMsgTxt("Sixth argument (u) must be "
				      "a column vector.");
			 return;
		    }
		    if (nmat != 0 && nmat != mxGetM(prhs[5])) {
			 mexErrMsgTxt("Dimension error (arg 6 and later).");
			 return;
		    }
		    u = mxGetPr(prhs[5]);
			nmat = mxGetM(prhs[5]);
	    }
    case 5:
	    if (mxGetM(prhs[4]) != 0 || mxGetN(prhs[4]) != 0) {
		    if (!mxIsNumeric(prhs[4]) || mxIsComplex(prhs[4]) 
		     ||  mxIsSparse(prhs[4])
		     || !mxIsDouble(prhs[4]) 
		     ||  mxGetN(prhs[4])!=1 ) {
			 mexErrMsgTxt("Fifth argument (l) must be "
				      "a column vector.");
			 return;
		    }
		    if (nmat != 0 && nmat != mxGetM(prhs[4])) {
			 mexErrMsgTxt("Dimension error (arg 5 and later).");
			 return;
		    }
		    l = mxGetPr(prhs[4]);
			nmat = mxGetM(prhs[4]);
	    }
    case 4:
		if (mxIsEmpty(prhs[3]))
		{ /* No Constraints */
			mmat = 0;
		}
		else
		{ /* Constraints */
			if (mxGetM(prhs[3]) != 0 || mxGetN(prhs[3]) != 0) {
				if (!mxIsNumeric(prhs[3]) || mxIsComplex(prhs[3]) 
				 ||  mxIsSparse(prhs[3])
				 || !mxIsDouble(prhs[3]) 
				 ||  mxGetN(prhs[3])!=1 ) {
				 mexErrMsgTxt("Fourth argument (b) must be "
						  "a column vector.");
				 return;
				}
				if (mmat != 0 && mmat != mxGetM(prhs[3])) {
				 mexErrMsgTxt("Dimension error (arg 4 and later).");
				 return;
				}
				b = mxGetPr(prhs[3]);
			}
		}
    case 3:
		if (mxIsEmpty(prhs[2]))
		{ /* No Constraints */
			if (mmat != 0) {
				mexErrMsgTxt("Dimension error (arg 3 and later).");
				return;
			}
		}
		else
		{ /* Constraints */
			if (mxGetM(prhs[2]) != 0 || mxGetN(prhs[2]) != 0) {
				if (!mxIsNumeric(prhs[2]) || mxIsComplex(prhs[2]) 
				 || mxIsSparse(prhs[2]) ) {
				 mexErrMsgTxt("Third argument (A) must be "
						  "a matrix.");
				 return;
				}
				if (mmat != 0 && mmat != mxGetM(prhs[2])) {
				 mexErrMsgTxt("Dimension error (arg 3 and later).");
				 return;
				}
				if (nmat != 0 && nmat != mxGetN(prhs[2])) {
				 mexErrMsgTxt("Dimension error (arg 3 and later).");
				 return;
				}
				mmat = mxGetM(prhs[2]);
				nmat = mxGetN(prhs[2]);
				A = mxGetPr(prhs[2]);
			}
		}
		tmpdp = (double *)malloc((nmat+mmat)*sizeof(double));
		for(i=0;i<nmat;i++) tmpdp[i] = (l[i] < -Inf ? -Inf : l[i]);
		l = tmpdp;
		tmpdp = (double *)malloc((nmat+mmat)*sizeof(double));
		for(i=0;i<nmat;i++) tmpdp[i] = (u[i] > Inf ? Inf : u[i]);
		u = tmpdp;
		/* Equality constraints */
		for(i=nmat;i<(int)(nmat+neq);i++) { l[i] = u[i] = 0; }
		/* InEquality constraints */
		for(i=nmat + neq;i<nmat+mmat;i++) { l[i] = -Inf; u[i] = 0; }
    case 2:
	    if (mxGetM(prhs[1]) != 0 || mxGetN(prhs[1]) != 0) {
		    if (!mxIsNumeric(prhs[1]) || mxIsComplex(prhs[1]) 
		     ||  mxIsSparse(prhs[1])
		     || !mxIsDouble(prhs[1]) 
		     ||  mxGetN(prhs[1])!=1 ) {
			 mexErrMsgTxt("Second argument (c) must be "
				      "a column vector.");
			 return;
		    }
		    if (nmat != 0 && nmat != mxGetM(prhs[1])) {
			 mexErrMsgTxt("Dimension error (arg 2 and later).");
			 return;
		    }
		    c = mxGetPr(prhs[1]);
		    nmat = mxGetM(prhs[1]);
	    }
    case 1:
		if (mxIsEmpty(prhs[0]))
		{ /* Linear Program */
			H = (double *)calloc(nmat*nmat,sizeof(double));
		}
		else
		{ /* Quadratic Program */
	        if (mxGetM(prhs[0]) != 0 || mxGetN(prhs[0]) != 0) {
				if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0]) 
				 || mxIsSparse(prhs[0]) ) {
				 mexErrMsgTxt("First argument (H) must be "
						  "a matrix.");
				 return;
				}
				if (nmat != 0 && nmat != mxGetM(prhs[0])) {
				 mexErrMsgTxt("Dimension error (arg 1 and later).");
				 return;
				}
				if (nmat != 0 && nmat != mxGetN(prhs[0])) {
				 mexErrMsgTxt("Dimension error (arg 1 and later).");
				 return;
				}
				nmat = mxGetN(prhs[0]);
				Q = mxGetPr(prhs[0]);
				H = (double *)calloc(nmat*nmat,sizeof(double));
				for(i=0;i<nmat*nmat;i++) H[i] = Q[i];
			}
		}
	    break;
    }

    if (nlhs > 3 || nlhs < 1) {
	    mexErrMsgTxt("Usage: [x,lambda,how] = loqo(H,c,A,b,l,u,x0,neqcstr,verbosity)");
	    return;
    }

	primal = (double *)calloc((3*nmat),sizeof(double));	
	dual = (double *)calloc((mmat+2*nmat),sizeof(double));	

    how = pr_loqo(nmat, mmat, c, H, A, b, l, u, primal, dual, verb, sigfig_max, counter_max, margin, bound, restart);

    switch (nlhs) {
    case 3:
	    plhs[2] = mxCreateString(str[how]);
    case 2:
	    plhs[1] = mxCreateDoubleMatrix(mmat, 1, mxREAL);
	    lambda = mxGetPr(plhs[1]);
		for(i=0; i<mmat; i++) lambda[i] = dual[i];
    case 1:
	    plhs[0] = mxCreateDoubleMatrix(nmat, 1, mxREAL);
	    x = mxGetPr(plhs[0]);
		for(i=0; i<nmat; i++) x[i] = primal[i];
	    break;
    }

	/* Free up memory */
	free(l);
	free(u);
	free(primal);
	free(dual);
	free(H);

}
