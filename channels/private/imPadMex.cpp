/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 3.00
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "wrappers.hpp"
#include "string.h"
typedef unsigned char uchar;

// pad A by [pt,pb,pl,pr] and store result in B
template<class T> void imPad( T *A, T *B, int h, int w, int d, int pt, int pb,
  int pl, int pr, int flag, T val )
{
  int h1=h+pt, hb=h1+pb, w1=w+pl, wb=w1+pr, x, y, z, mPad;
  int ct=0, cb=0, cl=0, cr=0;
  if(pt<0) { ct=-pt; pt=0; } if(pb<0) { h1+=pb; cb=-pb; pb=0; }
  if(pl<0) { cl=-pl; pl=0; } if(pr<0) { w1+=pr; cr=-pr; pr=0; }
  int *xs, *ys; x=pr>pl?pr:pl; y=pt>pb?pt:pb; mPad=x>y?x:y;
  bool useLookup = ((flag==2 || flag==3) && (mPad>h || mPad>w))
    || (flag==3 && (ct || cb || cl || cr ));
  // helper macro for padding
  #define PAD(XL,XM,XR,YT,YM,YB) \
  for(x=0;  x<pl; x++) for(y=0;  y<pt; y++) B[x*hb+y]=A[(XL+cl)*h+YT+ct]; \
  for(x=0;  x<pl; x++) for(y=pt; y<h1; y++) B[x*hb+y]=A[(XL+cl)*h+YM+ct]; \
  for(x=0;  x<pl; x++) for(y=h1; y<hb; y++) B[x*hb+y]=A[(XL+cl)*h+YB-cb]; \
  for(x=pl; x<w1; x++) for(y=0;  y<pt; y++) B[x*hb+y]=A[(XM+cl)*h+YT+ct]; \
  for(x=pl; x<w1; x++) for(y=h1; y<hb; y++) B[x*hb+y]=A[(XM+cl)*h+YB-cb]; \
  for(x=w1; x<wb; x++) for(y=0;  y<pt; y++) B[x*hb+y]=A[(XR-cr)*h+YT+ct]; \
  for(x=w1; x<wb; x++) for(y=pt; y<h1; y++) B[x*hb+y]=A[(XR-cr)*h+YM+ct]; \
  for(x=w1; x<wb; x++) for(y=h1; y<hb; y++) B[x*hb+y]=A[(XR-cr)*h+YB-cb];
  // build lookup table for xs and ys if necessary
  if( useLookup ) {
    xs = (int*) wrMalloc(wb*sizeof(int)); int h2=(pt+1)*2*h;
    ys = (int*) wrMalloc(hb*sizeof(int)); int w2=(pl+1)*2*w;
    if( flag==2 ) {
      for(x=0; x<wb; x++) { z=(x-pl+w2)%(w*2); xs[x]=z<w ? z : w*2-z-1; }
      for(y=0; y<hb; y++) { z=(y-pt+h2)%(h*2); ys[y]=z<h ? z : h*2-z-1; }
    } else if( flag==3 ) {
      for(x=0; x<wb; x++) xs[x]=(x-pl+w2)%w;
      for(y=0; y<hb; y++) ys[y]=(y-pt+h2)%h;
    }
  }
  // pad by appropriate value
  for( z=0; z<d; z++ ) {
    // copy over A to relevant region in B
    for( x=0; x<w-cr-cl; x++ )
      memcpy(B+(x+pl)*hb+pt,A+(x+cl)*h+ct,sizeof(T)*(h-ct-cb));
    // set boundaries of B to appropriate values
    if( flag==0 && val!=0 ) { // "constant"
      for(x=0;  x<pl; x++) for(y=0;  y<hb; y++) B[x*hb+y]=val;
      for(x=pl; x<w1; x++) for(y=0;  y<pt; y++) B[x*hb+y]=val;
      for(x=pl; x<w1; x++) for(y=h1; y<hb; y++) B[x*hb+y]=val;
      for(x=w1; x<wb; x++) for(y=0;  y<hb; y++) B[x*hb+y]=val;
    } else if( useLookup ) { // "lookup"
      PAD( xs[x], xs[x], xs[x], ys[y], ys[y], ys[y] );
    } else if( flag==1 ) {  // "replicate"
      PAD( 0, x-pl, w-1, 0, y-pt, h-1 );
    } else if( flag==2 ) { // "symmetric"
      PAD( pl-x-1, x-pl, w+w1-1-x, pt-y-1, y-pt, h+h1-1-y );
    } else if( flag==3 ) { // "circular"
      PAD( x-pl+w, x-pl, x-pl-w, y-pt+h, y-pt, y-pt-h );
    }
    A += h*w;  B += hb*wb;
  }
  if( useLookup ) { wrFree(xs); wrFree(ys); }
  #undef PAD
}

// B = imPadMex(A,pad,type); see imPad.m for usage details
#ifdef MATLAB_MEX_FILE
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int *ns, ms[3], nCh, nDims, pt, pb, pl, pr, flag, k; double *p;
  void *A, *B; mxClassID id; double val=0; char type[1024];

  // Error checking on arguments
  if( nrhs!=3 ) mexErrMsgTxt("Three inputs expected.");
  if( nlhs>1 ) mexErrMsgTxt("One output expected.");
  nDims=mxGetNumberOfDimensions(prhs[0]); id=mxGetClassID(prhs[0]);
  ns = (int*) mxGetDimensions(prhs[0]); nCh=(nDims==2) ? 1 : ns[2];
  if( (nDims!=2 && nDims!=3) ||
    (id!=mxSINGLE_CLASS && id!=mxDOUBLE_CLASS && id!=mxUINT8_CLASS) )
    mexErrMsgTxt("A should be 2D or 3D single, double or uint8 array.");
  if( !mxIsDouble(prhs[1]) ) mexErrMsgTxt("Input pad must be a double array.");

  // extract padding amounts
  k = (int) mxGetNumberOfElements(prhs[1]);
  p = (double*) mxGetData(prhs[1]);
  if(k==1) { pt=pb=pl=pr=int(p[0]); }
  else if (k==2) { pt=pb=int(p[0]); pl=pr=int(p[1]); }
  else if (k==4) { pt=int(p[0]); pb=int(p[1]); pl=int(p[2]); pr=int(p[3]); }
  else mexErrMsgTxt( "Input pad must have 1, 2, or 4 values.");

  // figure out padding type (flag and val)
  if( !mxGetString(prhs[2],type,1024) ) {
    if(!strcmp(type,"replicate")) flag=1;
    else if(!strcmp(type,"symmetric")) flag=2;
    else if(!strcmp(type,"circular")) flag=3;
    else mexErrMsgTxt("Invalid pad value.");
  } else {
    flag=0; val=(double)mxGetScalar(prhs[2]);
  }
  if( ns[0]==0 || ns[1]==0 ) flag=0;

  // create output array
  ms[0]=ns[0]+pt+pb; ms[1]=ns[1]+pl+pr; ms[2]=nCh;
  if( ms[0]<0 || ns[0]<=-pt || ns[0]<=-pb ) ms[0]=0;
  if( ms[1]<0 || ns[1]<=-pl || ns[1]<=-pr ) ms[1]=0;
  plhs[0] = mxCreateNumericArray(3, (const mwSize*) ms, id, mxREAL);
  if( ms[0]==0 || ms[1]==0 ) return;

  // pad array
  A=mxGetData(prhs[0]); B=mxGetData(plhs[0]);
  if( id==mxDOUBLE_CLASS ) {
    imPad( (double*)A,(double*)B,ns[0],ns[1],nCh,pt,pb,pl,pr,flag,val );
  } else if( id==mxSINGLE_CLASS ) {
    imPad( (float*)A,(float*)B,ns[0],ns[1],nCh,pt,pb,pl,pr,flag,float(val) );
  } else if( id==mxUINT8_CLASS ) {
    imPad( (uchar*)A,(uchar*)B,ns[0],ns[1],nCh,pt,pb,pl,pr,flag,uchar(val) );
  } else {
    mexErrMsgTxt("Unsupported image type.");
  }
}
#endif
