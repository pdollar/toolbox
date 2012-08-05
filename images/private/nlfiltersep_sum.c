/**************************************************************************
 * Piotr's Image&Video Toolbox      Version 2.2
 * Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
 * Please email me if you find bugs, or have suggestions or questions!
 * Licensed under the Simplified BSD License [see external/bsd.txt]
 *************************************************************************/
#include "mex.h"

#define arraysum(A, m, s, e, i) m=0; for(i=s; i<=e; i++) { m+=A[i]; };
int	maxi( int x, int y ) { return (x > y) ? x : y; };
int	mini( int x, int y ) { return (x < y) ? x : y; };

/**************************************************************************
 * Row non-linear seperable filter - sum (see nlfiltersep.m)
 *  x = nlfiltersep_sum( [ 1 9; 5 9; 0 0; 4 8; 7 3; 2 6], 1, 1 )
 *  y = [6 18; 6 18; 9 17; 11 11; 13 17; 9 9]; x-y
 * B(i,j) is the sum of A(i-r1:i+r2,j). It has the same dims as A.
 * This can be implemented effiicently because:
 *  B[i] = B[i-1] + A[i+r2] - A[i-r1-1];
 * Does not work for initial (r1+1) and final r2 values in each row.
 *************************************************************************/
void nlfiltersep_sum( const double *A, double *B, int r1, int r2, int mRows, int nCols ) {
  int i, row0, e, s, r, c; double m;
  for( c=0; c<nCols; c++ ) {
    row0 = mRows * c;
    /* leading border calculations */
    for(r=0; r<=mini(r1, mRows-1); r++) {
      e = mini( r+r2, mRows-1 );
      arraysum( A, m, row0, row0+e, i );
      B[r+row0] = m;
    }
    /* main caclulations */
    for(r=r1+1; r<mRows-r2; r++) {
      B[r+row0] = B[r+row0-1] + A[r+row0+r2] - A[r+row0-r1-1];
    }
    /* end border calculations */
    for(r=maxi(mRows-r2, 0); r<mRows; r++) {
      s = maxi( r-r1, 0 );
      arraysum( A, m, s+row0, mRows-1+row0, i );
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
  nlfiltersep_sum( A, B, r1, r2, mRows, nCols );
}
