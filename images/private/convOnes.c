/**************************************************************************
 * Piotr's Image&Video Toolbox      Version NEW
 * Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include <math.h>
#include "mex.h"

void			convOnes( double *B, int ry, int rx, int rz, int h, int w, int d ) {
  /* convolve w ones mask (fast smooth) */
  int i,j,k,o; double *V; int ry2, rx2, rz2, a;
  ry2=ry*2; rx2=rx*2; rz2=rz*2; a=w*h;
  /* convolve along y */
  if( ry>0 ) {  V=(double*) mxCalloc( h+ry2+1, sizeof(double) );
    for(k=0; k<d; k++) for(j=0; j<w; j++) { o=k*a+j*h;
      for(i=0; i<h; i++) V[i+ry]=B[o+i];
      B[o]=0; for(i=0; i<=ry; i++) B[o]+=V[i+ry];
      for(i=1; i<h; i++) B[o+i]=B[o+i-1]-V[i-1]+V[i+ry2];
    } mxFree(V);
  }
  /* convolve along x */
  if( rx>0 ) {  V=(double*) mxCalloc( w+rx2+1, sizeof(double) );
    for(k=0; k<d; k++) for(i=0; i<h; i++) { o=k*a+i;
      for(j=0; j<w; j++) V[j+rx]=B[o+j*h];
      B[o]=0; for(j=0; j<=rx; j++) B[o]+=V[j+rx];
      for(j=1; j<w; j++) B[o+j*h]=B[o+(j-1)*h]-V[j-1]+V[j+rx2];
    } mxFree(V);
  }
  /* convolve along z */
  if( rz>0 ) {  V=(double*) mxCalloc( d+rz2+1, sizeof(double) );
    for(j=0; j<w; j++) for(i=0; i<h; i++) { o=j*h+i;
      for(k=0; k<d; k++) V[k+rz]=B[k*a+o];
      B[o]=0; for(k=0; k<=rz; k++) B[o]+=V[k+rz];
      for(k=1; k<d; k++) B[k*a+o]=B[(k-1)*a+o]-V[k-1]+V[k+rz2];
    } mxFree(V);
  }
}

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* B=convOnes(A,ry,rx); or B=convOnes(A,ry,rx,rz); */
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
  convOnes( B, ry, rx, rz, ms[0], ms[1], ms[2] );
}
