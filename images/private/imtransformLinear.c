/**************************************************************************
 * Piotr's Image&Video Toolbox      Version NEW
 * Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include "mex.h"

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* J=imtransformLinear(I,rs,cs); */
  int m, n, i, id, fr, fc; double *I, *J, *rs, *cs;
  double wr, wc, wrc, r, c;

  /* extract inputs */
  m = mxGetM(prhs[0]); n = mxGetN(prhs[0]);
  I   = (double*) mxGetData(prhs[0]);
  rs  = (double*) mxGetData(prhs[1]);
  cs  = (double*) mxGetData(prhs[2]);

  /* Perform interpolation */
  J = mxMalloc(sizeof(double)*m*n);
  for( i=0; i<m*n; i++ ) {
    r = rs[i]; fr = (int) r; wr = r-fr;
    c = cs[i]; fc = (int) c; wc = c-fc;
    id=(fr-1)+(fc-1)*m; wrc=wr*wc;
    J[i]=I[id]*(1-wr-wc+wrc) + I[id+1]*(wr-wrc) + I[id+m]*(wc-wrc) + I[id+m+1]*wrc;
  }

  /* create output array */
  plhs[0] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  mxSetData(plhs[0],J); mxSetM(plhs[0],m); mxSetN(plhs[0],n);
}
