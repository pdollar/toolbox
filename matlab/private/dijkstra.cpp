//***************************************************************************
// FIBTEST.CPP
//
// Test program for the F-heap implementation.
// Copyright (c) 1996 by John Boyer.
// See header file for free usage information.
//
// This version has been updated by V. Rabaud and P. Dollar in 2008:
//  - to be compilable on GNU/Linux by removing the conio.h dependency.
//  - to send back the array of previous nodes on the shortest paths
//  - changed iostream.h to <iostream> and added using namespace std; 
//  - removed duplicate includes, cleaned up some, changed formatting
//***************************************************************************

#include <math.h>
#include "mex.h"
#include "fibheap.h"

#define _FIBHEAPTEST_CPP

//***************************************************************************
// This Fibonacci heap implementation is Copyright (c) 1996 by John Boyer.
// See the header file for free usage information.
//***************************************************************************

//===========================================================================
// class HeapNode
//===========================================================================
class HeapNode : public FibHeapNode {
  double   N;
  long int IndexV;

public:
  HeapNode() : FibHeapNode() { N = 0; };
  virtual void operator =(FibHeapNode& RHS);
  virtual int  operator ==(FibHeapNode& RHS);
  virtual int  operator <(FibHeapNode& RHS);
  virtual void operator =(double NewKeyVal );
  virtual void Print();
  double GetKeyValue() { return N; };
  void SetKeyValue(double n) { N = n; };
  long int GetIndexValue() { return IndexV; };
  void SetIndexValue( long int v) { IndexV = v; };
};

void HeapNode::Print() {
  FibHeapNode::Print();
  mexPrintf( "%f (%d)" , N , IndexV );
}

void HeapNode::operator =(double NewKeyVal) {
  HeapNode Temp;
  Temp.N = N = NewKeyVal;
  FHN_Assign(Temp);
}

void HeapNode::operator =(FibHeapNode& RHS) {
  FHN_Assign(RHS);
  N = ((HeapNode&) RHS).N;
}

int  HeapNode::operator ==(FibHeapNode& RHS) {
  if (FHN_Cmp(RHS)) return 0;
  return N == ((HeapNode&) RHS).N ? 1 : 0;
}

int  HeapNode::operator <(FibHeapNode& RHS) {
  int X;

  if ((X=FHN_Cmp(RHS)) != 0)
    return X < 0 ? 1 : 0;

  return N < ((HeapNode&) RHS).N ? 1 : 0;
};

//===========================================================================
// main
//===========================================================================

void dodijk_sparse( long int N, long int S, double *D, double *P, double *sr, int *irs, int *jcs, HeapNode *A, FibHeap  *theHeap  ) {
  int      finished;
  long int i,startind,endind,whichneighbor,ndone,closest;
  double   closestD,arclength;
  double   INF,SMALL,olddist;
  HeapNode *Min;
  HeapNode Temp;

  INF   = mxGetInf();
  SMALL = mxGetEps();

  /* initialize */
  for (i=0; i<N; i++) {
    if (i!=S) A[ i ] = (double) INF; else A[ i ] = (double) SMALL;
    if (i!=S) D[ i ] = (double) INF; else D[ i ] = (double) SMALL;
    if (P!=NULL) P[ i ] = -1;
    theHeap->Insert( &A[i] );
    A[ i ].SetIndexValue( (long int) i );
  }


  // Insert 0 then extract it.  This will cause the
  // Fibonacci heap to get balanced.

  theHeap->Insert(&Temp);
  theHeap->ExtractMin();

  /*theHeap->Print();
  for (i=0; i<N; i++)
  {
  closest = A[ i ].GetIndexValue();
  closestD = A[ i ].GetKeyValue();
  mexPrintf( "Index at i=%d =%d  value=%f\n" , i , closest , closestD );
  }*/

  /* loop over nonreached nodes */
  finished = 0;
  ndone    = 0;
  while ((finished==0) && (ndone < N)) {
    //if ((ndone % 100) == 0) mexPrintf( "Done with node %d\n" , ndone );

    Min = (HeapNode *) theHeap->ExtractMin();
    closest  = Min->GetIndexValue();
    closestD = Min->GetKeyValue();

    if ((closest<0) || (closest>=N))
      mexErrMsgTxt( "Minimum Index out of bound..." );

    //theHeap->Print();
    //mexPrintf( "EXTRACTED MINIMUM  NDone=%d S=%d closest=%d closestD=%f\n" , ndone , S , closest , closestD );
    //mexErrMsgTxt( "Exiting..." );

    D[ closest ] = closestD;

    if (closestD == INF) finished=1; else {
      /* add the closest to the determined list */
      ndone++;

      /* relax all nodes adjacent to closest */
      startind = jcs[ closest   ];
      endind   = jcs[ closest+1 ] - 1;

      if (startind!=endind+1)
        for (i=startind; i<=endind; i++) {
          whichneighbor = irs[ i ];
          arclength = sr[ i ];
          olddist   = D[ whichneighbor ];

          //mexPrintf( "INSPECT NEIGHBOR #%d  olddist=%f newdist=%f\n" , whichneighbor , olddist , closestD+arclength );

          if ( olddist > ( closestD + arclength )) {
            D[ whichneighbor ] = closestD + arclength;
            if(P!=NULL) P[ whichneighbor ] = closest + 1;    // +1 because Matlab indexes from 1 and not 0

            Temp = A[ whichneighbor ];
            Temp.SetKeyValue( closestD + arclength );
            theHeap->DecreaseKey( &A[ whichneighbor ], Temp );

            //mexPrintf( "UPDATING NODE #%d  olddist=%f newdist=%f\n" , whichneighbor , olddist , closestD+arclength );
          }
        }
    }
  }
}


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
  double    *sr,*D,*P,*SS,*Dsmall,*Psmall;
  int       *irs,*jcs;
  long int  M,N,S,MS,NS,i,j;

  HeapNode *A = NULL;
  FibHeap  *theHeap = NULL;

  if (nrhs != 2)
    mexErrMsgTxt( "Only 2 input arguments allowed." );
  if (nlhs > 2)
    mexErrMsgTxt( "Only 2 output argument allowed." );

  M = mxGetM( prhs[0] );
  N = mxGetN( prhs[0] );

  if (M != N) mexErrMsgTxt( "Input matrix needs to be square." );

  SS = mxGetPr(prhs[1]);
  MS = mxGetM( prhs[1] );
  NS = mxGetN( prhs[1] );

  if ((MS==0) || (NS==0) || ((MS>1) && (NS>1)))
    mexErrMsgTxt( "Source nodes are specified in one dimensional matrix only" );
  if (NS>MS) MS=NS;

  plhs[0] = mxCreateDoubleMatrix( MS,M, mxREAL);
  D = mxGetPr(plhs[0]);
  Dsmall = (double *) mxCalloc( M , sizeof( double ));

  plhs[1] = (nlhs<2) ? NULL : mxCreateDoubleMatrix( MS,M, mxREAL);
  P = (nlhs<2) ? NULL : mxGetPr(plhs[1]) ;
  Psmall = (nlhs<2) ? NULL : (double *) mxCalloc( M , sizeof( double ));

  if(mxIsSparse( prhs[ 0 ] ) == 1) {
    /* dealing with sparse array */
    sr      = mxGetPr(prhs[0]);
    irs     = mxGetIr(prhs[0]);
    jcs     = mxGetJc(prhs[0]);

    // Setup for the Fibonacci heap
    for (i=0; i<MS; i++) {
      if ((theHeap = new FibHeap) == NULL || (A = new HeapNode[M+1]) == NULL ) {
        mexErrMsgTxt( "Memory allocation failed-- ABORTING.\n" );
      }

      theHeap->ClearHeapOwnership();

      S = (long int) *( SS + i );
      S--;

      if ((S < 0) || (S > M-1)) mexErrMsgTxt( "Source node(s) out of bound" );

      // run the dijkstra code 
      //mexPrintf( "Working on i=%d\n" , i );
      dodijk_sparse( N,S,Dsmall,Psmall,sr,irs,jcs,A,theHeap );
      for (j=0; j<M; j++) {
        *( D + j*MS + i ) = *( Dsmall + j );
        if(nlhs==2) *( P + j*MS + i ) = *( Psmall + j );
        //mexPrintf( "Distance i=%d to j=%d =%f\n" , S+1 , j , *( Dsmall + j ) );
      }
      delete theHeap;
      delete[] A;
    }
  } else mexErrMsgTxt( "Function not implemented for full arrays" );
}
