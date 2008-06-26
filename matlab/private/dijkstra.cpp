//***************************************************************************
// DIJKSTRA.CPP
// 
// Based on ISOMAP code which can be found at http://isomap.stanford.edu/.
//***************************************************************************

#include "mex.h"
#include "fibheap.h"
#define DIJKSTRA_CPP

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

//===========================================================================
// main
//===========================================================================

void dijkstra1( long int N, long int S, double *D1, double *P1, double *G, int *Gir, int *Gjc, HeapNode *A, FibHeap *heap ) {
  int      finished;
  long int i,startInd,endInd,whichNeigh,nDone,closest;
  double   closestD,arcLength,INF,SMALL,oldDist;
  HeapNode *hnMin, hnTmp;
  INF=mxGetInf(); SMALL=mxGetEps();

  // initialize
  for (i=0; i<N; i++) {
    if (i!=S) A[ i ] = (double) INF; else A[ i ] = (double) SMALL;
    if (i!=S) D1[ i ] = (double) INF; else D1[ i ] = (double) SMALL;
    if (P1!=NULL) P1[ i ] = -1;
    heap->Insert( &A[i] );
    A[ i ].SetIndexValue( (long int) i );
  }

  // Insert 0 then extract it, which will balance heap
  heap->Insert(&hnTmp); heap->ExtractMin();

  // loop over nonreached nodes
  finished = nDone = 0;
  while ((finished==0) && (nDone < N)) {
    hnMin = (HeapNode *) heap->ExtractMin();
    closest  = hnMin->GetIndexValue();
    closestD = hnMin->GetKeyValue();
    if ((closest<0) || (closest>=N))
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
          arcLength = G[ i ];
          oldDist = D1[ whichNeigh ];
          if ( oldDist > ( closestD + arcLength )) {
            D1[ whichNeigh ] = closestD + arcLength;
            if(P1!=NULL) P1[ whichNeigh ] = closest + 1;
            hnTmp = A[ whichNeigh ];
            hnTmp.SetKeyValue( closestD + arcLength );
            heap->DecreaseKey( &A[ whichNeigh ], hnTmp );
          }
        }
    }
  }
}

//void dijkstra( long int N, long int NS, double *SS, double *D, double *P, double *G, int *Gir, int *Gjc ) {
//  double   *D1,*P1;
//  HeapNode *A = NULL;
//  FibHeap  *heap = NULL;
//  long int S,i,j;
//  
//  D1 = (double *) mxCalloc( N , sizeof( double ));
//  P1 = (P!=NULL) ? NULL : (double *) mxCalloc( N , sizeof( double ));
//
//  for( i=0; i<NS; i++ ) {
//    // setup heap
//    if ((heap = new FibHeap) == NULL || (A = new HeapNode[N+1]) == NULL )
//      mexErrMsgTxt( "Memory allocation failed-- ABORTING.\n" );
//    heap->ClearHeapOwnership();
//
//    // get source node (0 indexed)
//    S = (long int) *( SS + i ); S--;
//    if ((S < 0) || (S > N-1)) mexErrMsgTxt( "Source node(s) out of bound" );
//
//    // run the dijkstra code 
//    dijkstra1( N,S,D1,P1,G,Gir,Gjc,A,heap );
//
//    // store results
//    for( j=0; j<N; j++ ) {
//      *( D + j*NS + i ) = *( D1 + j );
//      if(P!=NULL) *( P + j*NS + i ) = *( P1 + j );
//    }
//
//    // cleanup
//    delete heap; delete[] A;
//  }
//}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
  double    *G,*D,*P,*SS;
  int       *Gir,*Gjc;
  long int  N,MS,NS;

  // get / check inputs
  if (nrhs != 2) mexErrMsgTxt( "Only 2 input arguments allowed." );
  if (nlhs > 2) mexErrMsgTxt( "Only 2 output argument allowed." );
  N = mxGetN( prhs[0] );
  if (mxGetM( prhs[0] ) != N) mexErrMsgTxt( "Input matrix needs to be square." );
  SS = mxGetPr(prhs[1]); MS = mxGetM(prhs[1]); NS=mxGetN(prhs[1]);
  if ((MS==0) || (NS==0) || ((MS>1) && (NS>1)))
    mexErrMsgTxt( "Source nodes are specified in one dimensional matrix only" );
  if (MS>NS) NS=MS;
  if(mxIsSparse(prhs[ 0 ])==0)
    mexErrMsgTxt( "Function not implemented for full arrays" );

  // create outputs and temp variables
  plhs[0] = mxCreateDoubleMatrix( NS,N, mxREAL);
  D = mxGetPr(plhs[0]);
  plhs[1] = (nlhs<2) ? NULL : mxCreateDoubleMatrix( NS,N, mxREAL);
  P = (nlhs<2) ? NULL : mxGetPr(plhs[1]) ;

  // dealing with sparse array 
  G      = mxGetPr(prhs[0]);
  Gir     = mxGetIr(prhs[0]);
  Gjc     = mxGetJc(prhs[0]);

  // run dijkstra
  //dijkstra( N, NS, SS, D, P, G, Gir, Gjc );

  // setup for dijkstra
  double   *D1,*P1;
  HeapNode *A = NULL;
  FibHeap  *heap = NULL;
  long int S,i,j;
  D1 = (double *) mxCalloc( N , sizeof( double ));
  P1 = (P==NULL) ? NULL : (double *) mxCalloc( N , sizeof( double ));

  for (i=0; i<NS; i++) {
    // setup heap
    if ((heap = new FibHeap) == NULL || (A = new HeapNode[N+1]) == NULL )
      mexErrMsgTxt( "Memory allocation failed-- ABORTING.\n" );
    heap->ClearHeapOwnership();

    // get source node (0 indexed)
    S = (long int) *( SS + i ); S--;
    if ((S < 0) || (S > N-1)) mexErrMsgTxt( "Source node(s) out of bound" );

    // run the dijkstra code for single source
    dijkstra1( N,S,D1,P1,G,Gir,Gjc,A,heap );

    // store results
    for (j=0; j<N; j++) {
      *( D + j*NS + i ) = *( D1 + j );
      if(P!=NULL) *( P + j*NS + i ) = *( P1 + j );
    }

    // cleanup
    delete heap; delete[] A;
  }
}
