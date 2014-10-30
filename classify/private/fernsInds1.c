/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 2.50
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "mex.h"
#include <math.h>
typedef unsigned int uint;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int N, F, M, S, n, f, m, s;
  double *data, *thrs;
  uint *fids, *inds;
  
  /* Error checking on arguments */
  if( nrhs!=3) mexErrMsgTxt("Three input arguments required.");
  if( nlhs>1 ) mexErrMsgTxt("Too many output arguments.");
  if( !mxIsClass(prhs[0], "double") || !mxIsClass(prhs[1], "uint32")
  || !mxIsClass(prhs[2], "double"))
    mexErrMsgTxt("Input arrays are of incorrect type.");
  
  /* extract inputs */
  data = (double*) mxGetData(prhs[0]); /* N x F */
  fids = (uint*)   mxGetData(prhs[1]); /* M x S */
  thrs = (double*) mxGetData(prhs[2]); /* N x F */
  N=mxGetM(prhs[0]); F=mxGetN(prhs[0]);
  M=mxGetM(prhs[1]); S=mxGetN(prhs[1]);
  
  /* create outputs */
  plhs[0] = mxCreateNumericMatrix(N, M, mxUINT32_CLASS, mxREAL);
  inds = (uint*) mxGetData(plhs[0]); /* N x M */
  
  /* compute inds */
  for(m=0; m<M; m++) for(s=0; s<S; s++) for(n=0; n<N; n++) {
    inds[n+m*N]*=2; f=fids[m+s*M]-1;
    if( data[n+f*N]<thrs[m+s*M] ) inds[n+m*N]++;
  }
  for(n=0; n<N*M; n++) inds[n]++;
}
