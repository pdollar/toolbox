#include "mex.h";

void integralImagePrepare( int m, int n, double *I, double *II, double *sqII )
{	
	// create integral image and square integral image.
	// 1) set first row/column to II to be 0
	// 2) create first real row/column of II
	// 3) create remainder of II
 	double v; int i, j; int m1=m+1, n1=n+1;
	for( i = 0; i < n1; i++) II[m1*i] = sqII[m1*i] = 0;
	for( j = 0; j < m1; j++) II[j] = sqII[j] = 0;
	v = I[0]; II[1+m1]=v; sqII[1+m1]=v*v;
	for( i = 2; i < n+1; i++) {
		v = I[0+m*(i-1)];
		II[1+m1*i] = II[1+m1*(i-1)] + v;
		sqII[1+m1*i] = sqII[1+m1*(i-1)] + v*v;
	}
	for( j = 2; j < m+1; j++) {
		v = I[j-1];
		II[j+m1] = II[j-1+m1] + v;
		sqII[j+m1] = sqII[j-1+m1] + v*v;
	}
	for( j = 2; j < m+1; j++) for( i = 2; i < n+1; i++) {
		v = I[j-1+m*(i-1)];
		II[j+m1*i] = II[j-1+m1*i] + II[j+m1*(i-1)] - II[j-1+m1*(i-1)] + v;
		sqII[j+m1*i] = sqII[j-1+m1*i] + sqII[j+m1*(i-1)] - sqII[j-1+m1*(i-1)] + v*v;
	}
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
	// get / check inputs
	if(nrhs != 1) mexErrMsgTxt( "Only 1 input argument allowed." );
	if(nlhs != 2) mexErrMsgTxt( "Only 2 output arguments allowed." );

	// create output vars
	int m=mxGetM(plhs[0]), n=mxGetN(plhs[0]);
	plhs[0]=mxCreateDoubleMatrix(m+1,n+1,mxREAL); 
	plhs[1]=mxCreateDoubleMatrix(m+1,n+1,mxREAL);

	// get vars
	double *I, *II, *IIsq;
	I=mxGetPr(prhs[0]);
	II=mxGetPr(plhs[0]);
	IIsq=mxGetPr(plhs[1]);

	// run
	integralImagePrepare( m, n, I, II, IIsq );
}
