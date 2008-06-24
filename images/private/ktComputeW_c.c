/*********************************************************************
 * DATESTAMP  27-Sep-2007  7:00pm
 * Piotr's Image&Video Toolbox      Version 2.1
 * Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
 * Please email me if you find bugs, or have suggestions or questions!
 *********************************************************************/

#include "mex.h"
#include "math.h"
typedef unsigned char uchar;

/* Construct W for kernel tracker. */
void ktComputeW( double* w, uchar* B, double* q, double *p, int n, int nBits )
{
  int i, indFlat, nBits2 = nBits+nBits, nBins=1<<nBits;
  int nBins3=nBins*nBins*nBins;
  double *qp;
  
  qp = (double*) mxMalloc( nBins3 * sizeof(double) );
  for( i=0; i<nBins3; i++ )
    qp[i] = ( p[i]>0 ) ? sqrt(q[i]/p[i]) : 0.0;
  
  for( i=0; i<n; i++ ) {
    indFlat = B[i] + (B[i+n]<<nBits) + (B[i+n+n]<<nBits2);
    w[i] = qp[ indFlat ];
  }

  mxFree( qp );
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Declare variables. */
  int n, nBits, dims[2];
  uchar *B; double *q, *p, *w;
  
  /* PRHS=[B, q, p, nBits];   PLHS=[w]  */
  if( nrhs != 4) mexErrMsgTxt("4 input arguments required.");
  if( nlhs > 1) mexErrMsgTxt("Too many output arguments.");
  
  /* extract input arguments */
  n = mxGetM( prhs[0] );
  B = (uchar*) mxGetData(prhs[0]);
  q = mxGetPr(prhs[1]);
  p = mxGetPr(prhs[2]);
  nBits = mxGetScalar(prhs[3]);
  
  /* create output variable -- nBins = 2^nBits */
  dims[0]=n; dims[1]=1;
  plhs[0] = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
  w = mxGetPr( plhs[0] );
  
  /* call main function */
  ktComputeW( w, B, q, p, n, nBits );
}
