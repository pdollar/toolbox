/**************************************************************************
 * Piotr's Image&Video Toolbox      Version 2.63
 * Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include <math.h>
#include <string.h>
#include "mex.h"

#ifndef min 
 #define min(a,b) (((a)<(b)) ? (a) : (b))
#endif

void			convOnes( double *A, double *B, int ry, int rx, int rz, int h, int w, int d ) {
  /* convolve w ones mask (fast smooth) */
  int i,j,k,o,c,m=32,m1; double *V, *S; int ry2, rx2, rz2, a;
  ry2=ry*2; rx2=rx*2; rz2=rz*2; a=w*h; S=A;
  if( ry==0 && rx==0 && rz==0 ) { memcpy(B,A,h*w*d*sizeof(double)); return; }
  /* convolve along y */
  if( ry>0 ) { V=(double*) mxCalloc( h+ry2+1, sizeof(double) );
    for(k=0; k<d; k++) for(j=0; j<w; j++) { o=k*a+j*h;
      for(i=0; i<h; i++) V[i+ry]=S[o+i];
      B[o]=0; for(i=0; i<=ry; i++) B[o]+=V[i+ry];
      for(i=1; i<h; i++) B[o+i]=B[o+i-1]-V[i-1]+V[i+ry2];
    } mxFree(V); S=B;
  }
  /* convolve along x */
  if( rx>0 ) { V=(double*) mxCalloc( (w+rx2+1)*m, sizeof(double) );
    for(k=0; k<d; k++) for(i=0; i<h; i+=m) { m1=min(h-i,m); o=k*a+i;
      for(j=0; j<w; j++) for(c=0; c<m1; c++) V[m*(j+rx)+c]=S[o+j*h+c];
      for(c=0; c<m1; c++) B[o+c]=0; for(j=0; j<=rx; j++) for(c=0; c<m1; c++) B[o+c]+=V[m*(j+rx)+c];
      for(j=1; j<w; j++) for(c=0; c<m1; c++) B[o+j*h+c]=B[o+(j-1)*h+c]-V[m*(j-1)+c]+V[m*(j+rx2)+c];
    } mxFree(V); S=B;
  }
  /* convolve along z */
  if( rz>0 ) { V=(double*) mxCalloc( (d+rz2+1)*m, sizeof(double) );
    for(j=0; j<w; j++) for(i=0; i<h; i+=m) { m1=min(h-i,m); o=j*h+i;
      for(k=0; k<d; k++) for(c=0; c<m1; c++) V[m*(k+rz)+c]=S[k*a+o+c];
      for(c=0; c<m1; c++) B[o+c]=0; for(k=0; k<=rz; k++) for(c=0; c<m1; c++) B[o+c]+=V[m*(k+rz)+c];
      for(k=1; k<d; k++) for(c=0; c<m1; c++) B[k*a+o+c]=B[(k-1)*a+o+c]-V[m*(k-1)+c]+V[m*(k+rz2)+c];
    } mxFree(V); S=B;
  }
}

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* B=convOnes(A,ry,rx); or B=convOnes(A,ry,rx,rz); */
  int ry=0, rx=0, rz=0; int *ns, ms[3], nDims, i;
  double *A, *B; mxClassID id;
  
  /* Error checking on arguments */
  if( nrhs<3 || nrhs>4) mexErrMsgTxt("Three or four input arguments required.");
  if( nlhs>1 ) mexErrMsgTxt("One output expected.");
  nDims=mxGetNumberOfDimensions(prhs[0]); id=mxGetClassID(prhs[0]);
  if( (nDims!=2 && nDims!=3) || id!=mxDOUBLE_CLASS )
    mexErrMsgTxt("A should be 2D or 3D double array.");
  ns = (int*) mxGetDimensions(prhs[0]); 
  ms[0]=ns[0]; ms[1]=ns[1]; ms[2]=(nDims==2) ? 1 : ns[2];

  /* extract inputs */
  A = (double*) mxGetData(prhs[0]);
  ry = (int) mxGetScalar(prhs[1]);
  rx = (int) mxGetScalar(prhs[2]);
  if(nrhs>=4) rz = (int) mxGetScalar(prhs[3]);

  /* create output array */
  plhs[0] = mxCreateNumericArray(3, ms, mxDOUBLE_CLASS, mxREAL);
  B = (double*) mxGetData(plhs[0]);

  /* Perform ones convolution */
  convOnes( A, B, ry, rx, rz, ms[0], ms[1], ms[2] );
}
