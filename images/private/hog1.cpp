/*******************************************************************************
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2011 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
*******************************************************************************/
#include <math.h>
#include "mex.h"
#define PI 3.1415926535897931
double mind(double x, double y) { return (x <= y ? x : y); }

/* snap to one of oBin orientations using binary search */
int compOrient( double dx, double dy, double *ux, double *uy, int oBin ) {
  int o0, o1; double s0, s1;
  if(oBin<=1) return 0; o0=0; o1=oBin-1;
  s0=fabs(ux[o0]*dx+uy[o0]*dy);
  s1=fabs(ux[o1]*dx+uy[o1]*dy);
  while( 1 ) {
    if(o0==o1-1) { return ((s0>s1) ? o0 : o1); }
    if( s0<s1 ) {
      o0+=(o1-o0+1)>>1; s0=fabs(ux[o0]*dx+uy[o0]*dy);
    } else {
      o1-=(o1-o0+1)>>1; s1=fabs(ux[o1]*dx+uy[o1]*dy);
    }
  }
}

/* compute gradient magnitude and orientation at each location */
void gradMag(double *I, double *M, int *O, int h, int w, int d, int oBin ) {
  int x, y, c, o, a=w*h; double m, m1, dx, dx1, dy, dy1, rx, ry;
  double *ux, *uy, *Ix, *Ix0, *Ix1, *Iy0, *Iy1, *M0; int *O0;
  /* pre-compute unit vectors evenly distributed at oBin orientations */
  ux = (double*) mxMalloc(oBin*sizeof(double));
  uy = (double*) mxMalloc(oBin*sizeof(double));
  for( o=0; o<oBin; o++ ) ux[o]=cos( ((double)o)/((double)oBin)*PI );
  for( o=0; o<oBin; o++ ) uy[o]=sin( ((double)o)/((double)oBin)*PI );
  /* compute gradient magnitude and orientation at each location */
  for( x=0; x<w; x++ ) {
    rx=.5; M0=M+x*h; O0=O+x*h; Ix=I+x*h; Ix0=Ix-h; Ix1=Ix+h;
    if(x==0) { Ix0=Ix; rx=1; } else if(x==w-1) { Ix1=Ix; rx=1; }
    for( y=0; y<h; y++ ) {
      if(y==0) {   Iy0=Ix-0; Iy1=Ix+1; ry=1; }
      if(y==1) {   Iy0=Ix-1; Iy1=Ix+1; ry=.5; }
      if(y==h-1) { Iy0=Ix-1; Iy1=Ix+0; ry=1; }
      dy=(*Iy1-*Iy0)*ry; dx=(*Ix1-*Ix0)*rx; m=dx*dx+dy*dy;
      for(c=1; c<d; c++) {
        dy1=(*(Iy1+c*a)-*(Iy0+c*a))*ry; dx1=(*(Ix1+c*a)-*(Ix0+c*a))*rx;
        m1=dx1*dx1+dy1*dy1; if(m1>m) { m=m1; dx=dx1; dy=dy1; }
      }
      *(M0++)=sqrt(m); *(O0++)=compOrient(dx,dy,ux,uy,oBin);
      Ix0++; Ix1++; Iy0++; Iy1++; Ix++;
    }
  }
  mxFree(ux); mxFree(uy);
}

/* compute oBin gradient histograms per sBin x sBin block of pixels */
void gradHist( double *M, int *O, double *H, int h, int w, int d,
  int sBin, int oBin, int oGr, bool soft )
{
  const int hb=h/sBin, wb=w/sBin, h0=hb*sBin, w0=wb*sBin, nb=wb*hb;
  const double s=sBin, sInv=1/s, sInv2=1/s/s, oGrInv=1/((double)oGr);
  double *H0; int x, y, xy, o0, o1, xb0, yb0, oBin1=oBin*nb;
  double od0, od1, o, m, m0, m1, xb, yb, xd0, xd1, yd0, yd1;
  if( !soft || sBin==1 ) { for( x=0; x<w0; x++ ) for( y=0; y<h0; y++ ) {
    /* interpolate w.r.t. orientation only, not spatial bin */
    xy=x*h+y; m=M[xy]*sInv2; o=O[xy]*oGrInv; o0=(int) o;
    m1=(o-o0)*m; m0=m-m1; o0*=nb; o1=o0+nb; if(o1==oBin1) o1=0;
    H0=H+(x/sBin)*hb+y/sBin; H0[o0]+=m0; H0[o1]+=m1;
  } return; }
  for( x=0; x<w0; x++ ) for( y=0; y<h0; y++ ) {
    /* get interpolation coefficients */
    xy=x*h+y; m=M[xy]*sInv2; o=O[xy]*oGrInv; o0=(int) o;
    xb=(((double) x)+.5)*sInv-0.5; xb0=(xb<0) ? -1 : (int) xb;
    yb=(((double) y)+.5)*sInv-0.5; yb0=(yb<0) ? -1 : (int) yb;
    xd0=xb-xb0; xd1=1.0-xd0; yd0=yb-yb0; yd1=1.0-yd0; H0=H+xb0*hb+yb0;
    /* interpolate using bilinear or trilinear interpolation */
    if( oGr==1 ) {
      o0*=nb;
      if( xb0>=0 && yb0>=0     ) *(H0+o0)      += xd1*yd1*m;
      if( xb0+1<wb && yb0>=0   ) *(H0+hb+o0)   += xd0*yd1*m;
      if( xb0>=0 && yb0+1<hb   ) *(H0+1+o0)    += xd1*yd0*m;
      if( xb0+1<wb && yb0+1<hb ) *(H0+hb+1+o0) += xd0*yd0*m;
    } else {
      od0=o-o0; od1=1.0-od0; o0*=nb; o1=o0+nb; if(o1==oBin1) o1=0;
      if( xb0>=0 && yb0>=0     ) *(H0+o0)      += od1*xd1*yd1*m;
      if( xb0+1<wb && yb0>=0   ) *(H0+hb+o0)   += od1*xd0*yd1*m;
      if( xb0>=0 && yb0+1<hb   ) *(H0+1+o0)    += od1*xd1*yd0*m;
      if( xb0+1<wb && yb0+1<hb ) *(H0+hb+1+o0) += od1*xd0*yd0*m;
      if( xb0>=0 && yb0>=0     ) *(H0+o1)      += od0*xd1*yd1*m;
      if( xb0+1<wb && yb0>=0   ) *(H0+hb+o1)   += od0*xd0*yd1*m;
      if( xb0>=0 && yb0+1<hb   ) *(H0+1+o1)    += od0*xd1*yd0*m;
      if( xb0+1<wb && yb0+1<hb ) *(H0+hb+1+o1) += od0*xd0*yd0*m;
    }
  }
}

/* compute HOG features given gradient histograms */
void hog( double *H, double *HG, int h, int w, int d, int sBin, int oBin ) {
  double *N, *N1, *H1, *HG1, n; int o, x, y, x1, y1, hb, wb, nb, hb1, wb1, nb1;
  double eps = 1e-4/4.0/sBin/sBin/sBin/sBin; /* precise backward equality */
  hb=h/sBin; wb=w/sBin; nb=wb*hb; hb1=hb-2; wb1=wb-2; nb1=hb1*wb1;
  if(hb1<=0 || wb1<=0) return; N = (double*) mxCalloc(nb,sizeof(double));
  for(o=0; o<oBin; o++) for(x=0; x<nb; x++) N[x]+=H[x+o*nb]*H[x+o*nb];
  for( x=0; x<wb1; x++ ) for( y=0; y<hb1; y++ ) {
    HG1 = HG + x*hb1 + y; /* perform 4 normalizations per spatial block */
    for(x1=1; x1>=0; x1--) for(y1=1; y1>=0; y1--) {
      N1 = N + (x+x1)*hb + (y+y1);  H1 = H + (x+1)*hb + (y+1);
      n = 1.0/sqrt(*N1 + *(N1+1) + *(N1+hb) + *(N1+hb+1) + eps);
      for(o=0; o<oBin; o++) { *HG1=mind(*H1*n, 0.2); HG1+=nb1; H1+=nb; }
    }
  } mxFree(N);
}

/* Create [wxhxd] mxArray array, do NOT initialize to 0 */
mxArray* mxCreateMatrix3(int h, int w, int d, mxClassID id, bool c, void **I ) {
  const int dims[3]={h,w,d}, n=h*w*d; int b; mxArray* M;
  if( id==mxINT32_CLASS ) b=sizeof(int);
  else if( id==mxDOUBLE_CLASS ) b=sizeof(double);
  else mexErrMsgTxt("Unknown mxClassID.");
  *I = c ? mxCalloc(n,b) : mxMalloc(n*b);
  M = mxCreateNumericMatrix(0,0,id,mxREAL);
  mxSetData(M,*I); mxSetDimensions(M,dims,3); return M;
}

/* Check inputs and outputs to mex, retrieve first input I */
void checkArgs( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[],
  int nl0, int nl1, int nr0, int nr1, int *h, int *w, int *d, double **I )
{
  const int *dims; int nDims;
  if( nlhs<nl0 || nlhs>nl1 ) mexErrMsgTxt("Incorrect number of outputs.");
  if( nrhs<nr0 || nrhs>nr1 ) mexErrMsgTxt("Incorrect number of inputs.");
  nDims = mxGetNumberOfDimensions(prhs[0]); dims = mxGetDimensions(prhs[0]);
  *h=dims[0]; *w=dims[1]; *d=(nDims==2) ? 1 : dims[2];
  if( (nDims!=2 && nDims!=3) || mxGetClassID(prhs[0])!=mxDOUBLE_CLASS)
    mexErrMsgTxt("First input must be a double 2 or 3 dimensional array.");
  *I = (double*) mxGetPr(prhs[0]);
}

/* H = hog( I, [sBin], [oBin], [oGran] ) - see hog.m */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
  int h, w, d, hb, wb, nb, hb1, wb1, sBin, oBin, oGr;
  double *I, *M, *H, *HG; int *O;
  checkArgs(nlhs,plhs,nrhs,prhs,1,1,1,4,&h,&w,&d,&I);
  sBin = (nrhs>=2) ? (int) mxGetScalar(prhs[1]) : 8;
  oBin = (nrhs>=3) ? (int) mxGetScalar(prhs[2]) : 9;
  oGr  = (nrhs>=4) ? (int) mxGetScalar(prhs[3]) : 10;
  hb=h/sBin; wb=w/sBin; nb=wb*hb; hb1=hb>2?hb-2:0; wb1=wb>2?wb-2:0;
  plhs[0] = mxCreateMatrix3( hb1, wb1, oBin*4, mxDOUBLE_CLASS, 0, (void**) &HG);
  if( hb1==0 || wb1==0 ) return;
  M = (double*) mxMalloc(h*w*sizeof(double));
  O = (int*) mxMalloc(h*w*sizeof(int));
  H = (double*) mxCalloc(nb*oBin, sizeof(double));
  gradMag( I, M, O, h, w, d, oBin*oGr );
  gradHist( M, O, H, h, w, d, sBin, oBin, oGr, true );
  hog( H, HG, h, w, d, sBin, oBin );
  mxFree(M); mxFree(O); mxFree(H);
}
