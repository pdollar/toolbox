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

	// data - uncomment one of the following
	//int x=87519651; Primitive<int> X(&x);
	//bool x[4]={true,false,true,false}; Primitive<bool> X(x,4);
	//uchar x=13; Primitive<uchar> X(&x);
	//double x=1.15415987557; Primitive<double> X(&x);
	//float x[2]={59.5,7500}; Primitive<float> X(x,2);
	//char *x="whatev yo"; Primitive<char> X(x,strlen(x)+1);
	//Matrixd X(5,5,0); for(int i=0; i<5; i++) X(i,i)=i;
	//Rect X(0,0,10,10); X._wt=.3f;
	Haar X; X.createSyst(1,25,25,10,10,0,0); X.finalize();

	// to matlab struct, from matlab struct, to matlab struct again
	mxArray *M = X.toMxArray();
	Savable *Y = Savable::frmMxArray(M);
	plhs[0] = Y->toMxArray();
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