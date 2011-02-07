/**************************************************************************
 * Piotr's Image&Video Toolbox      Version NEW
 * Copyright 2011 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include "mex.h"

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* [rs,cs,is]=imtransform2_comp(H,m,n,r0,r1,c0,c1,flag); */
  int m, n, flag; double *H, r0, r1, c0, c1;
  int *is, m1, n1, ind=0, i, j, fr, fc; double *rs, *cs, r, c, m2, n2, z;

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
  is  = mxMalloc(sizeof(int)*m1*n1);

  /* Compute rs an cs */
  if( H[2]==0 && H[5]==0 ) {
    for( i=0; i<n1; i++ ) {
      r = H[0]*r0 + H[3]*(c0+i) + H[6] + m2;
      c = H[1]*r0 + H[4]*(c0+i) + H[7] + n2;
      for(j=0; j<m1; j++) {
        rs[ind]=r; cs[ind]=c;
        r+=H[0]; c+=H[1]; ind++;
      }
    }
  } else {
    for( i=0; i<n1; i++ ) {
      r = H[0]*r0 + H[3]*(c0+i) + H[6];
      c = H[1]*r0 + H[4]*(c0+i) + H[7];
      z = H[2]*r0 + H[5]*(c0+i) + 1;
      for(j=0; j<m1; j++) {
        rs[ind]=r/z+m2; cs[ind]=c/z+n2;
        r+=H[0]; c+=H[1]; z+=H[2]; ind++;
      }
    }
  }

  /* clamp and compute ids according to flag */
  if( flag==1 ) { /* nearest neighbor */
    for(i=0; i<n1*m1; i++) {
      r = rs[i]<1 ? 1 : (rs[i]>m ? m : rs[i]);
      c = cs[i]<1 ? 1 : (cs[i]>n ? n : cs[i]);
      is[i] = ((int) (r-.5)) + ((int) (c-.5)) * m;
    }
  } else if(flag==2) { /* bilinear */
    for(i=0; i<n1*m1; i++) {
      r = rs[i]<2 ? 2 : (rs[i]>m-1 ? m-1 : rs[i]);
      c = cs[i]<2 ? 2 : (cs[i]>n-1 ? n-1 : cs[i]);
      fr = (int) r; fc = (int) c;
      rs[i]=r-fr; cs[i]=c-fc; is[i]=(fr-1)+(fc-1)*m;
    }
  } else { /* other cases - clamp only */
    for(i=0; i<n1*m1; i++) {
      rs[i] = rs[i]<2 ? 2 : (rs[i]>m-1 ? m-1 : rs[i]);
      cs[i] = cs[i]<2 ? 2 : (cs[i]>n-1 ? n-1 : cs[i]);
    }
  }

  /* create output array */
  plhs[0] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  plhs[1] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  plhs[2] = mxCreateNumericMatrix(0,0,mxINT32_CLASS,mxREAL);
  mxSetData(plhs[0],rs); mxSetM(plhs[0],m1); mxSetN(plhs[0],n1);
  mxSetData(plhs[1],cs); mxSetM(plhs[1],m1); mxSetN(plhs[1],n1);
  mxSetData(plhs[2],is); mxSetM(plhs[2],m1); mxSetN(plhs[2],n1);
}
