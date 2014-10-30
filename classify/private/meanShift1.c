/*******************************************************************************
* Piotr's Computer Vision Matlab Toolbox      Version 2.50
* Copyright 2014 Piotr Dollar.  [pdollar-at-gmail.com]
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/
#include <math.h>
#include <string.h>
#include "mex.h"

/*******************************************************************************
* Calculates mean of all the points in data that lie on a sphere of
* radius^2==radius2 centered on [1xp] vector x. data is [nxp]. mean
* contains [1xp] result and return is number of points used for calc.
*******************************************************************************/
int meanVec( double *x, double *data, int p, int n, double radius2,
        double *mean ) {
  int i, j; double dist; int cnt=0, m=0;
  for( j=0; j<p; j++ ) mean[j]=0;
  for( i=0; i<n; i++ ) {
    dist = 0.0;
    for( j=0; j<p; j++ ) {
      dist += (x[j]-data[cnt])*(x[j]-data[cnt]); cnt++;
    }
    if( dist < radius2 ) {
      cnt-=p; m++;
      for( j=0; j<p; j++ ) mean[j]+=data[cnt++];
    }
  }
  if( m ) for( j=0; j<p; j++ ) mean[j]/=m;
  return m;
}

/* Squared euclidean distance between two vectors. */
double dist( double *A, double *B, int n ) {
  double d=0.0; int i;
  for(i=0; i<n; i++) d+=(A[i]-B[i]) * (A[i]-B[i]);
  return d;
}

/*******************************************************************************
* data      - p x n column matrix of data points
* p         - dimension of data points
* n         - number of data points
* radius    - radius of search windo
* rate      - gradient descent proportionality factor
* maxIter   - max allowed number of iterations
* blur      - specifies algorithm mode
* labels    - labels for each cluster
* means     - output (final clusters)
*******************************************************************************/
void meanShift( double data[], int p, int n, double radius, double rate,
        int maxIter, bool blur, double labels[], double *means ) {
  double radius2;    /* radius^2 */
  int iter;          /* number of iterations */
  double *mean;      /* mean vector */
  int i, j, o, m;    /* looping and temporary variables */
  int delta = 1;     /* indicator if change occurred between iterations */
  int *deltas;       /* indicator if change occurred between iterations per point */
  double *meansCur;  /* calculated means for current iter */
  double *meansNxt;  /* calculated means for next iter */
  double *data1;     /* If blur data1 points to meansCur else it points to data */
  int *consolidated; /* Needed in the assignment of cluster labels */
  int nLabels = 1;   /* Needed in the assignment of cluster labels */
  
  /* initialization */
  meansCur = (double*) malloc( sizeof(double)*p*n );
  meansNxt = (double*) malloc( sizeof(double)*p*n );
  mean = (double*) malloc( sizeof(double)*p );
  consolidated = (int*) malloc( sizeof(int)*n );
  deltas = (int*) malloc( sizeof(int)*n );
  for(i=0; i<n; i++) deltas[i] = 1;
  radius2 = radius * radius;
  meansCur = (double*) memcpy(meansCur, data, p*n*sizeof(double) );
  if( blur ) data1=meansCur; else data1=data;
  
  /* main loop */
  mexPrintf("Progress: 0.000000"); mexEvalString("drawnow;");
  for(iter=0; iter<maxIter; iter++) {
    delta = 0;
    for( i=0; i<n; i++ ) {
      if( deltas[i] ) {
        /* shift meansNxt in direction of mean (if m>0) */
        o=i*p; m=meanVec( meansCur+o, data1, p, n, radius2, mean );
        if( m ) {
          for( j=0; j<p; j++ ) meansNxt[o+j] = (1-rate)*meansCur[o+j] + rate*mean[j];
          if( dist(meansNxt+o, meansCur+o, p)>0.001) delta=1; else deltas[i]=0;
        } else {
          for( j=0; j<p; j++ ) meansNxt[o+j] = meansCur[o+j]; deltas[i]=0;
        }
      }
    }
    mexPrintf( "\b\b\b\b\b\b\b\b%f", (float)(iter+1)/maxIter ); mexEvalString("drawnow;");
    memcpy( meansCur, meansNxt, p*n*sizeof(double) ); if(!delta) break;
  }
  mexPrintf( "\n" );
  
  /* Consolidate: assign all points that are within radius2 to same cluster. */
  for( i=0; i<n; i++ ) { consolidated[i]=0; labels[i]=0; }
  for( i=0; i<n; i++ ) if( !consolidated[i]) {
    for( j=0; j<n; j++ ) if( !consolidated[j]) {
      if( dist(meansCur+i*p, meansCur+j*p, p) < radius2) {
        labels[j]=nLabels; consolidated[j]=1;
      }
    }
    nLabels++;
  }
  nLabels--; memcpy( means, meansCur, p*n*sizeof(double) );
  
  /* free memory */
  free(meansNxt); free(meansCur); free(mean); free(consolidated); free(deltas);
}

/* see meanShift.m for usage info */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
  double radius, rate, *data, *labels, *means; int p, n, maxIter; bool blur;
  
  /* Check inputs */
  if(nrhs < 4) mexErrMsgTxt("At least four input arguments required.");
  if(nlhs > 2) mexErrMsgTxt("Too many output arguments.");
  if(nrhs==5) blur = mxGetScalar(prhs[4])!=0;
  
  /* Get inputs */
  data = mxGetPr(prhs[0]);
  radius = mxGetScalar(prhs[1]);
  rate = mxGetScalar(prhs[2]);
  maxIter = (int) mxGetScalar(prhs[3]);
  p=mxGetM(prhs[0]); n=mxGetN(prhs[0]);
  
  /* Create outputs */
  plhs[0] = mxCreateNumericMatrix(n, 1, mxDOUBLE_CLASS, mxREAL);
  plhs[1] = mxCreateNumericMatrix(p, n, mxDOUBLE_CLASS, mxREAL);
  labels=mxGetPr(plhs[0]); means=mxGetPr(plhs[1]);
  
  /* Do the actual computations in a subroutine */
  meanShift( data, p, n, radius, rate, maxIter, blur, labels, means );
}
