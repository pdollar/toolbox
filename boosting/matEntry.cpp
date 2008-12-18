#include "mex.h"

#include "Savable.h"
#include "Public.h"
#include "Matrix.h"
#include "IntegralImage.h"
#include "Haar.h"

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
	// get / check inputs
	if(nrhs != 0) mexErrMsgTxt( "Only 0 input args allowed." );
	if(nlhs > 1) mexErrMsgTxt( "Only 1 output args allowed." );

	//// data - uncomment one of the following
	const int n=1; int x[n]={87519651};
	//const int n=5; int x[n]={1,2,3,4,5};
	//const int n=4; bool x[n]={true,false,true,false};
	//const int n=1; uchar x[n]={13};
	//const int n=7; uchar x[n]={-1,1,2,3,4,5,256};
	//const int n=1; double x[n]={1.15415987557};
	//const int n=2; float x[n]={59.5,7500};
	//char *x="whatev yo"; const int n=strlen(x)+1;
	ObjImg X; X.frmPrim( "x", x, n );

	//// data (complex) - uncomment one of the following
	//Matrixd x(5,5,0); for(int i=0; i<5; i++) x(i,i)=i;
	//Rect x(0,0,10,10); x._wt=.3f;
	//VecSavable x;
	//Haar x; x.createSyst(1,25,25,10,10,0,0); x.finalize();
	//ObjImg X; X.frmSavable("x",&x);
	//// fun time
	//Savable *y = X.toSavable("x");
	//X.clear(); X.frmSavable("y",y); delete y;

	// to matlab struct, from matlab struct, to matlab struct again
	mxArray *M = X.toMxArray();
	X.clear(); X.frmMxArray( M );
	plhs[0] = X.toMxArray();
}

/*
template<class T> void	convert( const mxArray *A, Matrix<T> &B )
{
	int m=mxGetM(A), n=mxGetN(A);
	B.setDims(m,n);
	double *pA=mxGetPr(A);
	for( int i=0; i<B.size(); i++ ) B(i)=(T) pA[i];
}

template<class T> void	convert( const Matrix<T> &A, mxArray *&B )
{
	int m=A.rows(), n=A.cols();
	B = mxCreateDoubleMatrix( m, n, mxREAL );
	double *pB=mxGetPr(B);
	for( int i=0; i<A.size(); i++ ) pB[i]=A(i);
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
	// get / check inputs
	if(nrhs != 1) mexErrMsgTxt( "Only 1 input argument allowed." );
	if(nlhs > 1) mexErrMsgTxt( "Only 1 output argument allowed." );

	// prep
	Matrixd A; IntegralImage II;
	convert(prhs[0], A);
	II.prepare(A);

	// run
	Haar h; h.createSyst( 0, 50, 50, 10, 10, 0, 0 );
	Matrixf resp; h.convHaar( resp, II, 1, false );

	// test
	ObjImg oi; h.save( oi, "haar" );
	Haar b;	b.load( oi, "haar" );
	mexPrintf((h==b) ? "YAY\n" : "NAY\n");

	// return
	convert(resp,plhs[0]);
}
*/
