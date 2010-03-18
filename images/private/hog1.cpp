/**************************************************************************
 * Piotr's Image&Video Toolbox      Version 2.50
 * Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Lesser GPL [see external/lgpl.txt]
 *************************************************************************/
#include <math.h>
#include "mex.h"

#define eps 0.0001
#define PI 3.1415926535897931
static inline double min(double x, double y) { return (x <= y ? x : y); }
static inline double max(double x, double y) { return (x <= y ? y : x); }
static inline int min(int x, int y) { return (x <= y ? x : y); }
static inline int max(int x, int y) { return (x <= y ? y : x); }

// snap to one of oBin orientations using binary search
int					compOrient( double dx, double dy, double *ux, double *uy, int oBin ) {
  if(oBin<=1) return 0; int o0=0, o1=oBin-1;
  double s0=fabs(ux[o0]*dx+uy[o0]*dy);
  double s1=fabs(ux[o1]*dx+uy[o1]*dy);
  while( 1 ) {
    if(o0==o1-1) { return ((s0>s1) ? o0 : o1); }
    if( s0<s1 ) {
      o0+=(o1-o0+1)>>1; s0=fabs(ux[o0]*dx+uy[o0]*dy);
    } else {
      o1-=(o1-o0+1)>>1; s1=fabs(ux[o1]*dx+uy[o1]*dy);
    }
  }
}

// compute gradient magnitude (*2) and orientation
void				compGradImg( double *I, double *G, int *O, int h, int w, int nCh, int oBin ) {
  // compute unit vectors evenly distributed at oBin orientations
  double *ux = (double*) mxMalloc(oBin*sizeof(double));
  double *uy = (double*) mxMalloc(oBin*sizeof(double));
  for( int o=0; o<oBin; o++ ) ux[o]=cos(double(o)/double(oBin)*PI);
  for( int o=0; o<oBin; o++ ) uy[o]=sin(double(o)/double(oBin)*PI);
  
  // compute gradients for each channel, pick strongest gradient
  int y, x, c; double *I1, v, dx, dy, dx1, dy1, v1;
  #define COMPGRAD(x0, x1, rx, y0, y1, ry) { v=-1; for(c=0; c<nCh; c++) { \
          I1 = I + c*h*w + x*h + y; \
          dy1 = (*(I1+y1)-*(I1-y0))*ry; \
                  dx1 = (*(I1+x1*h)-*(I1-x0*h))*rx; \
                  v1=dx1*dx1+dy1*dy1; if(v1>v) { v=v1; dx=dx1; dy=dy1; }} \
          *(G+x*h+y)=sqrt(v); *(O+x*h+y)=compOrient(dx, dy, ux, uy, oBin); }
  
  // centered differences on interior points
  for( x=1; x<w-1; x++ ) for( y=1; y<h-1; y++ ) COMPGRAD(1, 1, 1, 1, 1, 1);
  
  // uncentered differences along each edge
  x=0;   for( y=1; y<h-1; y++ ) COMPGRAD(0, 1, 2, 1, 1, 1);
  y=0;   for( x=1; x<w-1; x++ ) COMPGRAD(1, 1, 1, 0, 1, 2);
  x=w-1; for( y=1; y<h-1; y++ ) COMPGRAD(1, 0, 2, 1, 1, 1);
  y=h-1; for( x=1; x<w-1; x++ ) COMPGRAD(1, 1, 1, 1, 0, 2);
  
  // finally uncentered differences at corners
  x=0;   y=0;   COMPGRAD(0, 1, 2, 0, 1, 2);
  x=w-1; y=0;   COMPGRAD(1, 0, 2, 0, 1, 2);
  x=0;   y=h-1; COMPGRAD(0, 1, 2, 1, 0, 2);
  x=w-1; y=h-1; COMPGRAD(1, 0, 2, 1, 0, 2);
  
  mxFree(ux); mxFree(uy);
}

// compute HOG features
mxArray*			hog( double *I, int h, int w, int nCh, int sBin, int oBin, int oGran ) {
  // compute gradient magnitude (*2) and orientation for each location in I
  double *G = (double*) mxMalloc(h*w*sizeof(double));
  int *O = (int*) mxMalloc(h*w*sizeof(int));
  compGradImg(I, G, O, h, w, nCh, oBin*oGran);
  
  // compute gradient histograms use trilinear interpolation on spatial and orientation bins
  const int hb=h/sBin, wb=w/sBin, h0=hb*sBin, w0=wb*sBin, nb=wb*hb;
  double *hist = (double*) mxCalloc(nb*oBin, sizeof(double));
  if( oGran==1 ) for( int x=0; x<w0; x++ ) for( int y=0; y<h0; y++ ) { // bilinear interp.
    double v=*(G+x*h+y); int o = *(O+x*h+y);
    double xb = (double(x)+.5)/double(sBin)-0.5; int xb0=(xb<0) ? -1 : int(xb);
    double yb = (double(y)+.5)/double(sBin)-0.5; int yb0=(yb<0) ? -1 : int(yb);
    double xd0=xb-xb0, xd1=1.0-xd0; double yd0=yb-yb0, yd1=1.0-yd0;
    double *dst = hist + o*nb + xb0*hb + yb0;
    if( xb0>=0 && yb0>=0     ) *(dst)      += xd1*yd1*v;
    if( xb0+1<wb && yb0>=0   ) *(dst+hb)   += xd0*yd1*v;
    if( xb0>=0 && yb0+1<hb   ) *(dst+1)    += xd1*yd0*v;
    if( xb0+1<wb && yb0+1<hb ) *(dst+hb+1) += xd0*yd0*v;
  } else for( int x=0; x<w0; x++ ) for( int y=0; y<h0; y++ ) { // trilinear interp.
    double v=*(G+x*h+y); double o = double(*(O+x*h+y))/double(oGran);
    int o0=int(o); int o1=(o0+1)%oBin; double od0=o-o0, od1=1.0-od0;
    double xb = (double(x)+.5)/double(sBin)-0.5; int xb0=(xb<0) ? -1 : int(xb);
    double yb = (double(y)+.5)/double(sBin)-0.5; int yb0=(yb<0) ? -1 : int(yb);
    double xd0=xb-xb0, xd1=1.0-xd0; double yd0=yb-yb0, yd1=1.0-yd0;
    double *dst = hist + xb0*hb + yb0;
    if( xb0>=0 && yb0>=0     ) *(dst+o0*nb)      += od1*xd1*yd1*v;
    if( xb0+1<wb && yb0>=0   ) *(dst+hb+o0*nb)   += od1*xd0*yd1*v;
    if( xb0>=0 && yb0+1<hb   ) *(dst+1+o0*nb)    += od1*xd1*yd0*v;
    if( xb0+1<wb && yb0+1<hb ) *(dst+hb+1+o0*nb) += od1*xd0*yd0*v;
    if( xb0>=0 && yb0>=0     ) *(dst+o1*nb)      += od0*xd1*yd1*v;
    if( xb0+1<wb && yb0>=0   ) *(dst+hb+o1*nb)   += od0*xd0*yd1*v;
    if( xb0>=0 && yb0+1<hb   ) *(dst+1+o1*nb)    += od0*xd1*yd0*v;
    if( xb0+1<wb && yb0+1<hb ) *(dst+hb+1+o1*nb) += od0*xd0*yd0*v;
  }
  mxFree(G); mxFree(O);
  
  // compute energy in each block by summing over orientations
  double *norm = (double*) mxCalloc(nb, sizeof(double));
  for( int o=0; o<oBin; o++ ) {
    double *src=hist+o*nb, *dst=norm, *end=norm+nb;
    while( dst < end ) { *(dst++)+=(*src)*(*src); src++; }
  }
  
  // compute normalized values (4 different normalizations per block)
  const int out[3] = { max(hb-2, 0), max(wb-2, 0), oBin*4 }; const int outp=out[0]*out[1];
  mxArray *mxH = mxCreateNumericArray(3, out, mxDOUBLE_CLASS, mxREAL);
  double *H = (double*) mxGetPr(mxH);
  for( int x=0; x<out[1]; x++ ) for( int y=0; y<out[0]; y++ ) {
    double *dst=H+x*out[0]+y; double *src, *p, n;
    for( int x1=1; x1>=0; x1-- ) for( int y1=1; y1>=0; y1-- ) {
      p = norm + (x+x1)*hb + (y+y1);
      n = 1.0/sqrt(*p + *(p+1) + *(p+hb) + *(p+hb+1) + eps);
      src = hist + (x+1)*hb + (y+1);
      for( int o=0; o<oBin; o++ ) {
        *dst=min(*src*n, 0.2); dst+=outp; src+=nb;
      }
    }
  }
  mxFree(hist); mxFree(norm);
  return mxH;
}

// H = hog(I,sBin,oBin,oGran)
void				mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
  // Error checking
  if( nrhs<1 || nrhs>4 ) mexErrMsgTxt("One to four inputs expected.");
  if( nlhs>1 ) mexErrMsgTxt("One output expected.");
  int nDims=mxGetNumberOfDimensions(prhs[0]);
  const int *dims = mxGetDimensions(prhs[0]);
  int nCh=(nDims==2) ? 1 : dims[2];
  if( (nDims!=2 && nDims!=3) || mxGetClassID(prhs[0])!=mxDOUBLE_CLASS)
    mexErrMsgTxt("I must be a double 2 or 3 dim array.");
  
  // extract input arguments
  double *I = (double*) mxGetPr(prhs[0]);
  int sBin = (nrhs>=2) ? (int) mxGetScalar(prhs[1]) : 8;
  int oBin = (nrhs>=3) ? (int) mxGetScalar(prhs[2]) : 9;
  int oGran = (nrhs>=4) ? (int) mxGetScalar(prhs[3]) : 10;
  
  // compute HOG features
  plhs[0] = hog(I, dims[0], dims[1], nCh, sBin, oBin, oGran);
}
