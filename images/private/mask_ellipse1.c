/*********************************************************************
* DATESTAMP  29-Sep-2005  2:00pm
* Piotr's Image&Video Toolbox      Version 1.0   
* Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
* Adapted from code by: Kristin Branson || kbranson-at-cs.ucsd.edu
* Please email me if you find bugs, or have suggestions or questions! 
*********************************************************************/

#include "mex.h"
#include <math.h>

#define max(a,b) a>b ? a : b

unsigned int get_ellipse_interior_inds(int* interior_pnts, int mrows, int ncols,
				 double crow, double ccol, double theta, double a, double b) {

  /* Stuff for finding the leftmost and rightmost ellipse interior points */
  double denom, sint, cost, coladd;
  int colsmall, colbig;

  /* Stuff for finding the upper and lower ellipse interior points */
  double A, B, C;
  double rowsmall, rowbig, temp;

  /* other variables */
  int row, col; /* looping */
  double costheta, sintheta, tantheta; /* angle */
  int max_interior_pts = mrows * ncols; /* max # of possible points */
  int ninterior_pnts; /*actual # of points found */
  
  
  /* angles */
  theta = 3.14159265 - theta;
  costheta = cos(theta); sintheta = sin(theta); tantheta = sintheta/costheta;

  
  /* Find the leftmost and rightmost points of the ellipse */
  denom = sqrt(pow(a,2)*pow(costheta,2) + pow(b,2)*pow(sintheta,2));
  sint = b*sintheta/denom;   cost = a*costheta/denom;
  coladd = a*costheta*cost + b*sintheta*sint;
  if(coladd < 0) coladd = -coladd;
  colsmall = ceil( ccol - coladd );  colbig = floor( ccol + coladd );
  if(colsmall < 1) colsmall = 1;     if(colbig > ncols) colbig = ncols;
    
  /* Find the top and bottom points for each c */
  ninterior_pnts = 0;
  for(col = colsmall; col <= colbig; col++) {
  
    /* get A,B,C */
    A = (col-ccol)/(a*costheta);
    B = b/a*tantheta;
    C = pow(B,2)-pow(A,2)+1;
    if(C < 0){ mexErrMsgTxt("inside of sqrt less than 0!");  return 0; }
    
    /* calculate start and end of row */
    rowsmall = crow - a * sintheta * (A-B*sqrt(C))/(B*B+1) + b * costheta * (A*B+sqrt(C))/(B*B+1);
    rowbig = crow - a * sintheta * (A+B*sqrt(C))/(B*B+1) + b * costheta * (A*B-sqrt(C))/(B*B+1);
    if (rowsmall>rowbig) {temp=rowsmall; rowsmall=rowbig; rowbig=temp;  }
    rowsmall = ceil(rowsmall-.0001);        rowbig = floor(rowbig+.0001);
    if(rowsmall < 1) rowsmall = 1;          if(rowbig > mrows) rowbig = mrows;
    
    /* Add points in between top and bottom for this c */
    for(row = (int) rowsmall; row <= (int) rowbig; row++){
      interior_pnts[ninterior_pnts] = row;
      interior_pnts[ninterior_pnts+max_interior_pts] = col;
      ninterior_pnts++;
    }
  }
  
  return ninterior_pnts;
}

				 

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i;

  /* ellipse parameters */ 
  double crow, ccol, theta, a, b;

  /* image size */
  int mrows, ncols;
  
  /* will contain ouput */
  int *interior_pnts;
  unsigned int ninterior_pnts;
  
  
  /* Error checking on arguments */    
  if (nrhs != 7)
    mexErrMsgTxt("7 input arguments required.");
  if (nlhs > 2) 
    mexErrMsgTxt("Too many output arguments.");
  for( i=0; i<7; i++ ) {
    if (mxIsComplex(prhs[i]) || !(mxGetM(prhs[i])==1 && mxGetN(prhs[i])==1))
        mexErrMsgTxt("Input must be a noncomplex scalar.");           
  }
  
  
  /* extract arguments (ellipse paramters) */
  crow = mxGetScalar( prhs[0] );  
  ccol = mxGetScalar( prhs[1] );
  a = mxGetScalar( prhs[2] );
  b = mxGetScalar( prhs[3] );  
  theta = mxGetScalar( prhs[4] );

  /* extract arguments (image size) */  
  mrows = mxGetScalar( prhs[5] );
  ncols = mxGetScalar( prhs[6] );
  
  /* create output array */
  plhs[1] = mxCreateNumericMatrix( mrows * ncols, 2, mxINT32_CLASS, mxREAL );
  interior_pnts = (int*) mxGetData(plhs[1]);
  
  /* get actual points inside of ellipse */
  ninterior_pnts = get_ellipse_interior_inds( interior_pnts, mrows, ncols, crow, ccol, theta, a, b);
  plhs[0] = mxCreateDoubleScalar( ninterior_pnts );
}
