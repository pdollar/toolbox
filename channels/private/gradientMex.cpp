/*******************************************************************************
* Piotr's Image&Video Toolbox      Version 3.00
* Copyright 2012 Piotr Dollar & Ron Appel.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "wrappers.hpp"
#include <math.h>
#include "string.h"
#include "sse.hpp"

#define PI 3.1415926535897931f

// compute x and y gradients for just one column (uses sse)
void grad1( float *I, float *Gx, float *Gy, int h, int w, int x ) {
  int y, y1; float *Ip, *In, r; __m128 *_Ip, *_In, *_G, _r;
  // compute column of Gx
  Ip=I-h; In=I+h; r=.5f;
  if(x==0) { r=1; Ip+=h; } else if(x==w-1) { r=1; In-=h; }
  if( h<4 || h%4>0 || (size_t(I)&15) || (size_t(Gx)&15) ) {
    for( y=0; y<h; y++ ) *Gx++=(*In++-*Ip++)*r;
  } else {
    _G=(__m128*) Gx; _Ip=(__m128*) Ip; _In=(__m128*) In; _r = SET(r);
    for(y=0; y<h; y+=4) *_G++=MUL(SUB(*_In++,*_Ip++),_r);
  }
  // compute column of Gy
  #define GRADY(r) *Gy++=(*In++-*Ip++)*r;
  Ip=I; In=Ip+1;
  // GRADY(1); Ip--; for(y=1; y<h-1; y++) GRADY(.5f); In--; GRADY(1);
  y1=((~((size_t) Gy) + 1) & 15)/4; if(y1==0) y1=4; if(y1>h-1) y1=h-1;
  GRADY(1); Ip--; for(y=1; y<y1; y++) GRADY(.5f);
  _r = SET(.5f); _G=(__m128*) Gy;
  for(; y+4<h-1; y+=4, Ip+=4, In+=4, Gy+=4)
    *_G++=MUL(SUB(LDu(*In),LDu(*Ip)),_r);
  for(; y<h-1; y++) GRADY(.5f); In--; GRADY(1);
  #undef GRADY
}

// compute x and y gradients at each location (uses sse)
void grad2( float *I, float *Gx, float *Gy, int h, int w, int d ) {
  int o, x, c, a=w*h; for(c=0; c<d; c++) for(x=0; x<w; x++) {
    o=c*a+x*h; grad1( I+o, Gx+o, Gy+o, h, w, x );
  }
}

// build lookup table a[] s.t. a[dx/2.02*n]~=acos(dx)
float* acosTable() {
  int i, n=25000, n2=n/2; float t, ni;
  static float a[25000]; static bool init=false;
  if( init ) return a+n2; ni = 2.02f/(float) n;
  for( i=0; i<n; i++ ) {
    t = i*ni - 1.01f;
    t = t<-1 ? -1 : (t>1 ? 1 : t);
    t = (float) acos( t );
    a[i] = (t <= PI-1e-5f) ? t : 0;
  }
  init=true; return a+n2;
}

// compute gradient magnitude and orientation at each location (uses sse)
void gradMag( float *I, float *M, float *O, int h, int w, int d ) {
  int x, y, y1, c, h4, s; float *Gx, *Gy, *M2; __m128 *_Gx, *_Gy, *_M2, _m;
  float *acost = acosTable(), acMult=25000/2.02f;
  // allocate memory for storing one column of output (padded so h4%4==0)
  h4=(h%4==0) ? h : h-(h%4)+4; s=d*h4*sizeof(float);
  M2=(float*) alMalloc(s,16); _M2=(__m128*) M2;
  Gx=(float*) alMalloc(s,16); _Gx=(__m128*) Gx;
  Gy=(float*) alMalloc(s,16); _Gy=(__m128*) Gy;
  // compute gradient magnitude and orientation for each column
  for( x=0; x<w; x++ ) {
    // compute gradients (Gx, Gy) and squared magnitude (M2) for each channel
    for( c=0; c<d; c++ ) grad1( I+x*h+c*w*h, Gx+c*h4, Gy+c*h4, h, w, x );
    for( y=0; y<d*h4/4; y++ ) _M2[y]=ADD(MUL(_Gx[y],_Gx[y]),MUL(_Gy[y],_Gy[y]));
    // store gradients with maximum response in the first channel
    for(c=1; c<d; c++) {
      for( y=0; y<h4/4; y++ ) {
        y1=h4/4*c+y; _m = CMPGT( _M2[y1], _M2[y] );
        _M2[y] = OR( AND(_m,_M2[y1]), ANDNOT(_m,_M2[y]) );
        _Gx[y] = OR( AND(_m,_Gx[y1]), ANDNOT(_m,_Gx[y]) );
        _Gy[y] = OR( AND(_m,_Gy[y1]), ANDNOT(_m,_Gy[y]) );
      }
    }
    // compute gradient mangitude (M) and normalize Gx
    for( y=0; y<h4/4; y++ ) {
      _m = MIN( RCPSQRT(_M2[y]), SET(1e10f) );
      _M2[y] = RCP(_m);
      _Gx[y] = MUL( MUL(_Gx[y],_m), SET(acMult) );
      _Gx[y] = XOR( _Gx[y], AND(_Gy[y], SET(-0.f)) );
    };
    memcpy( M+x*h, M2, h*sizeof(float) );
    // compute and store gradient orientation (O) via table lookup
    if(O!=0) for( y=0; y<h; y++ ) O[x*h+y] = acost[(int)Gx[y]];
  }
  alFree(Gx); alFree(Gy); alFree(M2);
}

// normalize gradient magnitude at each location (uses sse)
void gradMagNorm( float *M, float *S, int h, int w, float norm ) {
  __m128 *_M, *_S, _norm; int i=0, n=h*w, n4=n/4;
  _S = (__m128*) S; _M = (__m128*) M; _norm = SET(norm);
  bool sse = !(size_t(M)&15) && !(size_t(S)&15);
  if(sse) { for(; i<n4; i++) *_M++=MUL(*_M,RCP(ADD(*_S++,_norm))); i*=4; }
  for(; i<n; i++) M[i] /= (S[i] + norm);
}

// helper for gradHist, quantize O and M into O0, O1 and M0, M1 (uses sse)
void gradQuantize( float *O, float *M, int *O0, int *O1, float *M0, float *M1,
  int nOrients, int nb, int n, float norm )
{
  // assumes all *OUTPUT* matrices are 4-byte aligned
  int i, o0, o1; float o, od, m;
  __m128i _o0, _o1, *_O0, *_O1; __m128 _o, _o0f, _m, *_M0, *_M1;
  // define useful constants
  const float oMult=(float)nOrients/PI; const int oMax=nOrients*nb;
  const __m128 _norm=SET(norm), _oMult=SET(oMult), _nbf=SET((float)nb);
  const __m128i _oMax=SET(oMax), _nb=SET(nb);
  // perform the majority of the work with sse
  _O0=(__m128i*) O0; _O1=(__m128i*) O1; _M0=(__m128*) M0; _M1=(__m128*) M1;
  for( i=0; i<=n-4; i+=4 ) {
    _o=MUL(LDu(O[i]),_oMult); _o0f=CVT(CVT(_o)); _o0=CVT(MUL(_o0f,_nbf));
    _o1=ADD(_o0,_nb); _o1=AND(CMPGT(_oMax,_o1),_o1);
    *_O0++=_o0; *_O1++=_o1; _m=MUL(LDu(M[i]),_norm);
    *_M1=MUL(SUB(_o,_o0f),_m); *_M0=SUB(_m,*_M1); _M0++; _M1++;
  }
  // compute trailing locations without sse
  for( i; i<n; i++ ) {
    o=O[i]*oMult; m=M[i]*norm; o0=(int) o; od=o-o0;
    o0*=nb; o1=o0+nb; if(o1==oMax) o1=0;
    O0[i]=o0; O1[i]=o1; M1[i]=od*m; M0[i]=m-M1[i];
  }
}

// compute nOrients gradient histograms per bin x bin block of pixels
void gradHist( float *M, float *O, float *H, int h, int w,
  int bin, int nOrients, bool softBin )
{
  const int hb=h/bin, wb=w/bin, h0=hb*bin, w0=wb*bin, nb=wb*hb;
  const float s=(float)bin, sInv=1/s, sInv2=1/s/s;
  float *H0, *H1, *M0, *M1; int x, y; int *O0, *O1;
  O0=(int*)alMalloc(h*sizeof(int),16); M0=(float*) alMalloc(h*sizeof(float),16);
  O1=(int*)alMalloc(h*sizeof(int),16); M1=(float*) alMalloc(h*sizeof(float),16);
  // main loop
  for( x=0; x<w0; x++ ) {
    // compute target orientation bins for entire column - very fast
    gradQuantize( O+x*h, M+x*h, O0, O1, M0, M1, nOrients, nb, h0, sInv2 );

    if( !softBin || bin==1 ) {
      // interpolate w.r.t. orientation only, not spatial bin
      H1=H+(x/bin)*hb;
      #define GH H1[O0[y]]+=M0[y]; H1[O1[y]]+=M1[y]; y++;
      if( bin==1 )      for(y=0; y<h0;) { GH; H1++; }
      else if( bin==2 ) for(y=0; y<h0;) { GH; GH; H1++; }
      else if( bin==3 ) for(y=0; y<h0;) { GH; GH; GH; H1++; }
      else if( bin==4 ) for(y=0; y<h0;) { GH; GH; GH; GH; H1++; }
      else for( y=0; y<h0;) { for( int y1=0; y1<bin; y1++ ) { GH; } H1++; }
      #undef GH

    } else {
      // interpolate using trilinear interpolation
      float ms[4], xyd, xb, yb, xd, yd, init; __m128 _m, _m0, _m1;
      bool hasLf, hasRt; int xb0, yb0;
      if( x==0 ) { init=(0+.5f)*sInv-0.5f; xb=init; }
      hasLf = xb>=0; xb0 = hasLf?(int)xb:-1; hasRt = xb0 < wb-1;
      xd=xb-xb0; xb+=sInv; yb=init; y=0;
      // macros for code conciseness
      #define GHinit yd=yb-yb0; yb+=sInv; H0=H+xb0*hb+yb0; xyd=xd*yd; \
        ms[0]=1-xd-yd+xyd; ms[1]=yd-xyd; ms[2]=xd-xyd; ms[3]=xyd;
      #define GH(H,ma,mb) H1=H; STRu(*H1,ADD(LDu(*H1),MUL(ma,mb)));
      // leading rows, no top bin
      for( ; y<bin/2; y++ ) {
        yb0=-1; GHinit;
        if(hasLf) { H0[O0[y]+1]+=ms[1]*M0[y]; H0[O1[y]+1]+=ms[1]*M1[y]; }
        if(hasRt) { H0[O0[y]+hb+1]+=ms[3]*M0[y]; H0[O1[y]+hb+1]+=ms[3]*M1[y]; }
      }
      // main rows, has top and bottom bins, use SSE for minor speedup
      for( ; ; y++ ) {
        yb0 = (int) yb; if(yb0>=hb-1) break; GHinit;
        _m0=SET(M0[y]); _m1=SET(M1[y]);
        if(hasLf) { _m=SET(0,0,ms[1],ms[0]);
          GH(H0+O0[y],_m,_m0); GH(H0+O1[y],_m,_m1); }
        if(hasRt) { _m=SET(0,0,ms[3],ms[2]);
          GH(H0+O0[y]+hb,_m,_m0); GH(H0+O1[y]+hb,_m,_m1); }
      }
      // final rows, no bottom bin
      for( ; y<h0; y++ ) {
        yb0 = (int) yb; GHinit;
        if(hasLf) { H0[O0[y]]+=ms[0]*M0[y]; H0[O1[y]]+=ms[0]*M1[y]; }
        if(hasRt) { H0[O0[y]+hb]+=ms[2]*M0[y]; H0[O1[y]+hb]+=ms[2]*M1[y]; }
      }
      #undef GHinit
      #undef GH
    }
  }
  alFree(O0); alFree(O1); alFree(M0); alFree(M1);
}

// compute HOG features given gradient histograms
void hog( float *H, float *G, int h, int w, int bin, int nOrients, float clip ){
  float *N, *N1, *H1; int o, x, y, hb=h/bin, wb=w/bin, nb=wb*hb;
  float eps = 1e-4f/4/bin/bin/bin/bin; // precise backward equality
  // compute 2x2 block normalization values
  N = (float*) wrCalloc(nb,sizeof(float));
  for( o=0; o<nOrients; o++ ) for( x=0; x<nb; x++ ) N[x]+=H[x+o*nb]*H[x+o*nb];
  for( x=0; x<wb-1; x++ ) for( y=0; y<hb-1; y++ ) {
    N1=N+x*hb+y; *N1=1/float(sqrt( N1[0] + N1[1] + N1[hb] + N1[hb+1] +eps )); }
  // perform 4 normalizations per spatial block (handling boundary regions)
  #define U(a,b) Gs[a][y]=H1[y]*N1[y-(b)]; if(Gs[a][y]>clip) Gs[a][y]=clip;
  for( o=0; o<nOrients; o++ ) for( x=0; x<wb; x++ ) {
    H1=H+o*nb+x*hb; N1=N+x*hb; float *Gs[4]; Gs[0]=G+o*nb+x*hb;
    for( y=1; y<4; y++ ) Gs[y]=Gs[y-1]+nb*nOrients;
    bool lf, md, rt; lf=(x==0); rt=(x==wb-1); md=(!lf && !rt);
    y=0; if(!rt) U(0,0); if(!lf) U(2,hb);
    if(lf) for( y=1; y<hb-1; y++ ) { U(0,0); U(1,1); }
    if(md) for( y=1; y<hb-1; y++ ) { U(0,0); U(1,1); U(2,hb); U(3,hb+1); }
    if(rt) for( y=1; y<hb-1; y++ ) { U(2,hb); U(3,hb+1); }
    y=hb-1; if(!rt) U(1,1); if(!lf) U(3,hb+1);
  } wrFree(N);
  #undef U
}

/******************************************************************************/
#ifdef MATLAB_MEX_FILE
// Create [hxwxd] mxArray array, initialize to 0 if c=true
mxArray* mxCreateMatrix3( int h, int w, int d, mxClassID id, bool c, void **I ){
  const int dims[3]={h,w,d}, n=h*w*d; int b; mxArray* M;
  if( id==mxINT32_CLASS ) b=sizeof(int);
  else if( id==mxDOUBLE_CLASS ) b=sizeof(double);
  else if( id==mxSINGLE_CLASS ) b=sizeof(float);
  else mexErrMsgTxt("Unknown mxClassID.");
  *I = c ? mxCalloc(n,b) : mxMalloc(n*b);
  M = mxCreateNumericMatrix(0,0,id,mxREAL);
  mxSetData(M,*I); mxSetDimensions(M,dims,3); return M;
}

// Check inputs and outputs to mex, retrieve first input I
void checkArgs( int nl, mxArray *pl[], int nr, const mxArray *pr[], int nl0,
  int nl1, int nr0, int nr1, int *h, int *w, int *d, mxClassID id, void **I )
{
  const int *dims; int nDims;
  if( nl<nl0 || nl>nl1 ) mexErrMsgTxt("Incorrect number of outputs.");
  if( nr<nr0 || nr>nr1 ) mexErrMsgTxt("Incorrect number of inputs.");
  nDims = mxGetNumberOfDimensions(pr[0]); dims = mxGetDimensions(pr[0]);
  *h=dims[0]; *w=dims[1]; *d=(nDims==2) ? 1 : dims[2]; *I = mxGetPr(pr[0]);
  if( nDims!=2 && nDims!=3 ) mexErrMsgTxt("I must be a 2D or 3D array.");
  if( mxGetClassID(pr[0])!=id ) mexErrMsgTxt("I has incorrect type.");
}

// [Gx,Gy] = grad2(I) - see gradient2.m
void mGrad2( int nl, mxArray *pl[], int nr, const mxArray *pr[] ) {
  int h, w, d; float *I, *Gx, *Gy;
  checkArgs(nl,pl,nr,pr,1,2,1,1,&h,&w,&d,mxSINGLE_CLASS,(void**)&I);
  if(h<2 || w<2) mexErrMsgTxt("I must be at least 2x2.");
  pl[0]= mxCreateMatrix3( h, w, d, mxSINGLE_CLASS, 0, (void**) &Gx );
  pl[1]= mxCreateMatrix3( h, w, d, mxSINGLE_CLASS, 0, (void**) &Gy );
  grad2( I, Gx, Gy, h, w, d );
}

// [M,O] = gradMag( I, [channel] ) - see gradientMag.m
void mGradMag( int nl, mxArray *pl[], int nr, const mxArray *pr[] ) {
  int h, w, d, c; float *I, *M, *O=0;
  checkArgs(nl,pl,nr,pr,1,2,1,2,&h,&w,&d,mxSINGLE_CLASS,(void**)&I);
  if(h<2 || w<2) mexErrMsgTxt("I must be at least 2x2.");
  c = (nr>=2) ? (int) mxGetScalar(pr[1]) : 0;
  if( c>0 && c<=d ) { I += h*w*(c-1); d=1; }
  pl[0] = mxCreateMatrix3(h,w,1,mxSINGLE_CLASS,0,(void**)&M);
  if(nl>=2) pl[1] = mxCreateMatrix3(h,w,1,mxSINGLE_CLASS,0,(void**)&O);
  gradMag(I, M, O, h, w, d );
}

// gradMagNorm( M, S, norm ) - operates on M - see gradientMag.m
void mGradMagNorm( int nl, mxArray *pl[], int nr, const mxArray *pr[] ) {
  int h, w, d; float *M, *S, norm;
  checkArgs(nl,pl,nr,pr,0,0,3,3,&h,&w,&d,mxSINGLE_CLASS,(void**)&M);
  if( mxGetM(pr[1])!=h || mxGetN(pr[1])!=w || d!=1 ||
    mxGetClassID(pr[1])!=mxSINGLE_CLASS ) mexErrMsgTxt("M or S is bad.");
  S = (float*) mxGetPr(pr[1]); norm = (float) mxGetScalar(pr[2]);
  gradMagNorm(M,S,h,w,norm);
}

// H=gradHist(M,O,[bin],[nOrients],[softBin],[useHog],[clip])-see gradientHist.m
void mGradHist( int nl, mxArray *pl[], int nr, const mxArray *pr[] ) {
  int h, w, d, hb, wb, bin, nOrients; bool softBin, useHog;
  float *M, *O, *H, *G, clip;
  checkArgs(nl,pl,nr,pr,1,3,2,7,&h,&w,&d,mxSINGLE_CLASS,(void**)&M);
  O = (float*) mxGetPr(pr[1]);
  if( mxGetM(pr[1])!=h || mxGetN(pr[1])!=w || d!=1 ||
    mxGetClassID(pr[1])!=mxSINGLE_CLASS ) mexErrMsgTxt("M or O is bad.");
  bin      = (nr>=3) ? (int)   mxGetScalar(pr[2])    : 8;
  nOrients = (nr>=4) ? (int)   mxGetScalar(pr[3])    : 9;
  softBin  = (nr>=5) ? (bool) (mxGetScalar(pr[4])>0) : true;
  useHog   = (nr>=6) ? (bool) (mxGetScalar(pr[5])>0) : false;
  clip     = (nr>=7) ? (float) mxGetScalar(pr[6])    : 0.2f;
  hb=h/bin; wb=w/bin;
  if( useHog==false ) {
    pl[0] = mxCreateMatrix3(hb,wb,nOrients,mxSINGLE_CLASS,1,(void**)&H);
    gradHist( M, O, H, h, w, bin, nOrients, softBin );
  } else {
    pl[0] = mxCreateMatrix3(hb,wb,nOrients*4,mxSINGLE_CLASS,1,(void**)&G);
    H = (float*) mxCalloc(wb*hb*nOrients,sizeof(float));
    gradHist( M, O, H, h, w, bin, nOrients, softBin );
    hog( H, G, h, w, bin, nOrients, clip ); mxFree(H);
  }
}

// inteface to various gradient functions (see corresponding Matlab functions)
void mexFunction( int nl, mxArray *pl[], int nr, const mxArray *pr[] ) {
  int f; char action[1024]; f=mxGetString(pr[0],action,1024); nr--; pr++;
  if(f) mexErrMsgTxt("Failed to get action.");
  else if(!strcmp(action,"gradient2")) mGrad2(nl,pl,nr,pr);
  else if(!strcmp(action,"gradientMag")) mGradMag(nl,pl,nr,pr);
  else if(!strcmp(action,"gradientMagNorm")) mGradMagNorm(nl,pl,nr,pr);
  else if(!strcmp(action,"gradientHist")) mGradHist(nl,pl,nr,pr);
  else mexErrMsgTxt("Invalid action.");
}
#endif
