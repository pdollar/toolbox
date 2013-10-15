/*******************************************************************************
* Piotr's Image&Video Toolbox      Version 3.21
* Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "mex.h"
#include <vector>
#include <cmath>
using namespace std;

typedef unsigned int uint32;

inline void getChild( float *chns1, uint32 *cids, uint32 *fids,
  float *thrs, uint32 offset, uint32 &k0, uint32 &k )
{
  float ftr = chns1[cids[fids[k]]];
  k = (ftr<thrs[k]) ? 1 : 2;
  k0=k+=k0*2; k+=offset;
}

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
  const int treeDepth = mxGetField(trees,0,"treeDepth")==NULL ? 0 :
    (int) mxGetScalar(mxGetField(trees,0,"treeDepth"));

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
    if( treeDepth==1 ) {
      // specialized case for treeDepth==1
      for( int t = 0; t < nTrees; t++ ) {
        uint32 offset=t*nTreeNodes, k=offset, k0=0;
        getChild(chns1,cids,fids,thrs,offset,k0,k);
        h += hs[k]; if( h<=cascThr ) break;
      }
    } else if( treeDepth==2 ) {
      // specialized case for treeDepth==2
      for( int t = 0; t < nTrees; t++ ) {
        uint32 offset=t*nTreeNodes, k=offset, k0=0;
        getChild(chns1,cids,fids,thrs,offset,k0,k);
        getChild(chns1,cids,fids,thrs,offset,k0,k);
        h += hs[k]; if( h<=cascThr ) break;
      }
    } else if( treeDepth>2) {
      // specialized case for treeDepth>2
      for( int t = 0; t < nTrees; t++ ) {
        uint32 offset=t*nTreeNodes, k=offset, k0=0;
        for( int i=0; i<treeDepth; i++ )
          getChild(chns1,cids,fids,thrs,offset,k0,k);
        h += hs[k]; if( h<=cascThr ) break;
      }
    } else {
      // general case (variable tree depth)
      for( int t = 0; t < nTrees; t++ ) {
        uint32 offset=t*nTreeNodes, k=offset, k0=k;
        while( child[k] ) {
          float ftr = chns1[cids[fids[k]]];
          k = (ftr<thrs[k]) ? 1 : 0;
          k0 = k = child[k0]-k+offset;
        }
        h += hs[k]; if( h<=cascThr ) break;
      }
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
