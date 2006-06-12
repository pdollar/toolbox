/*********************************************************************
* DATESTAMP  29-Sep-2005  2:00pm
* Piotr's Image&Video Toolbox      Version 1.0   
* Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
* Please email me if you find bugs, or have suggestions or questions! 
*********************************************************************/


#include "mex.h"

/* 
    Please see accompanying m file for usage.
    
    Row non-linear seperable filter - max  (see nlfilt_sep)
    
    Given an mxn array A and a radius r, replaces each element A[i] with
    the maximum value in A within r elements of i along the FIRST dimension -
    ie along each ROW.  
    
    Example:
    >>  rnlfilt_max( [ 1 9; 5 9; 0 0; 4 8; 7 3; 2 6], 1 )
        ans =
             5     9
             5     9
             5     9
             7     8
             7     8
             7     6

    Note that A must have type double. Works for multidimensional 
    arrays but will need to reshape output. 
*/
    

#define max(A,B) ( (A) > (B) ? (A):(B))
#define min(A,B) ( (A) < (B) ? (A):(B))
#define arraymax(A,m,s,e,i) m=A[s];  for(i=s+1; i<=e; i++) { m=((A[i])>(m)?(A[i]):(m)); };

/**
 * B(i,j) is the max of A(i-r1:i+r2,j).  It has the same dimensions as A.
 * For efficiency, the leading and ending border calculations are done separately 
 * (these require an if statement every iteration). Works even if r1 or r2 is as big 
 * as A, except in this case no 'main calculations' are done and there is some 
 * duplication of effort.
 */
void rnlfilt_max( const double *A, double *B, const int r1, const int r2, 
                            const int mrows, const int ncols )
{
    int i;
    double m;
    int rowstart, e, s;
    int rowi, coli;
    
    for( coli=0; coli<ncols; coli++ ) {
        rowstart = mrows * coli;
    
        /* leading border calculations */
        for(rowi=0; rowi<min(r1,mrows-1); rowi++) {
            e = min( rowi+r2, mrows-1 );
            arraymax( A, m, rowstart, rowstart+e, i ); 
            B[rowi+rowstart] = m;
        }
    
        /* main caclulations */
        for(rowi=r1; rowi<mrows-r2; rowi++) {
            arraymax( A, m, rowi-r1+rowstart, rowi+r2+rowstart, i ); 
            B[rowi+rowstart] = m;
        }
    
        /* end border calculations */
        for(rowi=max(mrows-r2-1,0); rowi<mrows; rowi++) {
            s = max( rowi-r1, 0 );
            arraymax( A, m, s+rowstart, mrows-1+rowstart, i ); 
            B[rowi+rowstart] = m;
        }
    }
}




void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
                 const mxArray *prhs[])
{
  /* Declare variables. */ 
  int mrows, ncols;
  double *A; double* B;
  int r1, r2;

  
  /* Error checking on arguments */    
  if (nrhs != 3)
    mexErrMsgTxt("Three input arguments required.");
  if (nlhs > 1) 
    mexErrMsgTxt("Too many output arguments.");
  mrows = mxGetM( prhs[0] );   ncols = mxGetN( prhs[0] );
  if (mxIsComplex(prhs[1]) || !(mxGetM(prhs[1])==1 && mxGetN(prhs[1])==1))
    mexErrMsgTxt("2nd input must be a noncomplex scalar.");   
  if (mxIsDouble(prhs[0])==0)
    mexErrMsgTxt("Input array must be of type double.");  
    
  /* extract arguments */
  A = (double *) mxGetData(prhs[0]);
  r1 = (int) mxGetScalar(prhs[1]);
  r2 = (int) mxGetScalar(prhs[2]);
  
  /* create output array */
  plhs[0] = mxCreateDoubleMatrix(mrows, ncols, mxREAL );
  B = (double *) mxGetData(plhs[0]);
  
  /* Apply filter */
  rnlfilt_max( A, B, r1, r2, mrows, ncols );
}
