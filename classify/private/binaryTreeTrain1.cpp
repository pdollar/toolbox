/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 3.24
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include <mex.h>
#ifdef USEOMP
#include <omp.h>
#endif

typedef unsigned char uint8;
typedef unsigned int uint32;
#define min(x,y) ((x) < (y) ? (x) : (y))

// construct cdf given data vector and wts
void constructCdf( uint8* data, float *wts, int nBins,
                  int N, int M, uint32 *ord, float *cdf )
{
  int i; for( i=0; i<nBins; i++) cdf[i]=0;
  if(M) for( i=0; i<M; i++) cdf[data[ord[i]]] += wts[i];
  else for( i=0; i<N; i++) cdf[data[i]] += wts[i];
  for(i=1; i<nBins; i++) cdf[i]+=cdf[i-1];
}

// [errs,thrs] = mexFunction( data0, data1, wts0, wts1,
//  nBins, prior, fids, nThreads, [ord0], [ord1] )
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // get inputs
  int nBins, nThreads, N0, N1, M0, M1, F; float prior, *wts0, *wts1;
  uint8 *data0, *data1; uint32 *fids, *ord0, *ord1;
  data0 = (uint8*) mxGetData(prhs[0]);
  data1 = (uint8*) mxGetData(prhs[1]);
  wts0 = (float*) mxGetData(prhs[2]);
  wts1 = (float*) mxGetData(prhs[3]);
  nBins = (int) mxGetScalar(prhs[4]);
  prior = (float) mxGetScalar(prhs[5]);
  fids = (uint32*) mxGetData(prhs[6]);
  nThreads = (int) mxGetScalar(prhs[7]);
  N0 = (int) mxGetM(prhs[0]);
  N1 = (int) mxGetM(prhs[1]);
  F = (int) mxGetNumberOfElements(prhs[6]);

  // ord0 and ord1 are optional
  if( nrhs<10 ) M0=M1=0; else {
    ord0 = (uint32*) mxGetData(prhs[8]);
    ord1 = (uint32*) mxGetData(prhs[9]);
    M0 = (int) mxGetNumberOfElements(prhs[8]);
    M1 = (int) mxGetNumberOfElements(prhs[9]);
  }

  // create outpu structure
  plhs[0] = mxCreateNumericMatrix(1,F,mxSINGLE_CLASS,mxREAL);
  plhs[1] = mxCreateNumericMatrix(1,F,mxUINT8_CLASS,mxREAL);
  float *errs = (float*) mxGetData(plhs[0]);
  uint8 *thrs = (uint8*) mxGetData(plhs[1]);

  // find lowest error for each feature
  #ifdef USEOMP
  nThreads = min(nThreads,omp_get_max_threads());
  #pragma omp parallel for num_threads(nThreads)
  #endif
  for( int f=0; f<F; f++ ) {
    float cdf0[256], cdf1[256], e0=1, e1=0, e; int thr;
    constructCdf(data0+N0*size_t(fids[f]),wts0,nBins,N0,M0,ord0,cdf0);
    constructCdf(data1+N1*size_t(fids[f]),wts1,nBins,N1,M1,ord1,cdf1);
    for( int i=0; i<nBins; i++) {
      e = prior - cdf1[i] + cdf0[i];
      if(e<e0) { e0=e; e1=1-e; thr=i; } else if(e>e1) { e0=1-e; e1=e; thr=i; }
    }
    errs[f]=e0; thrs[f]=(uint8) thr;
  }
}
