/*******************************************************************************
* Piotr's Image&Video Toolbox      Version 3.01
* Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "string.h"
#include "mex.h"
#include "../../channels/private/sse.hpp"

// run nIter iterations of Horn & Schunk optical flow (alters Vx, Vy)
void opticalFlowHsMex( float *Vx, float *Vy, const float *Ex, const float *Ey,
  const float *Et, const float *Z, const int h, const int w, const int nIter )
{
  int x, y, x1, i, t, s; float my, mx, m, *Vx0, *Vy0;
  s=w*h*sizeof(float); Vx0=new float[s]; Vy0=new float[s];
  for( t=0; t<nIter; t++ ) {
    memcpy(Vx0,Vx,s); memcpy(Vy0,Vy,s);
    for( x=1; x<w-1; x++ ) {
      // do as much work as possible in SSE (assume non-aligned memory)
      for( y=1; y<h-4; y+=4 ) {
        x1=x*h; i=x1+y; __m128 _mx, _my, _m;
        _my=MUL(ADD(LDu(Vy0[x1-h+y]),LDu(Vy0[x1+h+y]),
          LDu(Vy0[x1+y-1]),LDu(Vy0[x1+y+1])),.25f);
        _mx=MUL(ADD(LDu(Vx0[x1-h+y]),LDu(Vx0[x1+h+y]),
          LDu(Vx0[x1+y-1]),LDu(Vx0[x1+y+1])),.25f);
        _m=MUL(ADD(MUL(LDu(Ey[i]),_my),MUL(LDu(Ex[i]),_mx),
          LDu(Et[i])),LDu(Z[i]));
        STRu(Vx[i],SUB(_mx,MUL(LDu(Ex[i]),_m)));
        STRu(Vy[i],SUB(_my,MUL(LDu(Ey[i]),_m)));
      }
      // do remainder of work in regular loop
      for( ; y<h-1; y++ ) {
        x1=x*h; i=x1+y;
        mx=.25f*(Vx0[x1-h+y]+Vx0[x1+h+y]+Vx0[x1+y-1]+Vx0[x1+y+1]);
        my=.25f*(Vy0[x1-h+y]+Vy0[x1+h+y]+Vy0[x1+y-1]+Vy0[x1+y+1]);
        m = (Ex[i]*mx + Ey[i]*my + Et[i])*Z[i];
        Vx[i]=mx-Ex[i]*m; Vy[i]=my-Ey[i]*m;
      }
    }
  }
  delete [] Vx0; delete [] Vy0;
}

// [Vx,Vy]=opticalFlowHsMex(Ex,Ey,Et,Z,nIter); - helper for opticalFlow
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  size_t h, w, nIter; float *Is[4], *Vx, *Vy;

  // Error checking on arguments
  if( nrhs!=5 ) mexErrMsgTxt("Five inputs expected.");
  if( nlhs!=2 ) mexErrMsgTxt("Two outputs expected.");
  h = mxGetM(prhs[0]); w = mxGetN(prhs[0]);
  for( int i=0; i<4; i++ ) {
    if(mxGetM(prhs[i])!=h || mxGetN(prhs[i])!=w) mexErrMsgTxt("Invalid dims.");
    if(mxGetClassID(prhs[i])!=mxSINGLE_CLASS) mexErrMsgTxt("Invalid type.");
    Is[i] = (float*) mxGetData(prhs[i]);
  }
  nIter = (int) mxGetScalar(prhs[4]);

  // create output matricies
  plhs[0] = mxCreateNumericMatrix(int(h),int(w),mxSINGLE_CLASS,mxREAL);
  plhs[1] = mxCreateNumericMatrix(int(h),int(w),mxSINGLE_CLASS,mxREAL);
  Vx = (float*) mxGetData(plhs[0]);
  Vy = (float*) mxGetData(plhs[1]);

  // run optical flow
  opticalFlowHsMex(Vx,Vy,Is[0],Is[1],Is[2],Is[3],int(h),int(w),nIter);
}
