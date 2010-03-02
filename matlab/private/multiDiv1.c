#include "mex.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef MATLAB_MEX_FILE
#include "blas.h"
#else
void dgels_(const char *trans, const int *M, const int *N, const int *nrhs,
double *A, const int *lda, double *b, const int *ldb, double *work, const
int * lwork, int *info);
#endif

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray * prhs[]) {
	/* find X such that A*X=B in batches */
	/* Retrieve the useful data */
	double *A = mxGetPr(prhs[0]);
	const mwSize *dimArrayA = mxGetDimensions(prhs[0]);
	int row = dimArrayA[0], colA = dimArrayA[1], nSet = dimArrayA[2];
	double *B = mxGetPr(prhs[1]);
	const mwSize *dimArrayB = mxGetDimensions(prhs[1]);
	int colB;
	int nCase = (int) (*( (double * ) mxGetPr(prhs[2]) ));

	switch (nCase) {
		case 1:
		case 2: {
			colB = dimArrayB[1];
			const mwSize dimArrayX[3] = {colA, colB, nSet};
			plhs[0] = mxCreateNumericArray(3, dimArrayX, mxDOUBLE_CLASS, mxREAL);
			break;
		}
		case 3:
			colB = 1;
			fprintf(stderr,"%i %i %i %i\n",row, colA, colB, nSet);
			plhs[0] = mxCreateDoubleMatrix(colA, nSet, mxREAL);
			break;
	}

	/* Create the output data */
	double *X = (double *) mxGetPr(plhs[0]);

	/* define data for the least squares */
	char *trans = "N";
	int info;

	/* create the work data */
	double *work = (double*)malloc( 10*sizeof(double) );
	int lwork = -1;
	dgels_( trans, &row, &colA, &colB, A,
				&row, B, &row, work, &lwork, &info );
	lwork = (int) work[0];
	
	free(work);
	work = (double*)malloc( lwork*sizeof(double) );

	/* create the temporary data */
	double *ATmp = (double*)malloc( row*colA*sizeof(double) );
	double *BTmp = (double*)malloc( row*colB*sizeof(double) );

	/* solve A(:,:,i)*X=B(:,:,i) */
	int i;
	for(i=0; i<nSet; ++i) {
		/* copy the submatrices to ATmp and BTmp */
		memcpy(ATmp, A+i*(row*colA), row*colA*sizeof(double));
		switch (nCase) {
			case 1:
				memcpy(BTmp, B, row*colB*sizeof(double));
				break;
			case 2:
			case 3:
				memcpy(BTmp, B+i*(row*colB), row*colB*sizeof(double));
				break;
		}
		/* proceed with the least squares */
		dgels_( trans, &row, &colA, &colB, ATmp,
					&row, BTmp, &row, work, &lwork, &info );
		/* copy back the result to X */
		int j;
		for(j=0; j<colB; ++j)
			memcpy(X+i*(colA*colB) + j*colA, BTmp+j*row,
				colA*sizeof(double));
	}
	
	/* free memory */
	free(ATmp);
	free(BTmp);
	free(work);
}
