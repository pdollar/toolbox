/*******************************************************************************
* Piotr's Image&Video Toolbox      Version 3.24
* Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include <mex.h>
#ifdef USEOMP
#include <omp.h>
#endif

typedef unsigned char uint8;
typedef unsigned int uint32;
#define min(x,y) ((x) < (y) ? (x) : (y))

template<typename T>
void forestInds( uint32 *inds, const T *data, const T *thrs,
  const uint32 *fids, const uint32 *child, int N, int nThreads )
{
  #ifdef USEOMP
  nThreads = min(nThreads,omp_get_max_threads());
  #pragma omp parallel for num_threads(nThreads)
  #endif
  for( int i = 0; i < N; i++ ) {
    uint32 k = 0;
    while( child[k] )
      if( data[i+fids[k]*size_t(N)] < thrs[k] )
        k = child[k]-1; else k = child[k];
    inds[i] = k+1;
  }
}

// inds=mexFunction(data,thrs,fids,child,[nThreads])
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int N, nThreads; void *data, *thrs; uint32 *inds, *fids, *child;
  data = mxGetData(prhs[0]);
  thrs = mxGetData(prhs[1]);
  fids = (uint32*) mxGetData(prhs[2]);
  child = (uint32*) mxGetData(prhs[3]);
  nThreads = (nrhs<5) ? 100000 : (int) mxGetScalar(prhs[4]);
  N = (int) mxGetM(prhs[0]);
  plhs[0] = mxCreateNumericMatrix(N,1,mxUINT32_CLASS,mxREAL);
  inds = (uint32*) mxGetPr(plhs[0]);
  if(mxGetClassID(prhs[0])!=mxGetClassID(prhs[1]))
    mexErrMsgTxt("Mismatch between data types.");
  if(mxGetClassID(prhs[0])==mxSINGLE_CLASS)
    forestInds(inds,(float*)data,(float*)thrs,fids,child,N,nThreads);
  else if(mxGetClassID(prhs[0])==mxDOUBLE_CLASS)
    forestInds(inds,(double*)data,(double*)thrs,fids,child,N,nThreads);
  else if(mxGetClassID(prhs[0])==mxUINT8_CLASS)
    forestInds(inds,(uint8*)data,(uint8*)thrs,fids,child,N,nThreads);
  else mexErrMsgTxt("Unknown data type.");
}
