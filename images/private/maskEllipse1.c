/***************************************************************************
* maskEllipse.c
*
* Adapted from code by: Kristin Branson [kbranson-at-cs.ucsd.edu]
*
* Piotr's Image&Video Toolbox      Version 2.2
* Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
***************************************************************************/
#include "mex.h"
#include <math.h>

unsigned int getInterior(int* pnts, int mRows, int nCols, double cenRow, double cenCol, double th, double a, double b)
{
	/* Stuff for finding the leftmost/rightmost ellipse interior points */
	double denom, sint, cost, coladd;
	int colsmall, colbig;

	/* Stuff for finding the upper and lower ellipse interior points */
	double A, B, C;
	double rowsmall, rowbig, temp;

	/* other variables */
	int row, col; /* looping */
	double cosTh, sinTh, tanTh; /* angle */
	int maxN = mRows * nCols; /* max num of possible points */
	int n; /*actual num of points found */

	/* angles */
	th = 3.14159265 - th;
	cosTh=cos(th); sinTh=sin(th); tanTh=sinTh/cosTh;

	/* Find the leftmost and rightmost points of the ellipse */
	denom = sqrt(pow(a,2)*pow(cosTh,2) + pow(b,2)*pow(sinTh,2));
	sint = b*sinTh/denom; cost = a*cosTh/denom;
	coladd = a*cosTh*cost + b*sinTh*sint;
	if(coladd < 0) coladd = -coladd;
	colsmall = (int)ceil( cenCol - coladd ); colbig = (int)floor( cenCol + coladd );
	if(colsmall < 1) colsmall = 1; if(colbig > nCols) colbig = nCols;

	/* Find the top and bottom points for each c */
	n = 0;
	for(col = colsmall; col <= colbig; col++) {
		/* get A,B,C */
		A = (col-cenCol)/(a*cosTh);
		B = b/a*tanTh;
		C = pow(B,2)-pow(A,2)+1;
		if(C < 0){ mexErrMsgTxt("inside of sqrt less than 0!"); return 0; }

		/* calculate start and end of row */
		rowsmall = cenRow - a * sinTh * (A-B*sqrt(C))/(B*B+1) + b * cosTh * (A*B+sqrt(C))/(B*B+1);
		rowbig = cenRow - a * sinTh * (A+B*sqrt(C))/(B*B+1) + b * cosTh * (A*B-sqrt(C))/(B*B+1);
		if (rowsmall>rowbig) {temp=rowsmall; rowsmall=rowbig; rowbig=temp; }
		rowsmall = ceil(rowsmall-.0001); rowbig = floor(rowbig+.0001);
		if(rowsmall < 1) rowsmall = 1; if(rowbig > mRows) rowbig = mRows;

		/* Add points in between top and bottom for this c */
		for(row = (int) rowsmall; row <= (int) rowbig; row++){
			pnts[n]=row; pnts[n+maxN]=col; n++;
		}
	}

	return n;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int i, mRows, nCols;

	/* ellipse parameters */
	double cenRow, cenCol, th, a, b;

	/* will contain ouput */
	int *pnts; unsigned int n;

	/* Error checking on arguments */
	if(nrhs != 7 ) mexErrMsgTxt("7 input arguments required.");
	if(nlhs > 2 ) mexErrMsgTxt("Too many output arguments.");
	for( i=0; i<7; i++ ) {
		if( mxIsComplex(prhs[i]) || !(mxGetM(prhs[i])==1 && mxGetN(prhs[i])==1) )
			mexErrMsgTxt("Input must be a noncomplex scalar.");
	}

	/* extract arguments (ellipse paramters) */
	cenRow = mxGetScalar( prhs[0] );
	cenCol = mxGetScalar( prhs[1] );
	a = mxGetScalar( prhs[2] );
	b = mxGetScalar( prhs[3] );
	th = mxGetScalar( prhs[4] );

	/* extract arguments (image size) */
	mRows = (int) mxGetScalar( prhs[5] );
	nCols = (int) mxGetScalar( prhs[6] );

	/* create output array */
	plhs[1] = mxCreateNumericMatrix( mRows*nCols, 2, mxINT32_CLASS, mxREAL );
	pnts = (int*) mxGetData(plhs[1]);

	/* get actual points inside of ellipse */
	n = getInterior( pnts, mRows, nCols, cenRow, cenCol, th, a, b);
	plhs[0] = mxCreateDoubleScalar( n );
}
