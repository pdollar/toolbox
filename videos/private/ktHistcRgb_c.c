/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 2.2
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "mex.h"
typedef unsigned char uchar;

/*******************************************************************************
* Construct 3-D RGB histogram of colors in B [n x 3].
* Efficient implementation possible for the following reasons:
*  1) We know that histogram is 3 dimensional.
*  2) All values in B are between [0,2^nBits)
*  3) Bins are restricted to powers of 2 (nBins=2^nBits)
* Finding the bin index is simply a matter of dividing/multiplying by
* powers of 2, which can be done efficiently with the left and right shift
* operators. See also histc2c.c in toolbox for more general histogramming
* implementation. This is about 5x faster. Note: nBins = 2^nBits = 1<<nBits
*******************************************************************************/
void ktHistcRgb( double* h, uchar* B, double* wtMask, int n, int nBits ) {
  int i, indFlat, nBits2=nBits+nBits;
  for( i=0; i<n; i++ ) {
    indFlat = B[i] + (B[i+n]<<nBits) + (B[i+n+n]<<nBits2);
    h[ indFlat ] += wtMask[i];
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int n, nBits;
  mwSize dims[3]; 
  uchar *B; double *wtMask, *h;
  
  /* PRHS=[B, wtMask, nBits]; PLHS=[h] */
  if( nrhs != 3) mexErrMsgTxt("Three input arguments required.");
  if( nlhs > 1) mexErrMsgTxt("Too many output arguments.");
  
  /* extract inputs */
  n = mxGetM( prhs[0] );
  B = (uchar*) mxGetData(prhs[0]);
  wtMask = mxGetPr(prhs[1]);
  nBits = (int) mxGetScalar(prhs[2]);
  
  /* create outputs-- nBins = 2^nBits */
  dims[0]=dims[1]=dims[2]=1<<nBits;
  plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
  h = mxGetPr( plhs[0] );
  
  /* call main function */
  ktHistcRgb( h, B, wtMask, n, nBits );
}
