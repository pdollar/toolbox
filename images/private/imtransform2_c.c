/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 3.30
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "mex.h"
#include <string.h>

/*******************************************************************************
%% initialize test data
I=imResample(double(imread('cameraman.tif')),256,256); [m,n]=size(I);
rep=100; flag=2; H=[eye(2)+randn(2)*.1 randn(2,1)*5; randn(1,2)*0.0 1];
Hi=H^-1; Hi=Hi/Hi(9); r0=(-m+1)/2; r1=(m-1)/2; c0=(-n+1)/2; c1=(n-1)/2;
%% method: perform step 1 and 2 separately
for i=1:rep, if(i==1), tic; end
  [us,vs]=imtransform2_c('homogToFlow',Hi,m,n,r0,r1,c0,c1);
  [rs1,cs1,is1]=imtransform2_c('flowToInds',us,vs,m,n,flag);
  J1 = imtransform2_c('applyTransform',I,rs1,cs1,is1,flag);
end; toc
%% method: perform step 1 and 2 together
for i=1:rep, if(i==1), tic; end
  [rs2,cs2,is2]=imtransform2_c('homogToInds',Hi,m,n,r0,r1,c0,c1,flag);
  J2 = imtransform2_c('applyTransform',I,rs2,cs2,is2,flag);
end; toc
[mean2(abs(is1-is2)) mean2(abs(J1-J2))]
*******************************************************************************/

void homogToFlow(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* [us,vs]=homogToFlow(H,m,n,[r0],[r1],[c0],[c1]); */
  int ind=0, i, j, m, n, m1, n1; double *H, *us, *vs;
  double r, c, r0, c0, r1, c1, m2, n2, z;

  /* extract inputs */
  H  = (double*) mxGetData(prhs[0]);
  m  = (int) mxGetScalar(prhs[1]);
  n  = (int) mxGetScalar(prhs[2]);
  if(nrhs==7) {
    r0 = mxGetScalar(prhs[3]);
    r1 = mxGetScalar(prhs[4]);
    c0 = mxGetScalar(prhs[5]);
    c1 = mxGetScalar(prhs[6]);
    m1  = (int) (r1-r0+1);
    n1  = (int) (c1-c0+1);
  } else {
    m1=m; r0 = (-m+1.0)/2.0;
    n1=n; c0 = (-n+1.0)/2.0;
  }
  m2 = (m-1.0)/2.0;
  n2 = (n-1.0)/2.0;

  /* initialize memory */
  us = mxMalloc(sizeof(double)*m1*n1);
  vs = mxMalloc(sizeof(double)*m1*n1);

  /* Compute flow at each grid point */
  for( i=0; i<9; i++ ) H[i]=H[i]/H[8];
  if( H[2]==0 && H[5]==0 ) {
    for( i=0; i<n1; i++ ) {
      r = H[0]*r0 + H[3]*(c0+i) + H[6] + m2;
      c = H[1]*r0 + H[4]*(c0+i) + H[7] + n2 - i;
      for(j=0; j<m1; j++) {
        us[ind]=r-j; vs[ind]=c;
        r+=H[0]; c+=H[1]; ind++;
      }
    }
  } else {
    for( i=0; i<n1; i++ ) {
      r = H[0]*r0 + H[3]*(c0+i) + H[6];
      c = H[1]*r0 + H[4]*(c0+i) + H[7];
      z = H[2]*r0 + H[5]*(c0+i) + 1;
      for(j=0; j<m1; j++) {
        us[ind]=r/z+m2-j; vs[ind]=c/z+n2-i;
        r+=H[0]; c+=H[1]; z+=H[2]; ind++;
      }
    }
  }

  /* create output array */
  plhs[0] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  plhs[1] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  mxSetData(plhs[0],us); mxSetM(plhs[0],m1); mxSetN(plhs[0],n1);
  mxSetData(plhs[1],vs); mxSetM(plhs[1],m1); mxSetN(plhs[1],n1);
}

void homogsToFlow(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* [us,vs]=homogsToFlow(H,M); */
  int i, j, k, m, n, q, *dims, affine=1, ind=0; unsigned int *M;
  double *H, *H1, *us, *vs; double r, c, r0, c0, z;

  /* extract inputs */
  H = (double*) mxGetData(prhs[0]);
  M = (unsigned int*) mxGetData(prhs[1]);
  m = (int) mxGetM(prhs[1]); n = (int) mxGetN(prhs[1]);
  if(mxGetNumberOfDimensions(prhs[0])==2) q=1; else {
    dims=(int*) mxGetDimensions(prhs[0]); q=dims[2]; }

  /* initialize memory */
  us = mxMalloc(sizeof(double)*m*n);
  vs = mxMalloc(sizeof(double)*m*n);

  /* Compute flow at each grid point */
  r0=(-m+1.0)/2.0; c0=(-n+1.0)/2.0;
  for( k=0; k<q; k++ ) {
    H1=H+k*9; for(i=0; i<9; i++) H1[i]=H1[i]/H1[8];
    affine=affine && H1[2]==0 && H1[5]==0;
  }
  if( affine ) {
    for( i=0; i<n; i++ ) for(j=0; j<m; j++) {
      k=M[ind]; H1=H+k*9; r=r0+j; c=c0+i;
      us[ind] = H1[0]*r + H1[3]*c + H1[6] - r;
      vs[ind] = H1[1]*r + H1[4]*c + H1[7] - c;
      ind++;
    }
  } else {
    for( i=0; i<n; i++ ) for(j=0; j<m; j++) {
      k=M[ind]; H1=H+k*9; r=r0+j; c=c0+i;
      us[ind] = H1[0]*r + H1[3]*c + H1[6];
      vs[ind] = H1[1]*r + H1[4]*c + H1[7];
      z       = H1[2]*r + H1[5]*c + 1;
      us[ind]=us[ind]/z-r; vs[ind]=vs[ind]/z-c; ind++;
    }
  }

  /* create output array */
  plhs[0] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  plhs[1] = mxCreateNumericMatrix(0,0,mxDOUBLE_CLASS,mxREAL);
  mxSetData(plhs[0],us); mxSetM(plhs[0],m); mxSetN(plhs[0],n);
  mxSetData(plhs[1],vs); mxSetM(plhs[1],m); mxSetN(plhs[1],n);
}

void flowToInds(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* [rs,cs,is]=flowToInds(us,vs,m,n,flag); */
  int m, n, m1, n1, flag; double *us, *vs;
  int *is, ind=0, i, j, fr, fc; double *rs, *cs, r, c;

  /* extract inputs */
  us = (double*) mxGetData(prhs[0]);
  vs = (double*) mxGetData(prhs[1]);
  m  = (int) mxGetScalar(prhs[2]);
  n  = (int) mxGetScalar(prhs[3]);
  flag = (int) mxGetScalar(prhs[4]);

  /* initialize memory */
  m1=(int)mxGetM(prhs[0]); n1=(int)mxGetN(prhs[0]);
  rs  = mxMalloc(sizeof(double)*m1*n1);
  cs  = mxMalloc(sizeof(double)*m1*n1);
  is  = mxMalloc(sizeof(int)*m1*n1);

  /* clamp and compute ids according to flag */
  if( flag==1 ) { /* nearest neighbor */
    for(i=0; i<n1; i++) for(j=0; j<m1; j++) {
      r=us[ind]+j+1; r = r<1 ? 1 : (r>m ? m : r);
      c=vs[ind]+i+1; c = c<1 ? 1 : (c>n ? n : c);
      is[ind] = ((int) (r-.5)) + ((int) (c-.5)) * m; ind++;
    }
  } else if(flag==2) { /* bilinear */
    for(i=0; i<n1; i++) for(j=0; j<m1; j++) {
      r=us[ind]+j+1; r = r<2 ? 2 : (r>m-1 ? m-1 : r); fr = (int) r;
      c=vs[ind]+i+1; c = c<2 ? 2 : (c>n-1 ? n-1 : c); fc = (int) c;
      rs[ind]=r-fr; cs[ind]=c-fc; is[ind]=(fr-1)+(fc-1)*m; ind++;
    }
  } else { /* other cases - clamp only */
    for(i=0; i<n1; i++) for(j=0; j<m1; j++) {
      r=us[ind]+j+1; rs[ind] = r<2 ? 2 : (r>m-1 ? m-1 : r);
      c=vs[ind]+i+1; cs[ind] = c<2 ? 2 : (c>n-1 ? n-1 : c); ind++;
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

void homogToInds(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* [rs,cs,is]=homogToInds(H,m,n,r0,r1,c0,c1,flag); */
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
  m1  = (int) (r1-r0+1); m2 = (m+1.0)/2.0;
  n1  = (int) (c1-c0+1); n2 = (n+1.0)/2.0;
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

void applyTransform(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* J=applyTransform(I,rs,cs,is,flag); */
  mwSize nsJ[3];
  int flag, *nsI, areaJ, areaI, nDims, i, k, id, *is;
  double *I, *J, *I1, *J1, *rs, *cs, wr, wc, wrc, r, c;

  /* extract inputs */
  I   = (double*) mxGetData(prhs[0]);
  rs  = (double*) mxGetData(prhs[1]);
  cs  = (double*) mxGetData(prhs[2]);
  is  = (int*) mxGetData(prhs[3]);
  flag = (int) mxGetScalar(prhs[4]);

  /* get dimensions */
  nDims = mxGetNumberOfDimensions(prhs[0]);
  nsI = (int*) mxGetDimensions(prhs[0]);
  nsJ[0]=(int)mxGetM(prhs[1]); nsJ[1]=(int)mxGetN(prhs[1]);
  nsJ[2]=(nDims==2) ? 1 : nsI[2];
  areaJ=nsJ[0]*nsJ[1]; areaI=nsI[0]*nsI[1];

  /* Perform interpolation */
  J = mxMalloc(sizeof(double)*areaJ*nsJ[2]);
  if( flag==1 ) { /* nearest neighbor */
    for( k=0; k<nsJ[2]; k++ ) {
      J1=J+areaJ*k; I1=I+areaI*k;
      for( i=0; i<areaJ; i++ ) J1[i]=I1[is[i]];
    }
  } else if( flag==2 ) { /* bilinear */
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

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* switchyard - apply appropriate action */
  int fail; char action[1024]; fail=mxGetString(prhs[0],action,1024);
  if(fail) mexErrMsgTxt("Failed to get action.");
  else if(!strcmp(action,"homogToFlow")) homogToFlow(nlhs,plhs,nrhs-1,prhs+1);
  else if(!strcmp(action,"homogsToFlow")) homogsToFlow(nlhs,plhs,nrhs-1,prhs+1);
  else if(!strcmp(action,"flowToInds")) flowToInds(nlhs,plhs,nrhs-1,prhs+1);
  else if(!strcmp(action,"homogToInds")) homogToInds(nlhs,plhs,nrhs-1,prhs+1);
  else if(!strcmp(action,"applyTransform")) applyTransform(nlhs,plhs,nrhs-1,prhs+1);
  else mexErrMsgTxt("Invalid action.");
}
