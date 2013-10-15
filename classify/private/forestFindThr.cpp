/*******************************************************************************
* Piotr's Image&Video Toolbox      Version 3.24
* Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <mex.h>

typedef unsigned int uint32;
#define gini(p) p*p
#define entropy(p) (-p*flog2(float(p)))

// fast approximate log2(x) from Paul Mineiro <paul@mineiro.com>
inline float flog2( float x ) {
  union { float f; uint32_t i; } vx = { x };
  union { uint32_t i; float f; } mx = { (vx.i & 0x007FFFFF) | 0x3f000000 };
  float y = float(vx.i); y *= 1.1920928955078125e-7f;
  return y - 124.22551499f - 1.498030302f * mx.f
    - 1.72587999f / (0.3520887068f + mx.f);
}

// perform actual computation
void forestFindThr( int H, int N, int F, const float *data,
  const uint32 *hs, const float *ws, const uint32 *order, const int split,
  uint32 &fid, float &thr, double &gain )
{
  double *Wl, *Wr, *W; float *data1; uint32 *order1;
  int i, j, j1, j2, h; double vBst, vInit, v, w, wl, wr, g, gl, gr;
  Wl=new double[H]; Wr=new double[H]; W=new double[H];
  // perform initialization
  vBst = vInit = 0; g = 0; w = 0; fid = 1; thr = 0;
  for( i=0; i<H; i++ ) W[i] = 0;
  for( j=0; j<N; j++ ) { w+=ws[j]; W[hs[j]-1]+=ws[j]; }
  if( split==0 ) { for( i=0; i<H; i++ ) g+=gini(W[i]); vBst=vInit=(1-g/w/w); }
  if( split==1 ) { for( i=0; i<H; i++ ) g+=entropy(W[i]); vBst=vInit=g/w; }
  // loop over features, then thresholds (data is sorted by feature value)
  for( i=0; i<F; i++ ) {
    order1=(uint32*) order+i*N; data1=(float*) data+i*size_t(N);
    for( j=0; j<H; j++ ) { Wl[j]=0; Wr[j]=W[j]; } gl=wl=0; gr=g; wr=w;
    for( j=0; j<N-1; j++ ) {
      j1=order1[j]; j2=order1[j+1]; h=hs[j1]-1;
      if(split==0) {
        // gini = 1-\sum_h p_h^2; v = gini_l*pl + gini_r*pr
        wl+=ws[j1]; gl-=gini(Wl[h]); Wl[h]+=ws[j1]; gl+=gini(Wl[h]);
        wr-=ws[j1]; gr-=gini(Wr[h]); Wr[h]-=ws[j1]; gr+=gini(Wr[h]);
        v = (wl-gl/wl)/w + (wr-gr/wr)/w;
      } else if (split==1) {
        // entropy = -\sum_h p_h log(p_h); v = entropy_l*pl + entropy_r*pr
        gl+=entropy(wl); wl+=ws[j1]; gl-=entropy(wl);
        gr+=entropy(wr); wr-=ws[j1]; gr-=entropy(wr);
        gl-=entropy(Wl[h]); Wl[h]+=ws[j1]; gl+=entropy(Wl[h]);
        gr-=entropy(Wr[h]); Wr[h]-=ws[j1]; gr+=entropy(Wr[h]);
        v = gl/w + gr/w;
      } else if (split==2) {
        // twoing: v = pl*pr*\sum_h(|p_h_left - p_h_right|)^2 [slow if H>>0]
        j1=order1[j]; j2=order1[j+1]; h=hs[j1]-1;
        wl+=ws[j1]; Wl[h]+=ws[j1]; wr-=ws[j1]; Wr[h]-=ws[j1];
        g=0; for( int h1=0; h1<H; h1++ ) g+=fabs(Wl[h1]/wl-Wr[h1]/wr);
        v = - wl/w*wr/w*g*g;
      }
      if( v<vBst && data1[j2]-data1[j1]>=1e-6f ) {
        vBst=v; fid=i+1; thr=0.5f*(data1[j1]+data1[j2]); }
    }
  }
  delete [] Wl; delete [] Wr; delete [] W; gain = vInit-vBst;
}

// [fid,thr,gain] = mexFunction(data,hs,ws,order,H,split);
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int H, N, F, split; float *data, *ws, thr;
  double gain; uint32 *hs, *order, fid;
  data = (float*) mxGetData(prhs[0]);
  hs = (uint32*) mxGetData(prhs[1]);
  ws = (float*) mxGetData(prhs[2]);
  order = (uint32*) mxGetData(prhs[3]);
  H = (int) mxGetScalar(prhs[4]);
  split = (int) mxGetScalar(prhs[5]);
  N = (int) mxGetM(prhs[0]);
  F = (int) mxGetN(prhs[0]);
  forestFindThr(H,N,F,data,hs,ws,order,split,fid,thr,gain);
  plhs[0] = mxCreateDoubleScalar(fid);
  plhs[1] = mxCreateDoubleScalar(thr);
  plhs[2] = mxCreateDoubleScalar(gain);
}
