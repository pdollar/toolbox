/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 3.00
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "wrappers.hpp"
#include "string.h"
#include <math.h>
#include <typeinfo>
#include "sse.hpp"
typedef unsigned char uchar;

// compute interpolation values for single column for resapling
template<class T> void resampleCoef( int ha, int hb, int &n, int *&yas,
  int *&ybs, T *&wts, int bd[2], int pad=0 )
{
  const T s = T(hb)/T(ha), sInv = 1/s; T wt, wt0=T(1e-3)*s;
  bool ds=ha>hb; int nMax; bd[0]=bd[1]=0;
  if(ds) { n=0; nMax=ha+(pad>2 ? pad : 2)*hb; } else { n=nMax=hb; }
  // initialize memory
  wts = (T*)alMalloc(nMax*sizeof(T),16);
  yas = (int*)alMalloc(nMax*sizeof(int),16);
  ybs = (int*)alMalloc(nMax*sizeof(int),16);
  if( ds ) for( int yb=0; yb<hb; yb++ ) {
    // create coefficients for downsampling
    T ya0f=yb*sInv, ya1f=ya0f+sInv, W=0;
    int ya0=int(ceil(ya0f)), ya1=int(ya1f), n1=0;
    for( int ya=ya0-1; ya<ya1+1; ya++ ) {
      wt=s; if(ya==ya0-1) wt=(ya0-ya0f)*s; else if(ya==ya1) wt=(ya1f-ya1)*s;
      if(wt>wt0 && ya>=0) { ybs[n]=yb; yas[n]=ya; wts[n]=wt; n++; n1++; W+=wt; }
    }
    if(W>1) for( int i=0; i<n1; i++ ) wts[n-n1+i]/=W;
    if(n1>bd[0]) bd[0]=n1;
    while( n1<pad ) { ybs[n]=yb; yas[n]=yas[n-1]; wts[n]=0; n++; n1++; }
  } else for( int yb=0; yb<hb; yb++ ) {
    // create coefficients for upsampling
    T yaf = (T(.5)+yb)*sInv-T(.5); int ya=(int) floor(yaf);
    wt=1; if(ya>=0 && ya<ha-1) wt=1-(yaf-ya);
    if(ya<0) { ya=0; bd[0]++; } if(ya>=ha-1) { ya=ha-1; bd[1]++; }
    ybs[yb]=yb; yas[yb]=ya; wts[yb]=wt;
  }
}

// resample A using bilinear interpolation and and store result in B
template<class T>
void resample( T *A, T *B, int ha, int hb, int wa, int wb, int d, T r ) {
  int hn, wn, x, x1, y, z, xa, xb, ya; T *A0, *A1, *A2, *A3, *B0, wt, wt1;
  T *C = (T*) alMalloc((ha+4)*sizeof(T),16); for(y=ha; y<ha+4; y++) C[y]=0;
  bool sse = (typeid(T)==typeid(float)) && !(size_t(A)&15) && !(size_t(B)&15);
  // get coefficients for resampling along w and h
  int *xas, *xbs, *yas, *ybs; T *xwts, *ywts; int xbd[2], ybd[2];
  resampleCoef<T>( wa, wb, wn, xas, xbs, xwts, xbd, 0 );
  resampleCoef<T>( ha, hb, hn, yas, ybs, ywts, ybd, 4 );
  if( wa==2*wb ) r/=2; if( wa==3*wb ) r/=3; if( wa==4*wb ) r/=4;
  r/=T(1+1e-6); for( y=0; y<hn; y++ ) ywts[y] *= r;
  // resample each channel in turn
  for( z=0; z<d; z++ ) for( x=0; x<wb; x++ ) {
    if(x==0) x1=0; xa=xas[x1]; xb=xbs[x1]; wt=xwts[x1]; wt1=1-wt; y=0;
    A0=A+z*ha*wa+xa*ha; A1=A0+ha, A2=A1+ha, A3=A2+ha; B0=B+z*hb*wb+xb*hb;
    // variables for SSE (simple casts to float)
    float *Af0, *Af1, *Af2, *Af3, *Bf0, *Cf, *ywtsf, wtf, wt1f;
    Af0=(float*) A0; Af1=(float*) A1; Af2=(float*) A2; Af3=(float*) A3;
    Bf0=(float*) B0; Cf=(float*) C;
    ywtsf=(float*) ywts; wtf=(float) wt; wt1f=(float) wt1;
    // resample along x direction (A -> C)
    #define FORs(X) if(sse) for(; y<ha-4; y+=4) STR(Cf[y],X);
    #define FORr(X) for(; y<ha; y++) C[y] = X;
    if( wa==2*wb ) {
      FORs( ADD(LDu(Af0[y]),LDu(Af1[y])) );
      FORr( A0[y]+A1[y] ); x1+=2;
    } else if( wa==3*wb ) {
      FORs( ADD(LDu(Af0[y]),LDu(Af1[y]),LDu(Af2[y])) );
      FORr( A0[y]+A1[y]+A2[y] ); x1+=3;
    } else if( wa==4*wb ) {
      FORs( ADD(LDu(Af0[y]),LDu(Af1[y]),LDu(Af2[y]),LDu(Af3[y])) );
      FORr( A0[y]+A1[y]+A2[y]+A3[y] ); x1+=4;
    } else if( wa>wb ) {
      int m=1; while( x1+m<wn && xb==xbs[x1+m] ) m++; float wtsf[4];
      for( int x0=0; x0<(m<4?m:4); x0++ ) wtsf[x0]=float(xwts[x1+x0]);
      #define U(x) MUL( LDu(*(Af ## x + y)), SET(wtsf[x]) )
      #define V(x) *(A ## x + y) * xwts[x1+x]
      if(m==1) { FORs(U(0));                     FORr(V(0)); }
      if(m==2) { FORs(ADD(U(0),U(1)));           FORr(V(0)+V(1)); }
      if(m==3) { FORs(ADD(U(0),U(1),U(2)));      FORr(V(0)+V(1)+V(2)); }
      if(m>=4) { FORs(ADD(U(0),U(1),U(2),U(3))); FORr(V(0)+V(1)+V(2)+V(3)); }
      #undef U
      #undef V
      for( int x0=4; x0<m; x0++ ) {
        A1=A0+x0*ha; wt1=xwts[x1+x0]; Af1=(float*) A1; wt1f=float(wt1); y=0;
        FORs(ADD(LD(Cf[y]),MUL(LDu(Af1[y]),SET(wt1f)))); FORr(C[y]+A1[y]*wt1);
      }
      x1+=m;
    } else {
      bool xBd = x<xbd[0] || x>=wb-xbd[1]; x1++;
      if(xBd) memcpy(C,A0,ha*sizeof(T));
      if(!xBd) FORs(ADD(MUL(LDu(Af0[y]),SET(wtf)),MUL(LDu(Af1[y]),SET(wt1f))));
      if(!xBd) FORr( A0[y]*wt + A1[y]*wt1 );
    }
    #undef FORs
    #undef FORr
    // resample along y direction (B -> C)
    if( ha==hb*2 ) {
      T r2 = r/2; int k=((~((size_t) B0) + 1) & 15)/4; y=0;
      for( ; y<k; y++ )  B0[y]=(C[2*y]+C[2*y+1])*r2;
      if(sse) for(; y<hb-4; y+=4) STR(Bf0[y],MUL((float)r2,_mm_shuffle_ps(ADD(
        LDu(Cf[2*y]),LDu(Cf[2*y+1])),ADD(LDu(Cf[2*y+4]),LDu(Cf[2*y+5])),136)));
      for( ; y<hb; y++ ) B0[y]=(C[2*y]+C[2*y+1])*r2;
    } else if( ha==hb*3 ) {
      for(y=0; y<hb; y++) B0[y]=(C[3*y]+C[3*y+1]+C[3*y+2])*(r/3);
    } else if( ha==hb*4 ) {
      for(y=0; y<hb; y++) B0[y]=(C[4*y]+C[4*y+1]+C[4*y+2]+C[4*y+3])*(r/4);
    } else if( ha>hb ) {
      y=0;
      //if( sse && ybd[0]<=4 ) for(; y<hb; y++) // Requires SSE4
      //  STR1(Bf0[y],_mm_dp_ps(LDu(Cf[yas[y*4]]),LDu(ywtsf[y*4]),0xF1));
      #define U(o) C[ya+o]*ywts[y*4+o]
      if(ybd[0]==2) for(; y<hb; y++) { ya=yas[y*4]; B0[y]=U(0)+U(1); }
      if(ybd[0]==3) for(; y<hb; y++) { ya=yas[y*4]; B0[y]=U(0)+U(1)+U(2); }
      if(ybd[0]==4) for(; y<hb; y++) { ya=yas[y*4]; B0[y]=U(0)+U(1)+U(2)+U(3); }
      if(ybd[0]>4)  for(; y<hn; y++) { B0[ybs[y]] += C[yas[y]] * ywts[y]; }
      #undef U
    } else {
      for(y=0; y<ybd[0]; y++) B0[y] = C[yas[y]]*ywts[y];
      for(; y<hb-ybd[1]; y++) B0[y] = C[yas[y]]*ywts[y]+C[yas[y]+1]*(r-ywts[y]);
      for(; y<hb; y++)        B0[y] = C[yas[y]]*ywts[y];
    }
  }
  alFree(xas); alFree(xbs); alFree(xwts); alFree(C);
  alFree(yas); alFree(ybs); alFree(ywts);
}

// B = imResampleMex(A,hb,wb,nrm); see imResample.m for usage details
#ifdef MATLAB_MEX_FILE
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int *ns, ms[3], n, m, nCh, nDims;
  void *A, *B; mxClassID id; double nrm;

  // Error checking on arguments
  if( nrhs!=4) mexErrMsgTxt("Four inputs expected.");
  if( nlhs>1 ) mexErrMsgTxt("One output expected.");
  nDims=mxGetNumberOfDimensions(prhs[0]); id=mxGetClassID(prhs[0]);
  ns = (int*) mxGetDimensions(prhs[0]); nCh=(nDims==2) ? 1 : ns[2];
  if( (nDims!=2 && nDims!=3) ||
    (id!=mxSINGLE_CLASS && id!=mxDOUBLE_CLASS && id!=mxUINT8_CLASS) )
    mexErrMsgTxt("A should be 2D or 3D single, double or uint8 array.");
  ms[0]=(int)mxGetScalar(prhs[1]); ms[1]=(int)mxGetScalar(prhs[2]); ms[2]=nCh;
  if( ms[0]<=0 || ms[1]<=0 ) mexErrMsgTxt("downsampling factor too small.");
  nrm=(double)mxGetScalar(prhs[3]);

  // create output array
  plhs[0] = mxCreateNumericArray(3, (const mwSize*) ms, id, mxREAL);
  n=ns[0]*ns[1]*nCh; m=ms[0]*ms[1]*nCh;

  // perform resampling (w appropriate type)
  A=mxGetData(prhs[0]); B=mxGetData(plhs[0]);
  if( id==mxDOUBLE_CLASS ) {
    resample((double*)A, (double*)B, ns[0], ms[0], ns[1], ms[1], nCh, nrm);
  } else if( id==mxSINGLE_CLASS ) {
    resample((float*)A, (float*)B, ns[0], ms[0], ns[1], ms[1], nCh, float(nrm));
  } else if( id==mxUINT8_CLASS ) {
    float *A1 = (float*) mxMalloc(n*sizeof(float));
    float *B1 = (float*) mxCalloc(m,sizeof(float));
    for(int i=0; i<n; i++) A1[i]=(float) ((uchar*)A)[i];
    resample(A1, B1, ns[0], ms[0], ns[1], ms[1], nCh, float(nrm));
    for(int i=0; i<m; i++) ((uchar*)B)[i]=(uchar) (B1[i]+.5);
  } else {
    mexErrMsgTxt("Unsupported type.");
  }
}
#endif
