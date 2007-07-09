/*********************************************************************
* DATESTAMP  29-Sep-2005  2:00pm
* Piotr's Image&Video Toolbox      Version 1.0   
* Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
* Please email me if you find bugs, or have suggestions or questions! 
*********************************************************************/

/*
 * Please see accompanying m file for usage.
 */

#include "mex.h"



/*
 * Return index of bin for x.  The edges are determined by the (nbins+1) 
 * element vector edges.  Returns an integer value k in [0,nbins-1] 
 * representing the bin x falls into, or k==nbins if x does not fall 
 * into any bin.  if edges[k] <= x < edges[k+1], then x falls 
 * into bin k (k<nbins).  Additionally, if x==edges[nbins], then x falls 
 * into bin k=nbins-1.  Eventually, all values where k==nbins should be ingored.
 * 
 * findBin adapted from \MATLAB6p5\toolbox\matlab\datafun\histc.c
 */
int findBin( double x, double *edges, int nbins )
{
    int k = nbins; /* NOBIN */
    
    int k0 = 0; int k1 = nbins;
    if (x >= edges[0] && x < edges[nbins]) {
        k = (k0+k1)/2;
        while (k0 < k1-1) {
            if (x >= edges[k]) k0 = k; 
            else k1 = k;
            k = (k0+k1)/2;
        }
        k = k0;
    }

    /* check for special case */
    if (x == edges[nbins])
         k = nbins-1;
		
    return k;
}





/**
 * Fast indexing into multidimensional arrays.  
 *
 * Call once and store the result:
 *    subMul = sub2ind_init( siz, nd );
 * Where siz is an nd length int array of sizes.
 *
 * Then, to index into an array A of size siz, given a subscript sub 
 * (where sub is an nd int array of subscripts), you can get the index 
 * into the array using: 
 *      sub2ind(ind,sub,subMul,nd)
 * This macro initializes ind.  Note that a looping variable "int k" 
 * must be previously defined.
 */
#define sub2ind(ind,sub,subMul,nd) ind=sub[0]; for(k=1;k<nd;k++) ind+=sub[k]*subMul[k]; 
int *sub2ind_init( const int*siz, const int nd )
{
    int i, *subMul;
    subMul = mxCalloc( nd, sizeof(int));
    subMul[0] = 1; for(i=1; i<nd; i++ ) subMul[i]=subMul[i-1]*siz[i-1]; 
    return subMul;
}



 
/* construct the nd dimensional histogram */
void histcND( double* h, double* A, double* weightmask, int n, int nd, 
                                      double**edges, int* nbins )
{
    /* looping vars - do not use k */
    int i, j, k, inbounds; 
    
    /*indexing into h  */
    int *subMul, *sub, ind;
    
    /* find out what bin each element in A falls into */
    sub = (int *) mxMalloc( nd * sizeof(int) );
    subMul = sub2ind_init( nbins, nd );
    for( i=0; i < n; i++) {
        inbounds = 1;
        for( j=0; j < nd; j++) {
            sub[j] = findBin( A[ n*j+i ], edges[j], nbins[j] );
            if(sub[j]==nbins[j]) {
                inbounds=0;
                break; 
            }
        }
        if( inbounds ) {
            sub2ind(ind,sub,subMul,nd);
            h[ ind ] += weightmask[i];
        }
    }
    mxFree( sub ); mxFree( subMul );
}






void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Declare variables. */ 
  int n, nd, *nbins;
  double *A, *weightmask, **edges, *h;
  int i;

  
  /* Error checking on arguments */    
  /* PRHS=[A1, weightmask, edges1, edges2, ...];   PLHS=[h]  */
  if( nrhs < 3)
    mexErrMsgTxt("At least three input arguments required.");
  if( nlhs > 1) 
    mexErrMsgTxt("Too many output arguments.");
  n = mxGetM( prhs[0] );  nd = mxGetN( prhs[0] );
  if( (mxGetM(prhs[1])!=1 && mxGetN(prhs[1])!=1) ||
        (mxGetM( prhs[1] )!=n && mxGetN( prhs[1] )!=n) )
    mexErrMsgTxt("weightmask must be a vector of length n (A is nxnd).");
  if( nrhs-2!=nd )
    mexErrMsgTxt("Number of edge vectors must equal nd (A is nxnd).");
  for( i=0; i < nd; i++) 
    if( mxGetM( prhs[i+2] )!=1 )
      mexErrMsgTxt("edges1 and edges2 must be row vectors.");

  /* extract arguments */
  A = mxGetPr(prhs[0]);
  weightmask = mxGetPr(prhs[1]);
  
  nbins = (int *) mxMalloc( nd * sizeof(int) );
  for( i=0; i < nd; i++) nbins[i] = mxGetN( prhs[i+2] ) -1;
  
  edges = (double **) mxCalloc( nd, sizeof(double*) );  
  for( i=0; i < nd; i++) 
      edges[i] = mxGetPr(prhs[i+2]);
  
  plhs[0] = mxCreateNumericArray(nd, nbins, mxDOUBLE_CLASS, mxREAL);
  h = mxGetPr( plhs[0] );

  /* call main function */
  histcND( h, A, weightmask, n, nd, edges, nbins );
  mxFree( nbins ); mxFree( edges );
}
