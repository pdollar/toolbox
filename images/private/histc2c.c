/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 2.2
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "mex.h"

/*******************************************************************************
* Return index of bin for x. The edges are determined by the (nBins+1)
* element vector edges. Returns an integer value k in [0,nBins-1]
* representing the bin x falls into, or k==nBins if x does not fall
* into any bin. if edges[k] <= x < edges[k+1], then x falls
* into bin k (k<nBins). Additionally, if x==edges[nBins], then x falls
* into bin k=nBins-1. Eventually, all values where k==nBins should be ingored.
* Adapted from \MATLAB6p5\toolbox\matlab\datafun\histc.c
*******************************************************************************/
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

/*******************************************************************************
* Fast indexing into multidimensional arrays.
* Call sub2ind_init once and store the result (siz contains the nd sizes):
*  subMul = sub2ind_init( siz, nd );
* Then, to index into an array A of size siz, given a subscript sub
* (where sub is an nd int array of subscripts), you can get the index using:
*  sub2ind(ind,sub,subMul,nd)
*******************************************************************************/
#define sub2ind(ind, sub, subMul, nd) ind=sub[0]; for(k=1;k<nd;k++) ind+=sub[k]*subMul[k];
int *sub2ind_init( const int*siz, const int nd ) {
  int i, *subMul;
  subMul = (int*) mxCalloc( nd, sizeof(int));
  subMul[0] = 1; for(i=1; i<nd; i++ ) subMul[i]=subMul[i-1]*siz[i-1];
  return subMul;
}

/* construct the nd dimensional histogram */
void histcND( double* h, double* A, double* wtMask, int n, int nd, double**edges, int* nBins ) {
  int i, j, k, inbounds; int *subMul, *sub, ind;
  sub = (int *) mxMalloc( nd * sizeof(int) );
  subMul = sub2ind_init( nBins, nd );
  for( i=0; i < n; i++) {
    inbounds = 1;
    for( j=0; j < nd; j++) {
      sub[j] = findBin( A[ n*j+i ], edges[j], nBins[j] );
      if(sub[j]==nBins[j]) { inbounds=0; break; }
    }
    if( inbounds ) {
      sub2ind(ind, sub, subMul, nd);
      h[ ind ] += wtMask[i];
    }
  }
  mxFree( sub ); mxFree( subMul );
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int i, n, nd, *nBins; double *A, *wtMask, **edges, *h;
  
  /* Error checking on arguments PRHS=[A1, wtMask, edges1, edges2, ...]; PLHS=[h] */
  if( nrhs < 3) mexErrMsgTxt("At least three input arguments required.");
  if( nlhs > 1) mexErrMsgTxt("Too many output arguments.");
  n = mxGetM( prhs[0] ); nd = mxGetN( prhs[0] );
  if( (mxGetM(prhs[1])!=1 && mxGetN(prhs[1])!=1) ||
          (mxGetM( prhs[1] )!=n && mxGetN( prhs[1] )!=n) )
    mexErrMsgTxt("wtMask must be a vector of length n (A is nxnd).");
  if( nrhs-2!=nd ) mexErrMsgTxt("Number of edge vectors must equal nd (A is nxnd).");
  for( i=0; i<nd; i++) if( mxGetM( prhs[i+2] )!=1 )
    mexErrMsgTxt("edges must be row vectors.");
  
  /* extract arguments */
  A = mxGetPr(prhs[0]);
  wtMask = mxGetPr(prhs[1]);
  nBins = (int*) mxMalloc( nd * sizeof(int) );
  for( i=0; i<nd; i++) nBins[i] = mxGetN(prhs[i+2])-1;
  edges = (double**) mxMalloc( nd * sizeof(double*) );
  for( i=0; i<nd; i++) edges[i] = mxGetPr(prhs[i+2]);
  
  /* create outputs */
  plhs[0] = mxCreateNumericArray(nd, nBins, mxDOUBLE_CLASS, mxREAL);
  h = mxGetPr( plhs[0] );
  
  /* call main function */
  histcND( h, A, wtMask, n, nd, edges, nBins );
  mxFree( nBins ); mxFree( edges );
}
