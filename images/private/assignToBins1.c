/**************************************************************************
 * Piotr's Image&Video Toolbox      Version 2.2
 * Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Simplified BSD License [see external/bsd.txt]
 *************************************************************************/
#include "mex.h"

/**************************************************************************
 * Return index of bin for x. The edges are determined by the (nBins+1)
 * element vector edges. Returns an integer value k in [0,nBins-1]
 * representing the bin x falls into, or k==nBins if x does not fall
 * into any bin. if edges[k] <= x < edges[k+1], then x falls
 * into bin k (k<nBins). Additionally, if x==edges[nBins], then x falls
 * into bin k=nBins-1. Eventually, all values where k==nBins should be ingored.
 * Adapted from \MATLAB6p5\toolbox\matlab\datafun\histc.c
 *************************************************************************/
int findBin( double x, double *edges, int nBins ) {
  int k = nBins; /* NOBIN */
  int k0 = 0; int k1 = nBins;
  if( x >= edges[0] && x < edges[nBins] ) {
    k = (k0+k1)/2;
    while( k0 < k1-1 ) {
      if(x >= edges[k]) k0 = k;
      else k1 = k;
      k = (k0+k1)/2;
    }
    k = k0;
  }
  /* check for special case */
  if(x == edges[nBins]) k = nBins-1;
  return k;
}

void assignToBins( double *B, double* A, double* edges, int n, int nBins ) {
  int j; for( j=0; j<n; j++ ) B[j]=(double) findBin( A[j], edges, nBins );
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int n, nBins; double *A, *B, *edges;
  
  /* Error checking on arguments */
  if( nrhs != 2 ) mexErrMsgTxt("Two input arguments required.");
  if( nlhs > 1 ) mexErrMsgTxt("Too many output arguments.");
  
  /* extract inputs */
  A = (double*) mxGetData(prhs[0]);
  n = mxGetNumberOfElements(prhs[0]);
  edges = (double*) mxGetData(prhs[1]);
  nBins = (int) mxGetNumberOfElements(prhs[1]) -1;
  
  /* create outputs */
  plhs[0] = mxCreateDoubleMatrix(1, n, mxREAL );
  B = (double*) mxGetData(plhs[0]);
  
  /* calculate the histograms */
  assignToBins( B, A, edges, n, nBins );
}
