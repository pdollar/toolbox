/**************************************************************************
 * Piotr's Image&Video Toolbox      Version NEW
 * Copyright 2011 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include "mex.h"

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* [rs,cs]=imtransform2_comp(H,m,n,r0,r1,c0,c1,flag); */
  int m, n, flag; double *H, r0, r1, c0, c1;
  int m1, n1, ind, i, j; double *rs, *cs, r, c, m2, n2, z;

  /* extract inputs */
  H  = (double*) mxGetData(prhs[0]);
  m  = (int) mxGetScalar(prhs[1]);
  n  = (int) mxGetScalar(prhs[2]);
  r0 = mxGetScalar(prhs[3]);
  r1 = mxGetScalar(prhs[4]);
  c0 = mxGetScalar(prhs[5]);
  c1 = mxGetScalar(prhs[6]);
  flag = (int) mxGetScalar(prhs[7]);

  /* initialize memory */
  m1  = (int) floor(r1-r0+1); m2 = (m+1.0)/2.0;
  n1  = (int) floor(c1-c0+1); n2 = (n+1.0)/2.0;
  rs  = mxMalloc(sizeof(double)*m1*n1);
  cs  = mxMalloc(sizeof(double)*m1*n1);

  /* Compute rs an cs */
  if( H[2]==0 && H[5]==0 ) {
    for(i=0; i<n1; i++) for(j=0; j<m1; j++) {
      c=c0+i; r=r0+j; ind=i*m1+j;
      rs[ind] = H[0]*r + H[3]*c + H[6] + m2;
      cs[ind] = H[1]*r + H[4]*c + H[7] + n2;
    }
  } else {
    for(i=0; i<n1; i++) for(j=0; j<m1; j++) {
      c=c0+i; r=r0+j; ind=i*m1+j;
      z = H[2]*r + H[5]*c + 1;
      rs[ind] = (H[0]*r + H[3]*c + H[6])/z + m2;
      cs[ind] = (H[1]*r + H[4]*c + H[7])/z + n2;
    }
  }

  /* clamp according to flag */
  if( flag==1 ) { /* nearest neighbor */
    for(i=0; i<n1*m1; i++) {
      rs[i] = (int) ((rs[i]<1 ? 1 : (rs[i]>m ? m : rs[i])) + .5);
      cs[i] = (int) ((cs[i]<1 ? 1 : (cs[i]>n ? n : cs[i])) + .5);
    }
  } else if(flag==2) { /* bilinear */
    for(i=0; i<n1*m1; i++) {
      rs[i] = rs[i]<2 ? 2 : (rs[i]>m-1 ? m-1 : rs[i]);
      cs[i] = cs[i]<2 ? 2 : (cs[i]>n-1 ? n-1 : cs[i]);
    }
  }

  /* create output array */
  plhs[0] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  plhs[1] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  mxSetData(plhs[0],rs); mxSetM(plhs[0],m1*n1); mxSetN(plhs[0],1);
  mxSetData(plhs[1],cs); mxSetM(plhs[1],m1*n1); mxSetN(plhs[1],1);
}
