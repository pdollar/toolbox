/*******************************************************************************
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include <string.h>
#include <mex.h>
typedef unsigned int uint32;

inline double gini( double p ) { return p*p; }

void forestFindThr( int H, int N, int F, const float *data,
  const uint32 *hs, const float *ws, const uint32 *order,
  uint32 &fid, float &thr, double &impurity )
{
  int i, j, j1, j2, h; double *Wl, *Wr, *W; float *data1; uint32 *order1;
  double impurity1, w=0, wl, wr, g=0, gl, gr;
  Wl=new double[H]; Wr=new double[H]; W=new double[H];
  for( i=0; i<H; i++ ) W[i] = 0;
  for( j=0; j<N; j++ ) { w+=ws[j]; W[hs[j]-1]+=ws[j]; }
  for( i=0; i<H; i++ ) g += gini(W[i]);
  fid = 1; thr = 0; impurity = 1e5;
  for( i=0; i<F; i++ ) {
    order1=(uint32*) order+i*N; data1=(float*) data+i*size_t(N);
    for( j=0; j<H; j++ ) { Wl[j]=0; Wr[j]=W[j]; } gl=wl=0; gr=g; wr=w;
    for( j=0; j<N-1; j++ ) {
      // gini=1-\sum_h p_h^2; impurity=ginil*wl/w+ginir*wr/w
      j1=order1[j]; j2=order1[j+1]; h=hs[j1]-1;
      wl+=ws[j1]; gl-=gini(Wl[h]); Wl[h]+=ws[j1]; gl+=gini(Wl[h]);
      wr-=ws[j1]; gr-=gini(Wr[h]); Wr[h]-=ws[j1]; gr+=gini(Wr[h]);
      impurity1 = (wl-gl/wl)/w + (wr-gr/wr)/w;
      if( impurity1<impurity && data1[j2]-data1[j1]>=1e-6f ) {
        impurity=impurity1; fid=i+1; thr=0.5f*(data1[j1]+data1[j2]); }
    }
  }
  delete [] Wl; delete [] Wr; delete [] W;
}

// [fid,thr,impurity] = mexFunction(data,hs,ws,order,H);
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int H, N, F; float *data, *ws, thr;
  double impurity; uint32 *hs, *order, fid;
  data = (float*) mxGetData(prhs[0]);
  hs = (uint32*) mxGetData(prhs[1]);
  ws = (float*) mxGetData(prhs[2]);
  order = (uint32*) mxGetData(prhs[3]);
  H = (int) mxGetScalar(prhs[4]);
  N = (int) mxGetM(prhs[0]);
  F = (int) mxGetN(prhs[0]);
  forestFindThr(H,N,F,data,hs,ws,order,fid,thr,impurity);
  plhs[0] = mxCreateDoubleScalar(fid);
  plhs[1] = mxCreateDoubleScalar(thr);
  plhs[2] = mxCreateDoubleScalar(impurity);
}
