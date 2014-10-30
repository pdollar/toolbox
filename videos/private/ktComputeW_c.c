/**************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 2.2
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
**************************************************************************/
#include "mex.h"
#include "math.h"
typedef unsigned char uchar;

/* Construct W for kernel tracker. */
void ktComputeW( double* w, uchar* B, double* q, double *p, int n, int nBits ) {
  int i, indFlat, nBits2=nBits+nBits, nBins=1<<nBits;
  int nBins3=nBins*nBins*nBins; double *qp;
  qp = (double*) mxMalloc( nBins3 * sizeof(double) );
  for( i=0; i<nBins3; i++ )
    qp[i] = ( p[i]>0 ) ? sqrt(q[i]/p[i]) : 0.0;
    for( i=0; i<n; i++ ) {
      indFlat = B[i] + (B[i+n]<<nBits) + (B[i+n+n]<<nBits2);
      w[i] = qp[ indFlat ];
    }
    mxFree( qp );
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* Declare variables. */
  int n, nBits, dims[2];
  uchar *B; double *q, *p, *w;
  
  /* PRHS=[B, q, p, nBits]; PLHS=[w] */
  if( nrhs != 4) mexErrMsgTxt("Four input arguments required.");
  if( nlhs > 1) mexErrMsgTxt("Too many output arguments.");
  
  /* extract inputs */
  n = mxGetM( prhs[0] );
  B = (uchar*) mxGetData(prhs[0]);
  q = mxGetPr(prhs[1]);
  p = mxGetPr(prhs[2]);
  nBits = (int) mxGetScalar(prhs[3]);
  
  /* create outputs */
  dims[0]=n; dims[1]=1;
  plhs[0] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
  w = mxGetPr( plhs[0] );
  
  /* call main function */
  ktComputeW( w, B, q, p, n, nBits );
}
