/**************************************************************************
 * Piotr's Image&Video Toolbox      Version NEW
 * Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include "mex.h"

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* J=imtransform2_apply(I,rs,cs,is,flag); */
  int flag, *nsI, nsJ[3], areaJ, areaI, nDims, i, k, id, *is;
  double *I, *J, *I1, *J1, *rs, *cs, wr, wc, wrc;

  /* extract inputs */
  I   = (double*) mxGetData(prhs[0]);
  rs  = (double*) mxGetData(prhs[1]);
  cs  = (double*) mxGetData(prhs[2]);
  is  = (int*) mxGetData(prhs[3]);
  flag = (int) mxGetScalar(prhs[4]);

  /* get dimensions */
  nDims = mxGetNumberOfDimensions(prhs[0]);
  nsI = (int*) mxGetDimensions(prhs[0]);
  nsJ[0]=mxGetM(prhs[1]); nsJ[1]=mxGetN(prhs[1]);
  nsJ[2]=(nDims==2) ? 1 : nsI[2];
  areaJ=nsJ[0]*nsJ[1]; areaI=nsI[0]*nsI[1];

  /* Perform interpolation */
  J = mxMalloc(sizeof(double)*areaJ*nsJ[2]);
  if( flag==1 ) { /* nearest neighbor */
    for( k=0; k<nsJ[2]; k++ ) {
      J1=J+areaJ*k; I1=I+areaI*k;
      for( i=0; i<areaJ; i++ ) J1[i]=I1[is[i]];
    }
  } else { /* bilinear */
    for( k=0; k<nsJ[2]; k++ ) {
      J1=J+areaJ*k; I1=I+areaI*k;
      for( i=0; i<areaJ; i++ ) {
        id=is[i]; wr=rs[i]; wc=cs[i]; wrc=wr*wc;
        J1[i]=I1[id]*(1-wr-wc+wrc) + I1[id+1]*(wr-wrc) 
          + I1[id+nsI[0]]*(wc-wrc) + I1[id+nsI[0]+1]*wrc;
      }
    }
  }

  /* create output array */
  plhs[0] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  mxSetData(plhs[0],J); mxSetDimensions(plhs[0],nsJ,3);
}
