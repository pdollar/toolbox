/**************************************************************************
 * Piotr's Image&Video Toolbox      Version NEW
 * Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include "mex.h"

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* J=imtransform2_apply(I,rs,cs,is,flag); */
  int flag, m, n, i, id, fr, fc, *is; double *I, *J, *rs, *cs;
  double wr, wc, wrc, r, c;

  /* extract inputs */
  m = mxGetM(prhs[1]); n = mxGetN(prhs[1]);
  I   = (double*) mxGetData(prhs[0]);
  rs  = (double*) mxGetData(prhs[1]);
  cs  = (double*) mxGetData(prhs[2]);
  is  = (int*) mxGetData(prhs[3]);
  flag = (int) mxGetScalar(prhs[4]);

  /* Perform interpolation */
  J = mxMalloc(sizeof(double)*m*n);
  if( flag==1 ) { /* nearest neighbor */
    for( i=0; i<m*n; i++ ) J[i]=I[is[i]];
  } else { /* bilinear */
    for( i=0; i<m*n; i++ ) {
      id=is[i]; wr=rs[i]; wc=cs[i]; wrc=wr*wc;
      J[i]=I[id]*(1-wr-wc+wrc) + I[id+1]*(wr-wrc) + I[id+m]*(wc-wrc) + I[id+m+1]*wrc;
    }
  }

  /* create output array */
  plhs[0] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  mxSetData(plhs[0],J); mxSetM(plhs[0],m); mxSetN(plhs[0],n);
}
