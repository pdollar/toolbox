/**************************************************************************
 * Piotr's Image&Video Toolbox      Version NEW
 * Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include "mex.h"

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* J=imtransformLinear(I,ids,wa,wb,wc,wd); */
  int m, n, i; double *I, *J, *wa, *wb, *wc, *wd; unsigned int *ids;

  /* extract inputs */
  m = mxGetM(prhs[0]); n = mxGetN(prhs[0]);
  I   = (double*) mxGetData(prhs[0]);
  wa  = (double*) mxGetData(prhs[1]);
  wb  = (double*) mxGetData(prhs[2]);
  wc  = (double*) mxGetData(prhs[3]);
  wd  = (double*) mxGetData(prhs[4]);
  ids = (unsigned int*) mxGetData(prhs[5]);

  /* Perform interpolation: J = I(ids).*wa + I(ids+1).*wb + I(ids+m).*wc + I(ids+m+1).*wd; */
  J = mxMalloc(sizeof(double)*m*n);
  for(i=0; i<m*n; i++)
    J[i]=I[ids[i]-1]*wa[i] + I[ids[i]]*wb[i] + I[ids[i]+m-1]*wc[i] + I[ids[i]+m]*wd[i];

  /* create output array */
  plhs[0] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  mxSetData(plhs[0],J); mxSetM(plhs[0],m); mxSetN(plhs[0],n);
}
