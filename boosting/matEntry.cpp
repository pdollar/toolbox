#include "Public.h"
#include "Matrix.h"
#include "IntegralImage.h"
#include "Haar.h"

#include "mex.h"

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
	//Rect a(0,0,4,4), b;
	//SavObj*	s = a.save("Rect");
	//b.load( *s );
	//mexPrintf((a==b) ? "YAY" : "NAY");
	Haar b;
	SavObj*	s = h.save("Haar");
	b.load( *s );
	mexPrintf((h==b) ? "YAY" : "NAY");

	// return
	convert(resp,plhs[0]);
}
