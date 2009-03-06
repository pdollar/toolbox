/***************************************************************************
* Piotr's Image&Video Toolbox      Version 2.2
* Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
***************************************************************************/
#include "mex.h"

/***************************************************************************
* Row non-linear seperable filter - blocksum (see nlfiltersep.m)
* Given an mxn array A and a distance d, sums every d elements along
* the FIRST dimension - ie along each ROW. This is a BLOCK operations.
*  x = nlfiltersep_blocksum( [ 1 9; 5 9; 0 0; 4 8; 7 3; 2 6], 3 )
*  y = [6 18; 13 17]; x-y
***************************************************************************/
void nlfiltersep_blocksum( const double *A, double *B, const int d, const int mRows, const int nCols )
{
	int i, a, b, j, block, nBlock; double m;
	nBlock = mRows / d;
	for( j=0; j<nCols; j++ ) {
		a=mRows*j; b=nBlock*j;
		for( block=0; block<nBlock; block++ ) {
			B[b]=0; for(i=0; i<d; i++) { B[b]+=A[a++]; }; b++;
		}
	}
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int mRows, nCols, d; double *A, *B;

	/* Error checking on arguments */
	if( nrhs!=2 ) mexErrMsgTxt("Two input arguments required.");
	if( nlhs>1 ) mexErrMsgTxt("Too many output arguments.");
	mRows = mxGetM(prhs[0]); nCols = mxGetN(prhs[0]);
	if(!mxIsDouble(prhs[0])) mexErrMsgTxt("Input array must be of type double.");

	/* extract inputs */
	A = (double*) mxGetData(prhs[0]);
	d = (int) mxGetScalar(prhs[1]);

	/* create outputs */
	plhs[0] = mxCreateDoubleMatrix(mRows/d, nCols, mxREAL );
	B = (double*) mxGetData(plhs[0]);

	/* Apply filter */
	nlfiltersep_blocksum( A, B, d, mRows, nCols );
}
