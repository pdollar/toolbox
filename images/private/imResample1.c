/**************************************************************************
 * Piotr's Image&Video Toolbox      Version 2.50
 * Copyright 2010 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include <math.h>
#include "mex.h"
typedef unsigned char uchar;

/* struct used for caching interpolation values for single column */
typedef struct { int yb, ya0, ya1; double wt0, wt1; } InterpInfo;

InterpInfo*		interpInfoDn( int ha, int hb, int *n ) {
  /* compute interpolation values for single column for DOWN sampling */
  int c, ya, yb, ya0, ya1; double sc, scInv, ya0f, ya1f; InterpInfo *ii;
  sc = (double)hb/(double)ha; scInv = 1.0/sc;
  *n = (int)ceil(hb*scInv)+2*hb; ya0f=0; ya1f=scInv; c=0;
  ii = (InterpInfo*) mxMalloc(sizeof(InterpInfo)*(*n));
  for( yb=0; yb<hb; yb++ ) {
    ya0=(int)ceil(ya0f); ya1=(int)floor(ya1f);
    if( ya0-ya0f > 1e-3 ) { /* upper elt contributing to yb */
      ii[c].yb=yb; ii[c].ya0=ya0-1; ii[c].wt0=(ya0-ya0f)*sc; c++; }
    for( ya=ya0; ya<ya1; ya++ ) { /* main elts contributing to yb */
      ii[c].yb=yb; ii[c].ya0=ya; ii[c].wt0=sc; c++; }
    if( ya1f-ya1 > 1e-3 ) { /* lower elt contributing to yb */
      ii[c].yb=yb; ii[c].ya0=ya1; ii[c].wt0=(ya1f-ya1)*sc; c++; }
    ya0f=ya1f; ya1f+=scInv;
  }
  *n=c; return ii;
}

InterpInfo*		interpInfoUp( int ha, int hb, int *n ) {
  /* compute interpolation values for single column for UP sampling */
  int ya, yb; double sc, scInv, yaf; InterpInfo *ii;
  sc = (double)hb/(double)ha; scInv = 1.0/sc; yaf=.5*scInv-.5;
  ii = (InterpInfo*) mxMalloc(sizeof(InterpInfo)*hb);
  for( yb=0; yb<hb; yb++ ) {
    ii[yb].yb=yb; ya=(int) floor(yaf);
    if(ya<0) { /* if near start of column */
      ii[yb].wt1=0; ii[yb].ya0=ii[yb].ya1=0;
    } else if( ya>=ha-1 ) { /* if near end of column */
      ii[yb].wt1=0; ii[yb].ya0=ii[yb].ya1=ha-1;
    } else { /* interior */
      ii[yb].wt1=yaf-ya; ii[yb].ya0=ya; ii[yb].ya1=ya+1;
    }
    ii[yb].wt0=1.0-ii[yb].wt1; yaf+=scInv;
  }
  *n=hb; return ii;
}

void			resample( double *A, double *B, int ha, int hb, int w, int nCh ) {
  /* resample every column in A, store in B, result is transposed */
  int ch, x, y, n; double *a, *b; const bool downsample=(hb<=ha); InterpInfo *ii;
  if(downsample) ii=interpInfoDn(ha, hb, &n); else ii=interpInfoUp(ha, hb, &n);
  for(x=0; x<n; x++) ii[x].yb*=w; /* transpose B */
  for(ch=0; ch<nCh; ch++) for(x=0; x<w; x++) {
    a = A + ch*w*ha + x*ha;
    b = B + ch*w*hb + x;
    if( downsample )
      for(y=0; y<n; y++) b[ii[y].yb]+=ii[y].wt0*a[ii[y].ya0];
    else
      for(y=0; y<n; y++) b[ii[y].yb]=a[ii[y].ya0]*ii[y].wt0+a[ii[y].ya1]*ii[y].wt1;
  }
  mxFree(ii);
}

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* B=imResample(A,scale) or B=imResample(A,h,w); */
  double input1=0, input2=0; int *ns, ms[3], nCh, nDims, i;
  double *A, *B, *T; void *A1, *B1; mxClassID id;
  
  /* Error checking on arguments */
  if( nrhs<2 || nrhs>3) mexErrMsgTxt("Two or three inputs expected.");
  if( nlhs>1 ) mexErrMsgTxt("One output expected.");
  nDims=mxGetNumberOfDimensions(prhs[0]); id=mxGetClassID(prhs[0]);
  if( (nDims!=2 && nDims!=3) || (id!=mxDOUBLE_CLASS && id!=mxUINT8_CLASS) )
    mexErrMsgTxt("A should be 2D or 3D double or uint8 array.");
  input1=mxGetScalar(prhs[1]); if(nrhs>=3) input2=mxGetScalar(prhs[2]);
  
  /* create output array */
  ns = (int*) mxGetDimensions(prhs[0]); nCh=(nDims==2) ? 1 : ns[2]; ms[2]=nCh;
  if( nrhs==2 ) {
    ms[0]=(int) (ns[0]*input1+.5); ms[1]=(int) (ns[1]*input1+.5);
  } else {
    ms[0]=(int) input1; ms[1]=(int) input2;
  }
  plhs[0] = mxCreateNumericArray(3, ms, id, mxREAL);
  
  /* convert to double if id!=mxDOUBLE_CLASS */
  A1=mxGetData(prhs[0]); B1=mxGetData(plhs[0]);
  if( id==mxDOUBLE_CLASS ) { A=(double*) A1; B=(double*) B1; } else {
    A = (double*) mxMalloc( ns[0]*ns[1]*nCh*sizeof(double) );
    B = (double*) mxCalloc( ms[0]*ms[1]*nCh, sizeof(double) );
  }
  if(id==mxUINT8_CLASS) for(i=0; i<ns[0]*ns[1]*nCh; i++) A[i]=(double) ((uchar*)A1)[i];
  
  /* Perform rescaling */
  T = (double*) mxCalloc(ms[0]*ns[1]*nCh, sizeof(double) );
  resample( A, T, ns[0], ms[0], ns[1], nCh );
  resample( T, B, ns[1], ms[1], ms[0], nCh );
  mxFree(T);
  
  /* convert from double if id!=mxDOUBLE_CLASS */
  if(id==mxUINT8_CLASS) for(i=0; i<ms[0]*ms[1]*nCh; i++) ((uchar*)B1)[i]=(uchar) (B[i]+.5);
  if( id!=mxDOUBLE_CLASS ) { mxFree(A); mxFree(B); }
}
