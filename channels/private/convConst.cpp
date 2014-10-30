/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 3.24
* Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "wrappers.hpp"
#include <string.h>
#include "sse.hpp"

// convolve one column of I by a 2rx1 ones filter
void convBoxY( float *I, float *O, int h, int r, int s ) {
  float t; int j, p=r+1, q=2*h-(r+1), h0=r+1, h1=h-r, h2=h;
  t=0; for(j=0; j<=r; j++) t+=I[j]; t=2*t-I[r]; j=0;
  if( s==1 ) {
    for(; j<h0; j++) O[j]=t-=I[r-j]-I[r+j];
    for(; j<h1; j++) O[j]=t-=I[j-p]-I[r+j];
    for(; j<h2; j++) O[j]=t-=I[j-p]-I[q-j];
  } else {
    int k=(s-1)/2; h2=(h/s)*s; if(h0>h2) h0=h2; if(h1>h2) h1=h2;
    for(; j<h0; j++) { t-=I[r-j]-I[r+j]; k++; if(k==s) { k=0; *O++=t; } }
    for(; j<h1; j++) { t-=I[j-p]-I[r+j]; k++; if(k==s) { k=0; *O++=t; } }
    for(; j<h2; j++) { t-=I[j-p]-I[q-j]; k++; if(k==s) { k=0; *O++=t; } }
  }
}

// convolve I by a 2r+1 x 2r+1 ones filter (uses SSE)
void convBox( float *I, float *O, int h, int w, int d, int r, int s ) {
  float nrm = 1.0f/((2*r+1)*(2*r+1)); int i, j, k=(s-1)/2, h0, h1, w0;
  if(h%4==0) h0=h1=h; else { h0=h-(h%4); h1=h0+4; } w0=(w/s)*s;
  float *T=(float*) alMalloc(h1*sizeof(float),16);
  while(d-- > 0) {
    // initialize T
    memset( T, 0, h1*sizeof(float) );
    for(i=0; i<=r; i++) for(j=0; j<h0; j+=4) INC(T[j],LDu(I[j+i*h]));
    for(j=0; j<h0; j+=4) STR(T[j],MUL(nrm,SUB(MUL(2,LD(T[j])),LDu(I[j+r*h]))));
    for(i=0; i<=r; i++) for(j=h0; j<h; j++ ) T[j]+=I[j+i*h];
    for(j=h0; j<h; j++ ) T[j]=nrm*(2*T[j]-I[j+r*h]);
    // prepare and convolve each column in turn
    k++; if(k==s) { k=0; convBoxY(T,O,h,r,s); O+=h/s; }
    for( i=1; i<w0; i++ ) {
      float *Il=I+(i-1-r)*h; if(i<=r) Il=I+(r-i)*h;
      float *Ir=I+(i+r)*h; if(i>=w-r) Ir=I+(2*w-r-i-1)*h;
      for(j=0; j<h0; j+=4) DEC(T[j],MUL(nrm,SUB(LDu(Il[j]),LDu(Ir[j]))));
      for(j=h0; j<h; j++ ) T[j]-=nrm*(Il[j]-Ir[j]);
      k++; if(k==s) { k=0; convBoxY(T,O,h,r,s); O+=h/s; }
    }
    I+=w*h;
  }
  alFree(T);
}

// convolve one column of I by a [1; 1] filter (uses SSE)
void conv11Y( float *I, float *O, int h, int side, int s ) {
  #define C4(m,o) ADD(LDu(I[m*j-1+o]),LDu(I[m*j+o]))
  int j=0, k=((~((size_t) O) + 1) & 15)/4;
  const int d = (side % 4 >= 2) ? 1 : 0, h2=(h-d)/2;
  if( s==2 ) {
    for( ; j<k; j++ ) O[j]=I[2*j+d]+I[2*j+d+1];
    for( ; j<h2-4; j+=4 ) STR(O[j],_mm_shuffle_ps(C4(2,d+1),C4(2,d+5),136));
    for( ; j<h2; j++ ) O[j]=I[2*j+d]+I[2*j+d+1];
    if(d==1 && h%2==0) O[j]=2*I[2*j+d];
  } else {
    if(d==0) { O[0]=2*I[0]; j++; if(k==0) k=4; }
    for( ; j<k; j++ ) O[j]=I[j-1+d]+I[j+d];
    for( ; j<h-4-d; j+=4 ) STR(O[j],C4(1,d) );
    for( ; j<h-d; j++ ) O[j]=I[j-1+d]+I[j+d];
    if(d==1) { O[j]=2*I[j]; j++; }
  }
  #undef C4
}

// convolve I by a [1 1; 1 1] filter (uses SSE)
void conv11( float *I, float *O, int h, int w, int d, int side, int s ) {
  const float nrm = 0.25f; int i, j;
  float *I0, *I1, *T = (float*) alMalloc(h*sizeof(float),16);
  for( int d0=0; d0<d; d0++ ) for( i=s/2; i<w; i+=s ) {
    I0=I1=I+i*h+d0*h*w; if(side%2) { if(i<w-1) I1+=h; } else { if(i) I0-=h; }
    for( j=0; j<h-4; j+=4 ) STR( T[j], MUL(nrm,ADD(LDu(I0[j]),LDu(I1[j]))) );
    for( ; j<h; j++ ) T[j]=nrm*(I0[j]+I1[j]);
    conv11Y(T,O,h,side,s); O+=h/s;
  }
  alFree(T);
}

// convolve one column of I by a 2rx1 triangle filter
void convTriY( float *I, float *O, int h, int r, int s ) {
  r++; float t, u; int j, r0=r-1, r1=r+1, r2=2*h-r, h0=r+1, h1=h-r+1, h2=h;
  u=t=I[0]; for( j=1; j<r; j++ ) u+=t+=I[j]; u=2*u-t; t=0;
  if( s==1 ) {
    O[0]=u; j=1;
    for(; j<h0; j++) O[j] = u += t += I[r-j]  + I[r0+j] - 2*I[j-1];
    for(; j<h1; j++) O[j] = u += t += I[j-r1] + I[r0+j] - 2*I[j-1];
    for(; j<h2; j++) O[j] = u += t += I[j-r1] + I[r2-j] - 2*I[j-1];
  } else {
    int k=(s-1)/2; h2=(h/s)*s; if(h0>h2) h0=h2; if(h1>h2) h1=h2;
    if(++k==s) { k=0; *O++=u; } j=1;
    for(;j<h0;j++) { u+=t+=I[r-j] +I[r0+j]-2*I[j-1]; if(++k==s){ k=0; *O++=u; }}
    for(;j<h1;j++) { u+=t+=I[j-r1]+I[r0+j]-2*I[j-1]; if(++k==s){ k=0; *O++=u; }}
    for(;j<h2;j++) { u+=t+=I[j-r1]+I[r2-j]-2*I[j-1]; if(++k==s){ k=0; *O++=u; }}
  }
}

// convolve I by a 2rx1 triangle filter (uses SSE)
void convTri( float *I, float *O, int h, int w, int d, int r, int s ) {
  r++; float nrm = 1.0f/(r*r*r*r); int i, j, k=(s-1)/2, h0, h1, w0;
  if(h%4==0) h0=h1=h; else { h0=h-(h%4); h1=h0+4; } w0=(w/s)*s;
  float *T=(float*) alMalloc(2*h1*sizeof(float),16), *U=T+h1;
  while(d-- > 0) {
    // initialize T and U
    for(j=0; j<h0; j+=4) STR(U[j], STR(T[j], LDu(I[j])));
    for(i=1; i<r; i++) for(j=0; j<h0; j+=4) INC(U[j],INC(T[j],LDu(I[j+i*h])));
    for(j=0; j<h0; j+=4) STR(U[j],MUL(nrm,(SUB(MUL(2,LD(U[j])),LD(T[j])))));
    for(j=0; j<h0; j+=4) STR(T[j],0);
    for(j=h0; j<h; j++ ) U[j]=T[j]=I[j];
    for(i=1; i<r; i++) for(j=h0; j<h; j++ ) U[j]+=T[j]+=I[j+i*h];
    for(j=h0; j<h; j++ ) { U[j] = nrm * (2*U[j]-T[j]); T[j]=0; }
    // prepare and convolve each column in turn
    k++; if(k==s) { k=0; convTriY(U,O,h,r-1,s); O+=h/s; }
    for( i=1; i<w0; i++ ) {
      float *Il=I+(i-1-r)*h; if(i<=r) Il=I+(r-i)*h; float *Im=I+(i-1)*h;
      float *Ir=I+(i-1+r)*h; if(i>w-r) Ir=I+(2*w-r-i)*h;
      for( j=0; j<h0; j+=4 ) {
        INC(T[j],ADD(LDu(Il[j]),LDu(Ir[j]),MUL(-2,LDu(Im[j]))));
        INC(U[j],MUL(nrm,LD(T[j])));
      }
      for( j=h0; j<h; j++ ) U[j]+=nrm*(T[j]+=Il[j]+Ir[j]-2*Im[j]);
      k++; if(k==s) { k=0; convTriY(U,O,h,r-1,s); O+=h/s; }
    }
    I+=w*h;
  }
  alFree(T);
}

// convolve one column of I by a [1 p 1] filter (uses SSE)
void convTri1Y( float *I, float *O, int h, float p, int s ) {
  #define C4(m,o) ADD(ADD(LDu(I[m*j-1+o]),MUL(p,LDu(I[m*j+o]))),LDu(I[m*j+1+o]))
  int j=0, k=((~((size_t) O) + 1) & 15)/4, h2=(h-1)/2;
  if( s==2 ) {
    for( ; j<k; j++ ) O[j]=I[2*j]+p*I[2*j+1]+I[2*j+2];
    for( ; j<h2-4; j+=4 ) STR(O[j],_mm_shuffle_ps(C4(2,1),C4(2,5),136));
    for( ; j<h2; j++ ) O[j]=I[2*j]+p*I[2*j+1]+I[2*j+2];
    if( h%2==0 ) O[j]=I[2*j]+(1+p)*I[2*j+1];
  } else {
    O[j]=(1+p)*I[j]+I[j+1]; j++; if(k==0) k=(h<=4) ? h-1 : 4;
    for( ; j<k; j++ ) O[j]=I[j-1]+p*I[j]+I[j+1];
    for( ; j<h-4; j+=4 ) STR(O[j],C4(1,0));
    for( ; j<h-1; j++ ) O[j]=I[j-1]+p*I[j]+I[j+1];
    O[j]=I[j-1]+(1+p)*I[j];
  }
  #undef C4
}

// convolve I by a [1 p 1] filter (uses SSE)
void convTri1( float *I, float *O, int h, int w, int d, float p, int s ) {
  const float nrm = 1.0f/((p+2)*(p+2)); int i, j, h0=h-(h%4);
  float *Il, *Im, *Ir, *T=(float*) alMalloc(h*sizeof(float),16);
  for( int d0=0; d0<d; d0++ ) for( i=s/2; i<w; i+=s ) {
    Il=Im=Ir=I+i*h+d0*h*w; if(i>0) Il-=h; if(i<w-1) Ir+=h;
    for( j=0; j<h0; j+=4 )
      STR(T[j],MUL(nrm,ADD(ADD(LDu(Il[j]),MUL(p,LDu(Im[j]))),LDu(Ir[j]))));
    for( j=h0; j<h; j++ ) T[j]=nrm*(Il[j]+p*Im[j]+Ir[j]);
    convTri1Y(T,O,h,p,s); O+=h/s;
  }
  alFree(T);
}

// convolve one column of I by a 2rx1 max filter
void convMaxY( float *I, float *O, float *T, int h, int r ) {
  int y, y0, y1, yi, m=2*r+1;
  #define max1(a,b) a>b ? a : b;
  #define maxk(y0,y1) { O[y]=I[y0]; \
    for( yi=y0+1; yi<=y1; yi++ ) { if(I[yi]>O[y]) O[y]=I[yi]; }}
  for( y=0; y<r; y++ ) { y1=y+r; if(y1>h-1) y1=h-1; maxk(0,y1); }
  for( ; y<=h-m-r; y+=m ) {
    T[m-1] = I[y+r];
    for( yi=1; yi<m; yi++ ) T[m-1-yi] = max1( T[m-1-yi+1], I[y+r-yi] );
    for( yi=1; yi<m; yi++ ) T[m-1+yi] = max1( T[m-1+yi-1], I[y+r+yi] );
    for( yi=0; yi<m; yi++ ) O[y+yi] = max1( T[yi], T[yi+m-1] );
  }
  for( ; y<h-r; y++ ) { maxk(y-r,y+r); }
  for( ; y<h; y++ ) { y0=y-r; if(y0<0) y0=0; maxk(y0,h-1); }
  #undef maxk
  #undef max1
}

// convolve I by a 2rx1 max filter
void convMax( float *I, float *O, int h, int w, int d, int r ) {
  if( r>w-1 ) r=w-1; if( r>h-1 ) r=h-1; int m=2*r+1;
  float *T=(float*) alMalloc(m*2*sizeof(float),16);
  for( int d0=0; d0<d; d0++ ) for( int x=0; x<w; x++ ) {
    float *Oc=O+d0*h*w+h*x, *Ic=I+d0*h*w+h*x;
    convMaxY(Ic,Oc,T,h,r);
  }
  alFree(T);
}

// B=convConst(type,A,r,s); fast 2D convolutions (see convTri.m and convBox.m)
#ifdef MATLAB_MEX_FILE
void mexFunction( int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[] ) {
  int *ns, ms[3], nDims, d, m, r, s; float *A, *B, p;
  mxClassID id; char type[1024];

  // error checking on arguments
  if(nrhs!=4) mexErrMsgTxt("Four inputs required.");
  if(nlhs > 1) mexErrMsgTxt("One output expected.");
  nDims = mxGetNumberOfDimensions(prhs[1]);
  id = mxGetClassID(prhs[1]);
  ns = (int*) mxGetDimensions(prhs[1]);
  d = (nDims == 3) ? ns[2] : 1;
  m = (ns[0] < ns[1]) ? ns[0] : ns[1];
  if( (nDims!=2 && nDims!=3) || id!=mxSINGLE_CLASS || m<4 )
    mexErrMsgTxt("A must be a 4x4 or bigger 2D or 3D float array.");

  // extract inputs
  if(mxGetString(prhs[0],type,1024))
    mexErrMsgTxt("Failed to get type.");
  A = (float*) mxGetData(prhs[1]);
  p = (float) mxGetScalar(prhs[2]);
  r = (int) mxGetScalar(prhs[2]);
  s = (int) mxGetScalar(prhs[3]);
  if( s<1 ) mexErrMsgTxt("Invalid sampling value s");
  if( r<0 ) mexErrMsgTxt("Invalid radius r");

  // create output array (w/o initializing to 0)
  ms[0]=ns[0]/s; ms[1]=ns[1]/s; ms[2]=d;
  B = (float*) mxMalloc(ms[0]*ms[1]*d*sizeof(float));
  plhs[0] = mxCreateNumericMatrix(0, 0, mxSINGLE_CLASS, mxREAL);
  mxSetData(plhs[0], B); mxSetDimensions(plhs[0],(mwSize*)ms,nDims);

  // perform appropriate type of convolution
  if(!strcmp(type,"convBox")) {
    if(r>=m/2) mexErrMsgTxt("mask larger than image (r too large)");
    convBox( A, B, ns[0], ns[1], d, r, s );
  } else if(!strcmp(type,"convTri")) {
    if(r>=m/2) mexErrMsgTxt("mask larger than image (r too large)");
    convTri( A, B, ns[0], ns[1], d, r, s );
  } else if(!strcmp(type,"conv11")) {
    if( s>2 ) mexErrMsgTxt("conv11 can sample by at most s=2");
    conv11( A, B, ns[0], ns[1], d, r, s );
  } else if(!strcmp(type,"convTri1")) {
    if( s>2 ) mexErrMsgTxt("convTri1 can sample by at most s=2");
    convTri1( A, B, ns[0], ns[1], d, p, s );
  } else if(!strcmp(type,"convMax")) {
    if( s>1 ) mexErrMsgTxt("convMax cannot sample");
    convMax( A, B, ns[0], ns[1], d, r );
  } else {
    mexErrMsgTxt("Invalid type.");
  }
}
#endif
