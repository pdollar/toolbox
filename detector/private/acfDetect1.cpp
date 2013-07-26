/*******************************************************************************
* Sketch Token Toolbox     V0.9
* Copyright 2013 Joseph Lim [lim@csail.mit.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see bsd.txt]
*******************************************************************************/
#include "mex.h"
#include <vector>
#include <cmath>
using namespace std;

typedef unsigned int uint32;

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
  // get inputs
  float *chns = (float*) mxGetData(prhs[0]);
  mxArray *trees = (mxArray*) prhs[1];
  const int shrink = (int) mxGetScalar(prhs[2]);
  const int modelHt = (int) mxGetScalar(prhs[3]);
  const int modelWd = (int) mxGetScalar(prhs[4]);
  const int stride = (int) mxGetScalar(prhs[5]);
  const float cascThr = (float) mxGetScalar(prhs[6]);

  // extract relevant fields from trees
  float *thrs = (float*) mxGetData(mxGetField(trees,0,"thrs"));
  float *hs = (float*) mxGetData(mxGetField(trees,0,"hs"));
  uint32 *fids = (uint32*) mxGetData(mxGetField(trees,0,"fids"));
  uint32 *child = (uint32*) mxGetData(mxGetField(trees,0,"child"));

  // get dimensions and constants
  const mwSize *chnsSize = mxGetDimensions(prhs[0]);
  const int height = (int) chnsSize[0];
  const int width = (int) chnsSize[1];
  const int nChns = mxGetNumberOfDimensions(prhs[0])<=2 ? 1 : (int) chnsSize[2];
  const mwSize *fidsSize = mxGetDimensions(mxGetField(trees,0,"fids"));
  const int nTreeNodes = (int) fidsSize[0];
  const int nTrees = (int) fidsSize[1];
  const int height1 = (int) ceil(float(height*shrink-modelHt+1)/stride);
  const int width1 = (int) ceil(float(width*shrink-modelWd+1)/stride);

  // construct cids array
  int nFtrs = modelHt/shrink*modelWd/shrink*nChns;
  uint32 *cids = new uint32[nFtrs]; int m=0;
  for( int z=0; z<nChns; z++ )
    for( int c=0; c<modelWd/shrink; c++ )
      for( int r=0; r<modelHt/shrink; r++ )
        cids[m++] = z*width*height + c*height + r;

  // apply classifier to each patch
  vector<int> rs, cs; vector<float> hs1;
  for( int c=0; c<width1; c++ ) for( int r=0; r<height1; r++ ) {
    float h=0, *chns1=chns+(r*stride/shrink) + (c*stride/shrink)*height;
    for( int t = 0; t < nTrees; t++ ) {
      uint32 k = t*nTreeNodes;
      while( child[k] ) {
        float ftr = chns1[cids[fids[k]]];
        if(ftr<thrs[k]) k = child[k]-1; else k = child[k];
        k += t*nTreeNodes;
      }
      h += hs[k]; if( h<=cascThr ) break;
    }
    if(h>cascThr) { cs.push_back(c); rs.push_back(r); hs1.push_back(h); }
  }
  delete [] cids; m=cs.size();

  // convert to bbs
  plhs[0] = mxCreateNumericMatrix(m,5,mxDOUBLE_CLASS,mxREAL);
  double *bbs = (double*) mxGetData(plhs[0]);
  for( int i=0; i<m; i++ ) {
    bbs[i+0*m]=cs[i]*stride; bbs[i+2*m]=modelWd;
    bbs[i+1*m]=rs[i]*stride; bbs[i+3*m]=modelHt;
    bbs[i+4*m]=hs1[i];
  }
}
