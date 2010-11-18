/**************************************************************************
 * Piotr's Image&Video Toolbox      Version 2.53
 * Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include <math.h>
#include "mex.h"

/**************************************************************************
 * % Matlab test code: currently conv2 is faster!
 * A=rand(500,500,1); rad=15; sig=sqrt((2*rad+1)/4); shape='same'; r=10;
 * fb=filterBinomial1d(rad); fg=fspecial('Gaussian',[2*rad+1,1],sig);
 * tic, for i=1:r, B = conv2(conv2(A,fb,shape),fb',shape); end; toc
 * tic, for i=1:r, C = binomSmooth(A,rad,rad,0); end; toc
 * tic, for i=1:r, D = conv2(conv2(A,fg,shape),fg',shape); end; toc
 * tic, for i=1:r, E = gaussSmooth(A,sig,shape,4); end; toc
 * diff=B-C; sum(abs(diff(:)))
 *************************************************************************/

void			binomSmooth( double *B, int ry, int rx, int rz, int h, int w, int d ) {
  /* fast binomial smoothing */
  int i,j,k,t,m,a; double *T; double norm=1; a=w*h;
  /* smooth single row by convolving with [1 1] mask 2*r times (same as binomial filter) */
  #define SMTH(r,i) for(i=0; i<r; i++) { T[i]=0; T[m-i]=0; } \
    for(t=0; t<r; t++) { for(i=0; i<m; i++) T[i]+=T[i+1]; for(i=m; i>0; i--) T[i]+=T[i-1]; }
  /* smooth along y */
  if( ry>0 ) {
    m=h+2*ry-1; T=(double*) mxMalloc((m+1)*sizeof(double));
    norm *= (double) pow(4.0,(double)ry);
    for(k=0; k<d; k++) for(j=0; j<w; j++) {
      for(i=0; i<h; i++) T[i+ry]=B[k*a+j*h+i]; SMTH(ry,i);
      for(i=0; i<h; i++) B[k*a+j*h+i]=T[i+ry];
    } mxFree(T);
  }
  /* convolve along x */
  if( rx>0 ) {
    m=w+2*rx-1; T=(double*) mxMalloc((m+1)*sizeof(double));
	norm *= (double) pow(4.0,(double)rx);
    for(k=0; k<d; k++) for(i=0; i<h; i++) {
      for(j=0; j<w; j++) T[j+rx]=B[k*a+j*h+i]; SMTH(rx,j);
      for(j=0; j<w; j++) B[k*a+j*h+i]=T[j+rx];
    } mxFree(T);
  }
  /* convolve along z */
  if( rz>0 ) {
    m=d+2*rz-1; T=(double*) mxMalloc((m+1)*sizeof(double));
    norm *= (double) pow(4.0,(double)rz);
    for(j=0; j<w; j++) for(i=0; i<h; i++) {
      for(k=0; k<d; k++) T[k+rz]=B[k*a+j*h+i]; SMTH(rz,k);
      for(k=0; k<d; k++) B[k*a+j*h+i]=T[k+rz];
    } mxFree(T);
  }
  /* normalize */
  for(i=0; i<w*h*d; i++) B[i]/=norm;
  #undef SMTH
}

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* B=binomSmooth(A,ry,rx); or B=binomSmooth(A,ry,rx,rz); */
  int ry=0, rx=0, rz=0; int *ns, ms[3], nDims, i;
  void *A; double *B; mxClassID id;
  
  /* Error checking on arguments */
  if( nrhs<3 || nrhs>4) mexErrMsgTxt("Three or four input arguments required.");
  if( nlhs>1 ) mexErrMsgTxt("One output expected.");
  nDims=mxGetNumberOfDimensions(prhs[0]); id=mxGetClassID(prhs[0]);
  if( (nDims!=2 && nDims!=3) || (id!=mxDOUBLE_CLASS && id!=mxUINT8_CLASS) )
    mexErrMsgTxt("A should be 2D or 3D double or uint8 array.");
  ns = (int*) mxGetDimensions(prhs[0]); 
  ms[0]=ns[0]; ms[1]=ns[1]; ms[2]=(nDims==2) ? 1 : ns[2];

  /* extract inputs */
  A = mxGetData(prhs[0]);
  ry = (int) mxGetScalar(prhs[1]);
  rx = (int) mxGetScalar(prhs[2]);
  if(nrhs>=4) rz = (int) mxGetScalar(prhs[3]);

  /* create output array */
  plhs[0] = mxCreateNumericArray(3, ms, mxDOUBLE_CLASS, mxREAL);
  B = (double*) mxGetData(plhs[0]);
  if( id==mxDOUBLE_CLASS ) for(i=0; i<ms[0]*ms[1]*ms[2]; i++) B[i]=((double*)A)[i];
  if( id==mxUINT8_CLASS ) for(i=0; i<ms[0]*ms[1]*ms[2]; i++) B[i]=((unsigned char*)A)[i];

  /* Perform ones convolution */
  binomSmooth( B, ry, rx, rz, ms[0], ms[1], ms[2] );
}
