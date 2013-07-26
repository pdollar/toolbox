/*******************************************************************************
* Piotr's Image&Video Toolbox      Version 3.20
* Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Simplified BSD License [see external/bsd.txt]
*******************************************************************************/

/**************************************************************************
 * Based on ISOMAP code which can be found at http:*isomap.stanford.edu/.
 * See accompanying m file (dijkstra.m) for usage.
 *************************************************************************/

/**************************************************************************
 * Bug fix for certain versions of VC++ compiler when used in Matlab.
 * http://www.mathworks.com/matlabcentral/newsreader/view_thread/281754
 *************************************************************************/
#if (_MSC_VER >= 1600)
#define __STDC_UTF_16__
typedef unsigned short char16_t;
#endif

#include "mex.h"
#include "fibheap.h"
#define DIJKSTRA_CPP

/**************************************************************************
 * class HeapNode
 *************************************************************************/
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
  HeapNode Tmp;
  Tmp.N = N = NewKeyVal;
  FHN_Assign(Tmp);
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

/*************************************************************************
 * main
 *************************************************************************/
void dijkstra1( long int n, long int s, double *D1, double *P1, double *Gpr, mwIndex *Gir, mwIndex *Gjc) {
  int      finished;
  long int i, startInd, endInd, whichNeigh, nDone, closest;
  double   closestD, arcLength, INF, SMALL, oldDist;
  HeapNode *A, *hnMin, hnTmp; FibHeap *heap;
  INF=mxGetInf(); SMALL=mxGetEps();
  
  // setup heap
  if ((heap = new FibHeap) == NULL || (A = new HeapNode[n+1]) == NULL )
    mexErrMsgTxt( "Memory allocation failed-- ABORTING.\n" );
  heap->ClearHeapOwnership();
  
  // initialize
  for (i=0; i<n; i++) {
    if (i!=s) A[ i ] = (double) INF; else A[ i ] = (double) SMALL;
    if (i!=s) D1[ i ] = (double) INF; else D1[ i ] = (double) SMALL;
    P1[ i ] = -1;
    heap->Insert( &A[i] );
    A[ i ].SetIndexValue( (long int) i );
  }
  
  // Insert 0 then extract it, which will balance heap
  heap->Insert(&hnTmp); heap->ExtractMin();
  
  // loop over nonreached nodes
  finished = nDone = 0;
  while ((finished==0) && (nDone < n)) {
    hnMin = (HeapNode *) heap->ExtractMin();
    closest  = hnMin->GetIndexValue();
    closestD = hnMin->GetKeyValue();
    if ((closest<0) || (closest>=n))
      mexErrMsgTxt( "Minimum Index out of bound..." );
    D1[ closest ] = closestD;
    if (closestD == INF) finished=1; else {
      // relax all nodes adjacent to closest
      nDone++;
      startInd = Gjc[ closest   ];
      endInd   = Gjc[ closest+1 ] - 1;
      if( startInd!=endInd+1 )
        for( i=startInd; i<=endInd; i++ ) {
        whichNeigh = Gir[ i ];
        arcLength = Gpr[ i ];
        oldDist = D1[ whichNeigh ];
        if ( oldDist > ( closestD + arcLength )) {
          D1[ whichNeigh ] = closestD + arcLength;
          P1[ whichNeigh ] = closest + 1;
          hnTmp = A[ whichNeigh ];
          hnTmp.SetKeyValue( closestD + arcLength );
          heap->DecreaseKey( &A[ whichNeigh ], hnTmp );
        }
        }
    }
  }
  
  // cleanup
  delete heap; delete[] A;
}

void dijkstra( long int n, long int nSrc, double *sources, double *D, double *P, const mxArray *G ) {
  // dealing with sparse array
  double *Gpr = mxGetPr(G);
  mwIndex *Gir = mxGetIr(G);
  mwIndex *Gjc = mxGetJc(G);
  
  // allocate memory for single source results (automatically recycled)
  double *D1 = (double *) mxCalloc( n , sizeof( double ));
  double *P1 = (double *) mxCalloc( n , sizeof( double ));
  
  // loop over sources
  long int s, i, j;
  for( i=0; i<nSrc; i++ ) {
    
    // run the dijkstra1 code for single source (0 indexed)
    s = (long int) *( sources + i ) - 1;
    if (s<0 || s > n-1) mexErrMsgTxt( "Source node(s) out of bound" );
    dijkstra1( n, s, D1, P1, Gpr, Gir, Gjc );
    
    // store results
    for( j=0; j<n; j++ ) {
      *( D + j*nSrc + i ) = *( D1 + j );
      *( P + j*nSrc + i ) = *( P1 + j );
    }
  }
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
  double    *D, *P, *sources;
  long int  n, mSrc, nSrc;
  
  // get / check inputs
  if (nrhs != 2) mexErrMsgTxt( "Only 2 input arguments allowed." );
  if (nlhs > 2) mexErrMsgTxt( "Only 2 output argument allowed." );
  n = mxGetN( prhs[0] );
  if (mxGetM( prhs[0] ) != n) mexErrMsgTxt( "Input matrix G needs to be square." );
  sources = mxGetPr(prhs[1]); mSrc = mxGetM(prhs[1]); nSrc=mxGetN(prhs[1]);
  if ((mSrc==0) || (nSrc==0) || ((mSrc>1) && (nSrc>1)))
    mexErrMsgTxt( "Source nodes are specified in vector only" );
  if(mSrc>nSrc) nSrc=mSrc;
  if(mxIsSparse(prhs[0])==0) mexErrMsgTxt( "Distance Matrix must be sparse" );
  
  // create outputs arrays D and P
  plhs[0] = mxCreateDoubleMatrix( nSrc, n, mxREAL );
  plhs[1] = mxCreateDoubleMatrix( nSrc, n, mxREAL );
  D = mxGetPr(plhs[0]);
  P = mxGetPr(plhs[1]) ;
  
  // run dijkstras to fill D and P
  dijkstra( n, nSrc, sources, D, P, prhs[0] );
}
