/*********************************************************************
* DATESTAMP  29-Sep-2005  2:00pm
* Piotr's Image&Video Toolbox      Version 1.0   
* Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
* Please email me if you find bugs, or have suggestions or questions! 
*********************************************************************/


#include "mex.h"

/* 
    Please see accompanying m file for usage.

    Row non-linear seperable block filter - sum  (see nlfiltblock_sep)    
    
    Given an mxn array A and a distance d, *sums* every d elements along
    the FIRST dimension - ie along each ROW.  This is a BLOCK operations.
    
    
    Example:
    >>  rnlfiltblock_sum( [ 1 9; 5 9; 0 0; 4 8; 7 3; 2 6], 3 )

        ans =
             6    18
            13    17    
                         
    Note that A must have type double. Works for multidimensional 
    arrays but will need to reshape output. 
*/
    

#define max(A,B) ( (A) > (B) ? (A):(B))
#define arraysum(A,m,s,e,i) m=0; for(i=s; i<=e; i++) { m+=A[i]; };

void rnlfiltblock_sum( const double *A, double *B, const int d, const int mrows, const int ncols )
{
    int i;
    double m;
    
    int Aoffset, Boffset;
    int coli, blocki;
    int nblocks;
    
    /* get dimensions of blocks */
    nblocks = mrows / d;

    /* scan over all columns */
    for( coli=0; coli<ncols; coli++ ) {
        Aoffset = mrows * coli;
        Boffset = nblocks * coli;
        
        /* for each column, scan over all blocks */
        for(blocki=0; blocki<nblocks; blocki++ ) {
            arraysum( A, m, Aoffset, Aoffset+d-1, i ); 
            B[Boffset] = m;
            Aoffset += d;
            Boffset += 1;
        }
     }
}



void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
                 const mxArray *prhs[])
{
  /* Declare variables. */ 
  int mrows, ncols;
  double *A; double* B; int d;

  
  /* Error checking on arguments */    
  if (nrhs != 2)
    mexErrMsgTxt("Two input arguments required.");
  if (nlhs > 1) 
    mexErrMsgTxt("Too many output arguments.");
  mrows = mxGetM( prhs[0] );   ncols = mxGetN( prhs[0] );
  if (mxIsComplex(prhs[1]) || !(mxGetM(prhs[1])==1 && mxGetN(prhs[1])==1))
    mexErrMsgTxt("2nd input must be a noncomplex scalar.");   
  if (mxIsDouble(prhs[0])==0)
    mexErrMsgTxt("Input array must be of type double.");      
    
  /* extract arguments */
  A = (double *) mxGetData(prhs[0]);
  d = (int) mxGetScalar(prhs[1]);
  
  /* create output array */
  plhs[0] = mxCreateDoubleMatrix(mrows/d, ncols, mxREAL );
  B = (double *) mxGetData(plhs[0]);
  
  /* Apply filter */
  rnlfiltblock_sum( A, B, d, mrows, ncols );
}
