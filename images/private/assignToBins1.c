/*********************************************************************
* DATESTAMP  29-Sep-2005  2:00pm
* Piotr's Image&Video Toolbox      Version 1.0   
* Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
* Please email me if you find bugs, or have suggestions or questions! 
*********************************************************************/

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



/*
 * Please see accompanying m file for usage.
 */

/* find out what bin each element in A falls into */
void assign2bins( double *B, double* A, double* edges, int nelements, int nbins )
{
    int j; 
    for( j=0; j < nelements; j++)
        B[j] = (double) findBin( A[j], edges, nbins ); 
}



void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
                 const mxArray *prhs[])
{
  /* Declare variables. */ 
  int nelements, nbins;
  double *A, *B, *edges;
  
  /* Error checking on arguments */    
  if (nrhs != 2)
    mexErrMsgTxt("Two input arguments required.");
  if (nlhs > 1) 
    mexErrMsgTxt("Too many output arguments.");
    
  /* extract arguments */
  A = (double *) mxGetData(prhs[0]);
  nelements = mxGetNumberOfElements(prhs[0]);
  edges = (double *) mxGetData(prhs[1]);
  nbins = (int) mxGetNumberOfElements(prhs[1]) -1;  
  
  /* create output array */
  /* Note extra bin, this is for values outsider range of edges */
  plhs[0] = mxCreateDoubleMatrix(1, nelements, mxREAL );
  B = (double *) mxGetData(plhs[0]);
  
  /* calculate the histograms */
  assign2bins( B, A, edges, nelements, nbins );
}
