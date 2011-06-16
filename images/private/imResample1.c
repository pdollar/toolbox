/**************************************************************************
 * Piotr's Image&Video Toolbox      Version 2.60
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

void			resample( double *A, double *B, int dim, int m0, int m1, int n, int nCh ) {
  /* resample along dim in A, store in B */
  int ch, x, y, r; double *a, *a0, *a1, *b, *b0, wt0, wt1;
  const bool downsample=(m1<m0); InterpInfo *ii;
  if(downsample) ii=interpInfoDn(m0, m1, &r); else ii=interpInfoUp(m0, m1, &r);
  if(dim==1) for(y=0; y<r; y++) { ii[y].yb*=n; ii[y].ya0*=n; ii[y].ya1*=n; }
  for(ch=0; ch<nCh; ch++) {
    a=A+ch*n*m0; b=B+ch*n*m1;
	/* resample height m0->m1 (width n unchanged) */
    if(dim==0) for(x=0; x<n; x++) {
      a0=a+x*m0; b0=b+x*m1;
      if( downsample ) for(y=0; y<r; y++) b0[ii[y].yb] += a0[ii[y].ya0]*ii[y].wt0;
      else for(y=0; y<r; y++) b0[ii[y].yb] = a0[ii[y].ya0]*ii[y].wt0 + a0[ii[y].ya1]*ii[y].wt1;
    /* resample width m0->m1 (height n unchanged) */
    } else for(x=0; x<r; x++) {
      a0=a+ii[x].ya0; a1=a+ii[x].ya1; b0=b+ii[x].yb; wt0=ii[x].wt0; wt1=ii[x].wt1;
      if( downsample ) for(y=0; y<n; y++) b0[y] += a0[y]*wt0;
      else for(y=0; y<n; y++) b0[y] = a0[y]*wt0 + a1[y]*wt1;
    }
  }
  mxFree(ii);
}

void			resampleInt( double *A, double *B, int h0, int w0, int nCh, int r )
{
  /* resample by integer factor r (special case, more efficient than resample) */
  int ch, i, j, i0, j0; double *a, *b; int h1=h0/r, w1=w0/r, h2, w2; double norm=1.0/r/r;
  for(ch=0; ch<nCh; ch++) for(j=0; j<w1; j++) for(j0=0; j0<r; j0++) for(i0=0; i0<r; i0++) {
      a=A+ch*w0*h0+(j0+j*r)*h0+i0; b=B+ch*w1*h1+j*h1; for(i=0; i<h1; i++) { *(b++)+=*a; a+=r; } }
  for(i=0; i<h1*w1*nCh; i++) B[i]*=norm;
}

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  /* B=imResample(A,scale) or B=imResample(A,h,w); */
  double input1=0, input2=0; int *ns, ms[3], nCh, nDims, i, r;
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
  r=ns[0]/ms[0]; if(ms[0]*r==ns[0] && ms[1]*r==ns[1] ) {
    resampleInt(A,B,ns[0],ns[1],nCh,r);
  } else {
    T = (double*) mxCalloc(ms[0]*ns[1]*nCh, sizeof(double) );
    resample( A, T, 0, ns[0], ms[0], ns[1], nCh );
    resample( T, B, 1, ns[1], ms[1], ms[0], nCh );
    mxFree(T);
  }

  /* convert from double if id!=mxDOUBLE_CLASS */
  if(id==mxUINT8_CLASS) for(i=0; i<ms[0]*ms[1]*nCh; i++) ((uchar*)B1)[i]=(uchar) (B[i]+.5);
  if( id!=mxDOUBLE_CLASS ) { mxFree(A); mxFree(B); }
}
