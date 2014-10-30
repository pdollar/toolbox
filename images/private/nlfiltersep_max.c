/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 2.2
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include "mex.h"

#define arraymax(A, m, s, e, i) m=A[s]; for(i=s+1; i<=e; i++) { m=((A[i])>(m)?(A[i]):(m)); };
int maxi( int x, int y ) { return (x > y) ? x : y; };
int mini( int x, int y ) { return (x < y) ? x : y; };

/*******************************************************************************
* Row non-linear seperable filter - max (see nlfiltersep.m)
*  x = nlfiltersep_max( [ 1 9; 5 9; 0 0; 4 8; 7 3; 2 6], 1, 1 )
*  y = [5 9; 5 9; 5 9; 7 8; 7 8; 7 6]; x-y
* B(i,j) is the max of A(i-r1:i+r2,j). It has the same dims as A.
* Border calculations are done separately for efficiency.
*******************************************************************************/
void nlfiltersep_max( const double *A, double *B, int r1, int r2, int mRows, int nCols ) {
  int i, row0, e, s, r, c; double m;
  for( c=0; c<nCols; c++ ) {
    row0 = mRows * c;
    /* leading border calculations */
    for(r=0; r<mini(r1, mRows-1); r++) {
      e = mini( r+r2, mRows-1 );
      arraymax( A, m, row0, row0+e, i );
      B[r+row0] = m;
    }
    /* main caclulations */
    for(r=r1; r<mRows-r2; r++) {
      arraymax( A, m, r-r1+row0, r+r2+row0, i ); B[r+row0]=m;
    }
    /* end border calculations */
    for(r=maxi(mRows-r2-1, 0); r<mRows; r++) {
      s = maxi( r-r1, 0 );
      arraymax( A, m, s+row0, mRows-1+row0, i );
      B[r+row0] = m;
    }
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int mRows, nCols, r1, r2; double *A, *B;
  
  /* Error checking on arguments */
  if( nrhs!=3 ) mexErrMsgTxt("Three input arguments required.");
  if( nlhs>1 ) mexErrMsgTxt("Too many output arguments.");
  mRows = mxGetM(prhs[0]); nCols = mxGetN(prhs[0]);
  if(!mxIsDouble(prhs[0])) mexErrMsgTxt("Input array must be of type double.");
  
  /* extract inputs */
  A = (double*) mxGetData(prhs[0]);
  r1 = (int) mxGetScalar(prhs[1]);
  r2 = (int) mxGetScalar(prhs[2]);
  
  /* create outputs */
  plhs[0] = mxCreateDoubleMatrix(mRows, nCols, mxREAL );
  B = (double*) mxGetData(plhs[0]);
  
  /* Apply filter */
  nlfiltersep_max( A, B, r1, r2, mRows, nCols );
}
