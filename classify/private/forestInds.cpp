/*******************************************************************************
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include <mex.h>
#include <omp.h>

typedef unsigned int uint32;
#define min(x,y) ((x) < (y) ? (x) : (y))

void forestInds( uint32 *inds, const float *data, const float *thrs,
  const uint32 *fids, const uint32 *child, int N, int nThreads )
{
  #pragma omp parallel for num_threads(nThreads)
  for( int i = 0; i < N; i++ ) {
    uint32 k = 0;
    while( child[k] )
      if( data[i+fids[k]*N] < thrs[k] )
        k = child[k]-1; else k = child[k];
    inds[i] = k+1;
  }
}

// inds=mexFunction(data,thrs,fids,child,[nThreads])
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int N, nThreads; float *data, *thrs; uint32 *inds, *fids, *child;
  data = (float*) mxGetData(prhs[0]);
  thrs = (float*) mxGetData(prhs[1]);
  fids = (uint32*) mxGetData(prhs[2]);
  child = (uint32*) mxGetData(prhs[3]);
  nThreads = (nrhs<5) ? 100000 : (int) mxGetScalar(prhs[4]);
  nThreads = min(nThreads,omp_get_max_threads());
  N = (int) mxGetM(prhs[0]);
  plhs[0] = mxCreateNumericMatrix(N,1,mxUINT32_CLASS,mxREAL);
  inds = (uint32*) mxGetPr(plhs[0]);
  forestInds(inds,data,thrs,fids,child,N,nThreads);
}
