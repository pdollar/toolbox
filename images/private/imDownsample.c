/***************************************************************************
* IMDOWNSAMPLE.C
*
* Fast bilinear downsampling. Inspired by resize.cpp from Deva Ramanan.
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
****************************************************************************/
#include <math.h>
#include "mex.h"

/* struct used for caching interpolation values for single column */
typedef struct { int ya, yb; double weight; } InterpInfo;

InterpInfo*		copmuteInterpInfo( int ha, int hb, int *n )
{
	/* compute interpolation values for single column */
	int c, ya, yb, yaStr, yaEnd; double sc, scInv, yaStrf, yaEndf; InterpInfo *ii;
	sc = (double)hb/(double)ha; scInv = 1.0/sc;
	*n = (int)ceil(hb*scInv)+2*hb; yaStrf=0; yaEndf=scInv; c=0;
	ii = (InterpInfo*) mxMalloc(sizeof(InterpInfo)*(*n));
	for( yb=0; yb<hb; yb++ ) {
		yaStr=(int)ceil(yaStrf); yaEnd=(int)floor(yaEndf);
		if( yaStr-yaStrf > 1e-3 ) { /* upper elt contributing to yb */
			ii[c].yb=yb; ii[c].ya=yaStr-1; ii[c].weight=(yaStr-yaStrf)*sc; c++;
		}
		for( ya=yaStr; ya<yaEnd; ya++ ) { /* main elts contributing to yb */
			ii[c].yb=yb; ii[c].ya=ya; ii[c].weight=sc; c++;
		}
		if( yaEndf-yaEnd > 1e-3 ) { /* lower elt contributing to yb */
			ii[c].yb=yb; ii[c].ya=yaEnd; ii[c].weight=(yaEndf-yaEnd)*sc; c++;
		}
		yaStrf=yaEndf; yaEndf+=scInv;
	}
	*n=c; return ii;
}

void			downsample2( double *a, double *b, InterpInfo *ii, int n )
{
	/* downsample single column a, store in b */
	InterpInfo *end = ii + n;
	while(ii!=end) { b[ii->yb]+=ii->weight*a[ii->ya]; ii++; }
}

void			downsample1( double *A, double *B, int ha, int hb, int w, int nCh )
{
	/* downsample every column in A, store in B, result is transposed */
	int ch, x, n; double *a, *b; InterpInfo *ii;
	ii = copmuteInterpInfo( ha, hb, &n );
	for(x=0; x<n; x++ ) ii[x].yb*=w; /* transpose B */
	for(ch=0; ch<nCh; ch++) for(x=0; x<w; x++) {
		a = A + ch*w*ha + x*ha;
		b = B + ch*w*hb + x;
		downsample2(a, b, ii, n);
	}
	mxFree(ii);
}

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	/* B=downsample(A,scale) - A should be 2 or 3 dim with double vals */
	double scale0, scale1; int *ns, ms[3], nCh, nDims; double *A,*B,*T;

	/* Error checking on arguments */
	if( nrhs<2 || nrhs>3) mexErrMsgTxt("Two or three inputs expected.");
	if( nlhs>1 ) mexErrMsgTxt("One output expected.");
	nDims=mxGetNumberOfDimensions(prhs[0]);
	if( (nDims!=2 && nDims!=3) || mxGetClassID(prhs[0])!=mxDOUBLE_CLASS)
		mexErrMsgTxt("A must be a double 2 or 3 dim array.");
	scale0=mxGetScalar(prhs[1]); scale1=(nrhs==3)?mxGetScalar(prhs[2]):scale0;
	if( scale0>1 || scale1>1 ) mexErrMsgTxt("Scaling factor must be at most 1.");

	/* create output array */
	ns = (int*) mxGetDimensions(prhs[0]); nCh=(nDims==2) ? 1 : ns[2];
	ms[0]=(int)(ns[0]*scale0+.5); ms[1]=(int)(ns[1]*scale1+.5); ms[2]=nCh;
	plhs[0] = mxCreateNumericArray(3,ms,mxDOUBLE_CLASS, mxREAL);

	/* Perform rescaling */
	A = (double*) mxGetPr(prhs[0]);
	B = (double*) mxGetPr(plhs[0]);
	T = (double*) mxCalloc(ms[0]*ns[1]*nCh, sizeof(double));
	downsample1(A, T, ns[0], ms[0], ns[1], nCh);
	downsample1(T, B, ns[1], ms[1], ms[0], nCh);
	mxFree(T);
}
