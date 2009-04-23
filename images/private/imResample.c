/***************************************************************************
* IMRESAMPLE.C
*
* Fast bilinear down/up sampling. Inspired by resize.cpp from Deva Ramanan.
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2009 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
****************************************************************************/
#include <math.h>
#include "mex.h"

/* struct used for caching interpolation values for single column */
typedef struct { int yb, ya0, ya1; double wt0, wt1; } InterpInfo;

InterpInfo*		interpInfoDn( int ha, int hb, int *n )
{
	/* compute interpolation values for single column for DOWN sampling */
	int c, ya, yb, ya0, ya1; double sc, scInv, ya0f, ya1f; InterpInfo *ii;
	sc = (double)hb/(double)ha; scInv = 1.0/sc;
	*n = (int)ceil(hb*scInv)+2*hb; ya0f=0; ya1f=scInv; c=0;
	ii = (InterpInfo*) mxMalloc(sizeof(InterpInfo)*(*n));
	for( yb=0; yb<hb; yb++ ) {
		ya0=(int)ceil(ya0f); ya1=(int)floor(ya1f);
		if( ya0-ya0f > 1e-3 ) { /* upper elt contributing to yb */
			ii[c].yb=yb; ii[c].ya0=ya0-1; ii[c].wt0=(ya0-ya0f)*sc; c++; }
		for( ya=ya0; ya<ya1; ya++ ) { /* main elts contributing to yb */
			ii[c].yb=yb; ii[c].ya0=ya; ii[c].wt0=sc; c++; }
		if( ya1f-ya1 > 1e-3 ) { /* lower elt contributing to yb */
			ii[c].yb=yb; ii[c].ya0=ya1; ii[c].wt0=(ya1f-ya1)*sc; c++; }
		ya0f=ya1f; ya1f+=scInv;
	}
	*n=c; return ii;
}

InterpInfo*		interpInfoUp( int ha, int hb, int *n )
{
	/* compute interpolation values for single column for UP sampling */
	int ya, yb; double sc, scInv, yaf; InterpInfo *ii;
	sc = (double)hb/(double)ha; scInv = 1.0/sc; yaf=.5*scInv-.5;
	ii = (InterpInfo*) mxMalloc(sizeof(InterpInfo)*hb);
	for( yb=0; yb<hb; yb++ ) {
		ii[yb].yb=yb; ya=(int) floor(yaf);
		if(ya<0) { /* if near start of column */
			ii[yb].wt1=0; ii[yb].ya0=ii[yb].ya1=0;
		} else if( ya>=ha-1 ) { /* if near end of column */
			ii[yb].wt1=0; ii[yb].ya0=ii[yb].ya1=ha-1;
		} else { /* interior */
			ii[yb].wt1=yaf-ya; ii[yb].ya0=ya; ii[yb].ya1=ya+1;
		}
		ii[yb].wt0=1.0-ii[yb].wt1; yaf+=scInv;
	}
	*n=hb; return ii;
}

void			resample( double *A, double *B, int ha, int hb, int w, int nCh )
{
	/* resample every column in A, store in B, result is transposed */
	int ch, x, y, n; double *a, *b; const bool downsample=(hb<=ha); InterpInfo *ii;
	if(downsample) ii=interpInfoDn(ha,hb,&n); else ii=interpInfoUp(ha,hb,&n);
	for(x=0; x<n; x++) ii[x].yb*=w; /* transpose B */
	for(ch=0; ch<nCh; ch++) for(x=0; x<w; x++) {
		a = A + ch*w*ha + x*ha;
		b = B + ch*w*hb + x;
		if( downsample )
			for(y=0; y<n; y++) b[ii[y].yb]+=ii[y].wt0*a[ii[y].ya0];
		else
			for(y=0; y<n; y++) b[ii[y].yb]=a[ii[y].ya0]*ii[y].wt0+a[ii[y].ya1]*ii[y].wt1;
	}
	mxFree(ii);
}

void			mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	/* B=imResample(A,scale) or B=imResample(A,h,w); */
	double input1=0, input2=0; int *ns, ms[3], nCh, nDims; void *A,*B,*T; mxClassID id;

	/* Error checking on arguments */
	if( nrhs<2 || nrhs>3) mexErrMsgTxt("Two or three inputs expected.");
	if( nlhs>1 ) mexErrMsgTxt("One output expected.");
	nDims=mxGetNumberOfDimensions(prhs[0]); id=mxGetClassID(prhs[0]);
	if( (nDims!=2 && nDims!=3) || id!=mxDOUBLE_CLASS )
		mexErrMsgTxt("A should be 2D or 3D double array.");
	input1=mxGetScalar(prhs[1]); if(nrhs>=3) input2=mxGetScalar(prhs[2]);

	/* create output array */
	ns = (int*) mxGetDimensions(prhs[0]); nCh=(nDims==2) ? 1 : ns[2]; ms[2]=nCh;
	if( nrhs==2 ) {
		ms[0]=(int) (ns[0]*input1+.5); ms[1]=(int) (ns[1]*input1+.5);
	} else {
		ms[0]=(int) input1; ms[1]=(int) input2;
	}
	plhs[0] = mxCreateNumericArray(3,ms,id,mxREAL);

	/* Perform rescaling */
	A=mxGetData(prhs[0]); B=mxGetData(plhs[0]);
	T=mxCalloc(ms[0]*ns[1]*nCh, mxGetElementSize(prhs[0]));
	resample( (double*) A, (double*) T, ns[0], ms[0], ns[1], nCh);
	resample( (double*) T, (double*) B, ns[1], ms[1], ms[0], nCh);
	mxFree(T);
}
