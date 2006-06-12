/*********************************************************************
* DATESTAMP  29-Sep-2005  2:00pm
* Piotr's Image&Video Toolbox      Version 1.0   
* Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
* Please email me if you find bugs, or have suggestions or questions! 
*********************************************************************/


#include "mex.h"

/* 
    Please see accompanying m file for usage.

    Row non-linear seperable filter - sum  (see nlfilt_sep)
    
    Given an mxn array A and a distance d, *sums* every d elements along
    the FIRST dimension - ie along each ROW.  Note that this is **extra** 
    efficient because it keeps track of running sums.
    
    Example:
    >>  rnlfilt_sum( [ 1 9; 5 9; 0 0; 4 8; 7 3; 2 6], 1 )
        ans =
             6    18
             6    18
             9    17
            11    11
            13    17
             9     9
                         
    Note that A must have type double. Works for multidimensional 
    arrays but will need to reshape output. 
*/
    

#define max(A,B) ( (A) > (B) ? (A):(B))
#define min(A,B) ( (A) < (B) ? (A):(B))
#define arraysum(A,m,s,e,i) m=0; for(i=s; i<=e; i++) { m+=A[i]; };

/**
 * B(i,j) is the sum of A(i-r1:i+r2,j).  It has the same dimensions as A.
 * This can be implemented effiicently because:
 *     B[i] = B[i-1] + A[i+r2] - A[i-r1-1];
 * Of course this trick does not work on the initial initial (r1+1) values
 * or the last (r2) values in each row.  Works even if r1 or r2 is as big 
 * as A, except in this case no 'main calculations' are done and there is 
 * some duplication of effort.
 */
void rnlfilt_sum( const double *A, double *B, const int r1, const int r2, 
                            const int mrows, const int ncols )
{
    int i;
    double m;
    int rowstart, e, s;
    int rowi, coli;

    for( coli=0; coli<ncols; coli++ ) {
        rowstart = mrows * coli;
    
        /* leading border calculations */
        for(rowi=0; rowi<=min(r1,mrows-1); rowi++) { 
            e = min( rowi+r2, mrows-1 );
            arraysum( A, m, rowstart, rowstart+e, i ); 
            B[rowi+rowstart] = m;
        }

        /* main caclulations */
        for(rowi=r1+1; rowi<mrows-r2; rowi++) {
            B[rowi+rowstart] = B[rowi+rowstart-1] + A[rowi+rowstart+r2] 
                                                    - A[rowi+rowstart-r1-1];
        }
    
        /* end border calculations */
        for(rowi=max(mrows-r2,0); rowi<mrows; rowi++) {
            s = max( rowi-r1, 0 );
            arraysum( A, m, s+rowstart, mrows-1+rowstart, i ); 
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
  rnlfilt_sum( A, B, r1, r2, mrows, ncols );
}
