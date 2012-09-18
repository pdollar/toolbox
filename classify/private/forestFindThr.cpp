/*******************************************************************************
* Piotr's Image&Video Toolbox      Version 3.01
* Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include <string.h>
#include <mex.h>
typedef unsigned int uint32;

void rtreeFindThr( int H, int N, int F, const float *data, const uint32 *hs,
  const float *ws, const uint32 *order, uint32 &fid, float &thr, double &gini )
{
  int i, j, h; double *L, *R, *T; float *data1; uint32 *order1;
  double gini1, s=0, sl, sr, g=0, gl, gr;
  L=new double[H]; R=new double[H]; T=new double[H];
  for( i=0; i<H; i++ ) T[i] = 0;
  for( j=0; j<N; j++ ) { s+=ws[j]; T[hs[j]-1]+=ws[j]; }
  for( i=0; i<H; i++ ) g+=T[i]*T[i];
  fid = 1; thr = 0; gini = 1e5;
  for( i=0; i<F; i++ ) {
    order1=(uint32*) order+i*N; data1=(float*) data+i*N;
    for( j=0; j<H; j++ ) { L[j]=0; R[j]=T[j]; } gl=sl=0; gr=g;
    for( j=0; j<N-1; j++ ) {
      int j1=order1[j], j2=order1[j+1]; h=hs[j1]-1; sl+=ws[j1]; sr=s-sl;
      gl-=L[h]*L[h]; L[h]+=ws[j1]; gl+=L[h]*L[h];
      gr-=R[h]*R[h]; R[h]-=ws[j1]; gr+=R[h]*R[h];
      if( data1[j2]-data1[j1]<1e-6f ) continue;
      gini1 = (sl-gl/sl)/s + (sr-gr/sr)/s; // + (sl*sl+sr*sr)/(s*s*100);
      if(gini1<gini) { gini=gini1; fid=i+1; thr=0.5f*(data1[j1]+data1[j2]); }
    }
  }
  delete [] L; delete [] R; delete [] T;
}

// [fid,thr,gini] = rtreeFindThr(data,hs,ws,order,H);
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int H, N, F; float *data, *ws, thr; double gini; uint32 *hs, *order, fid;
  data = (float*) mxGetData(prhs[0]);
  hs = (uint32*) mxGetData(prhs[1]);
  ws = (float*) mxGetData(prhs[2]);
  order = (uint32*) mxGetData(prhs[3]);
  H = (int) mxGetScalar(prhs[4]);
  N = (int) mxGetM(prhs[0]);
  F = (int) mxGetN(prhs[0]);
  rtreeFindThr(H,N,F,data,hs,ws,order,fid,thr,gini);
  plhs[0] = mxCreateDoubleScalar(fid);
  plhs[1] = mxCreateDoubleScalar(thr);
  plhs[2] = mxCreateDoubleScalar(gini);
}
