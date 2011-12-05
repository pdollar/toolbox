/*******************************************************************************
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2011 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
*******************************************************************************/
#include <math.h>
#include "mex.h"
typedef unsigned char uchar;

// compute interpolation values for single column for resapling
template<class T> void resampleCoef( int ha, int hb, int &n, int *&yas,
  int *&ybs, T *&wts, int bd[2], int pad=0 )
{
  const T s = T(hb)/T(ha), sInv = 1/s; T wt, wt0=T(1e-3)*s;
  bool ds=ha>hb; int nMax; bd[0]=bd[1]=0;
  if(ds) { n=0; nMax=ha+(pad>2 ? pad : 2)*hb; } else { n=nMax=hb; }
  // initialize memory
  wts = (T*)mxMalloc(nMax*sizeof(T));
  yas = (int*)mxMalloc(nMax*sizeof(int));
  ybs = (int*)mxMalloc(nMax*sizeof(int));
  if( ds ) for( int yb=0; yb<hb; yb++ ) {
    // create coefficients for downsampling
    T ya0f=yb*sInv, ya1f=ya0f+sInv;
    int ya0=int(ceil(ya0f)), ya1=int(ya1f), n1=0;
    for( int ya=ya0-1; ya<ya1+1; ya++ ) {
      wt=s; if(ya==ya0-1) wt=(ya0-ya0f)*s; else if(ya==ya1) wt=(ya1f-ya1)*s;
      if(wt>wt0 && ya>=0) { ybs[n]=yb; yas[n]=ya; wts[n]=wt; n++; n1++; }
    }
    if(n1>bd[0]) bd[0]=n1;
    while( n1<pad ) { ybs[n]=yb; yas[n]=yas[n-1]; wts[n]=0; n++; n1++; }
  } else for( int yb=0; yb<hb; yb++ ) {
    // create coefficients for upsampling
    T yaf = (T(.5)+yb)*sInv-T(.5); int ya=(int) floor(yaf);
    wt=1; if(ya>=0 && ya<ha) wt=1-(yaf-ya);
    if(ya<0) { ya=0; bd[0]++; } if(ya>=ha-1) { ya=ha-1; bd[1]++; }
    ybs[yb]=yb; yas[yb]=ya; wts[yb]=wt;
  }
}

// resample A using bilinear interpolation and and store result in B
template<class T>
void resample( T *A, T *B, int ha, int hb, int wa, int wb, int d ) {
  int hn, wn, x, y, z, xa, xb; T *A0, *B0, wt; bool xBd;
  T *C = (T*) mxMalloc((ha+4)*sizeof(T));
  // get coefficients for resampling along w and h
  int *xas, *xbs, *yas, *ybs; T *xwts, *ywts; int xbd[2], ybd[2];
  resampleCoef<T>( wa, wb, wn, xas, xbs, xwts, xbd, 0 );
  resampleCoef<T>( ha, hb, hn, yas, ybs, ywts, ybd, 4 );
  // resample each channel in turn
  for( z=0; z<d; z++ ) for( x=0; x<wn; x++ ) {
    xa=xas[x]; xb=xbs[x]; wt=xwts[x];
    A0=A+z*ha*wa+xa*ha; B0=B+z*hb*wb+xb*hb;
    // resample along x direction (A -> C)
    if( wa>wb ) {
      xBd = x==0 || xb!=xbs[x-1];
      if(xBd) for(y=0; y<ha; y++) C[y]  = A0[y] * wt;
      else    for(y=0; y<ha; y++) C[y] += A0[y] * wt;
    } else {
      xBd = x<xbd[0] || x>=wb-xbd[1]; T wt1=1-wt, *A1=A0+ha;
      if(xBd) for(y=0; y<ha; y++) C[y] = A0[y];
      else    for(y=0; y<ha; y++) C[y] = A0[y] * wt + A1[y] * wt1;
    }
    // resample along y direction (B -> C)
    if( ha>hb ) {
      xBd = x==wn-1 || xb!=xbs[x+1]; if(!xBd) continue; int ya, y=0;
      #define U(o) C[ya+o]*ywts[y*4+o]
      if(ybd[0]==2) for(; y<hb; y++) { ya=yas[y*4]; B0[y]=U(0)+U(1); }
      if(ybd[0]==3) for(; y<hb; y++) { ya=yas[y*4]; B0[y]=U(0)+U(1)+U(2); }
      if(ybd[0]==4) for(; y<hb; y++) { ya=yas[y*4]; B0[y]=U(0)+U(1)+U(2)+U(3); }
      if(ybd[0]>4)  for(; y<hn; y++) { B0[ybs[y]] += C[yas[y]] * ywts[y]; }
      #undef U
    } else {
      for(y=0; y<ybd[0]; y++) B0[y] = C[yas[y]];
      for(; y<hb-ybd[1]; y++) B0[y] = C[yas[y]]*ywts[y]+C[yas[y]+1]*(1-ywts[y]);
      for(; y<hb; y++)        B0[y] = C[yas[y]];
    }
  }
  mxFree(xas); mxFree(xbs); mxFree(xwts); mxFree(C);
  mxFree(yas); mxFree(ybs); mxFree(ywts);
}

// B=imResample(A,scale) or B=imResample(A,h,w);
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double input1=0, input2=0; int *ns, ms[3], n, m, nCh, nDims;
  void *A, *B; mxClassID id;

  // Error checking on arguments
  if( nrhs<2 || nrhs>3) mexErrMsgTxt("Two or three inputs expected.");
  if( nlhs>1 ) mexErrMsgTxt("One output expected.");
  nDims=mxGetNumberOfDimensions(prhs[0]); id=mxGetClassID(prhs[0]);
  if( (nDims!=2 && nDims!=3) ||
    (id!=mxSINGLE_CLASS && id!=mxDOUBLE_CLASS && id!=mxUINT8_CLASS) )
    mexErrMsgTxt("A should be 2D or 3D single, double or uint8 array.");
  input1=mxGetScalar(prhs[1]); if(nrhs>=3) input2=mxGetScalar(prhs[2]);

  // create output array
  ns = (int*) mxGetDimensions(prhs[0]); nCh=(nDims==2) ? 1 : ns[2]; ms[2]=nCh;
  if( nrhs==2 ) {
    ms[0]=(int) (ns[0]*input1+.5); ms[1]=(int) (ns[1]*input1+.5);
  } else {
    ms[0]=(int) input1; ms[1]=(int) input2;
  }
  if( ms[0]<=0 || ms[1]<=0 ) mexErrMsgTxt("downsampling factor too small.");
  plhs[0] = mxCreateNumericArray(3, (const mwSize*) ms, id, mxREAL);
  n=ns[0]*ns[1]*nCh; m=ms[0]*ms[1]*nCh;

  // convert to double if id!=mxDOUBLE_CLASS
  A=mxGetData(prhs[0]); B=mxGetData(plhs[0]);
  if( id==mxDOUBLE_CLASS ) {
    resample( (double*) A, (double*) B, ns[0], ms[0], ns[1], ms[1], nCh );
  } else if( id==mxSINGLE_CLASS ) {
    resample( (float*) A, (float*) B, ns[0], ms[0], ns[1], ms[1], nCh );
  } else if( id==mxUINT8_CLASS ) {
    float *A1 = (float*) mxMalloc(n*sizeof(float));
    float *B1 = (float*) mxCalloc(m,sizeof(float));
    for(int i=0; i<n; i++) A1[i]=(float) ((uchar*)A)[i];
    resample( A1, B1, ns[0], ms[0], ns[1], ms[1], nCh );
    for(int i=0; i<m; i++) ((uchar*)B)[i]=(uchar) (B1[i]+.5);
  } else {
    mexErrMsgTxt("Unsupported type.");
  }
}
