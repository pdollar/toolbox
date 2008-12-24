/**************************************************************************
* Rand.cpp
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
**************************************************************************/
#include "Rand.h"

static long		RANDSEED = -1;

float			randf()
{
	// Minimal random number generator of Park and Miller with Bays-Durham shuffle and added
	// safeguards. Returns a uniform random deviate between 0.0 and 1.0 (exclusive of the endpoint
	// values). Call with RANDSEED a negative integer to initialize; thereafter, do not alter
	// RANDSEED between successive deviates in a sequence. RNMX should approximate the largest
	// floating value that is less than 1 period of about 10^8. From NUMERICAL RECIPES IN C.
	static const long	IA		= 16807;
	static const long	IM		= 2147483647;
	static const double	AM		= (1.0/IM);
	static const long	IQ		= 127773;
	static const long	IR		= 2836;
	static const long	NTAB	= 32;
	static const double	NDIV	= (1+(IM-1)/NTAB);
	static const double	EPS		= 1.2e-7;
	static const double	RNMX	= (1.0-EPS);

	int j; long k;
	static long iy=0;
	static long iv[NTAB];
	float temp;

	//INITIALIZE
	if (RANDSEED <= 0 || !iy) {
		if (-(RANDSEED) < 1) RANDSEED=1;
		else RANDSEED = -(RANDSEED);
		for (j=NTAB+7;j>=0;j--) {//Load the shuffle table (after 8 warm-ups).
			k=(RANDSEED)/IQ;
			RANDSEED=IA*(RANDSEED-k*IQ)-IR*k;
			if (RANDSEED < 0) RANDSEED += IM;
			if (j < NTAB) iv[j] = RANDSEED;
		}
		iy=iv[0];
	}

	k=(RANDSEED)/IQ;					//Start here when not initializing.
	RANDSEED=IA*(RANDSEED-k*IQ)-IR*k;	//Compute RANDSEED=(IA*RANDSEED) % IM without
	if (RANDSEED < 0) RANDSEED += IM;	//overflows by Schrage’s method.
	j= (int) (((double)iy)/NDIV);		//Will be in the range 0..NTAB-1.
	iy=iv[j];							//Output previously stored value and refill the
	iv[j] = RANDSEED;					//shuffle table.
	if ((temp=(float)(AM*iy)) > (float) RNMX)
		return ((float) RNMX);			//Because users don’t expect endpoint values.
	else return temp;
}

int				randi( int minV, int mavV ) {
	return minV + (int) (((float)(mavV-minV+1))*randf());
}

double			randgauss( double mean, double sig )
{
	// Generate 2 Gaussian random number using 2 random numbers from the uniform [0,1] distr.
	double x1, x2, y1, wid=1.0; static double y2; static bool useLast=false;
	if(useLast) y1=y2; else {
		while( wid >= 1.0 ) {
			x1 = 2.0 * randf() - 1.0;
			x2 = 2.0 * randf() - 1.0;
			wid = x1 * x1 + x2 * x2;
		}
		wid = sqrt( (-2.0 * log( wid ) ) / wid );
		y1 = x1 * wid; y2 = x2 * wid;
	}
	useLast = !useLast;
	return( mean + y1 * sig );
}

void			randperm( vectori &p, int n, int k )
{
	int i, r, t; if(k<0) k=n; if(k>n) k=n;
	p.clear(); p.resize(n,0); for(i=0; i<n; i++) p[i]=i;
	for( i=0; i<k; i++ ) { r=randi(i,n-1); t=p[r]; p[r]=p[i]; p[i]=t; }
	p.resize(k);
}

void			sampleGaussian( Matrixd &V, int d, int n, double w, double *mean, double *sig )
{
	RF rf; Matrixd V1; V.setDims(n,d);
	for( int i=0; i<d; i++ ) {
		rf.setGaussian(mean[i],sig[i],w);
		rf.setCdf(); rf.sample(V1,n,1);
		for(int j=0; j<n; j++) V(j,i)=V1(j,0);
	}
}

void			sampleUniform( Matrixd &V, int d, int n, double w, double *minV, double *maxV )
{
	RF rf; Matrixd V1; V.setDims(n,d);
	for( int i=0; i<d; i++ ) {
		rf.setUniform(minV[i],maxV[i],w);
		rf.setCdf(); rf.sample(V1,n,1);
		for(int j=0; j<n; j++) V(j,i)=V1(j,0);
	}
}

///////////////////////////////////////////////////////////////////////////////
void			RF::toObjImg( ObjImg &oi, const char *name ) const
{
	oi.init(name,getCname(),4);
	oi._children[0].frmPrim("minV",&_minV);
	oi._children[1].frmPrim("w",&_w);
	oi._children[2].frmPrim("wInv",&_wInv);
	_pdf.toObjImg(oi._children[3],"pdf");
}

void			RF::frmObjImg( const ObjImg &oi, const char *name )
{
	clearCdf();
	oi.check(name,getCname(),4,4);
	oi._children[0].toPrim("minV",&_minV);
	oi._children[1].toPrim("w",&_w);
	oi._children[2].toPrim("wInv",&_wInv);
	_pdf.frmObjImg(oi._children[3],"pdf");
}

///////////////////////////////////////////////////////////////////////////////
void			RF::init( double minV, double mavV, double w )
{
	assert(minV<=mavV);
	_minV=minV; _w=w; _wInv=1.0/_w;
	int cnt = (int) ((mavV-minV)*_wInv+1.01);
	_pdf.setDims(1,cnt,0); clearCdf();
}

void			RF::normalize()
{
	clearCdf(); double sum=_pdf.sum();
	if( sum==0 ) error("empty pdf");
	_pdf*=1/sum;
}

void			RF::setUniform( double minV, double mavV, double w )
{
	RF::init( minV, mavV, w );
	_pdf.setVal(1); normalize();
}

void			RF::setUniformInt( int minV, int mavV )
{
	RF::init( minV, mavV, 1.0 );
	_pdf.setVal(1); normalize();
}

void			RF::setGaussian( double mean, double sig, double w )
{
	RF::init( mean-4*sig, mean+4*sig, w );
	if(getCnt()== 0) return;
	double x, z=-1/(2*sig*sig);
	for( int i=0; i<getCnt(); i++) {
		x=getVal(i)-mean; _pdf(i)=exp(x*x*z);
	}
	normalize();
}

void			RF::setPoisson( double lambda )
{
	if( lambda>100 ) error( "SetPoisson(lambda) only works if lambda<=100" );
	init( 0.0, min(150.0,15.0*lambda), 1.0 ); double factorial=1;
	for( int i=0; i<getCnt(); i++ ) { // overflow a bit after i>150
		_pdf(i)=pow(lambda,(double)i)/(exp(lambda)*factorial); factorial *= i+1;
	}
	normalize();
}

void			RF::set( const vectord &v, double minV, double mavV, double w )
{
	if(minV==mavV) { minV=0; mavV=v.size()-1; } init(minV,mavV,w);
	for(size_t i=0; i<v.size(); i++) _pdf(i)=(double) v[i];
	normalize();
}

void			RF::set( const Matrixd &v, double minV, double mavV, double w )
{
	if(minV==mavV) { minV=0; mavV=v.numel()-1; } init(minV,mavV,w);
	for(int i=0; i<v.numel(); i++) _pdf(i)=(double) v(i);
	normalize();
}

///////////////////////////////////////////////////////////////////////////////
double			RF::pdf( double x ) const
{
	int ind = getInd(x);
	if(!inRange(ind)) return 0.0;
	return _pdf(ind);
}

double			RF::cdf( double x ) const
{
	int ind=getInd(x); if(ind>=getCnt()) return 1.0; 
	if(cdfInit()) return _cdf(ind); // precomputed
	double c=0.0; for(int j=0; j<=ind; j++) c+=_pdf(j); return c;
}

double			RF::mean() const
{
	double mean = 0;
	for(int i=0; i<getCnt(); i++)
		mean += _pdf(i)*getVal(i);
	return mean;
}

double			RF::variance() const
{
	double mean=0, var=0, v;
	for(int i=0; i<getCnt(); i++) {
		v=getVal(i); mean+=_pdf(i)*v; var+=_pdf(i)*v*v;
	}
	return (var-mean*mean);
}

///////////////////////////////////////////////////////////////////////////////
void			RF::setCdf(int cntPerBin)
{
	normalize(); if(cntPerBin<1) cntPerBin=1;
	int cdfCount = min( 1000000, cntPerBin*getCnt() );
	_cdfInd.setDims(1,cdfCount); _cdf.setDims(1,getCnt());
	double cumDel=1.0/double(cdfCount), cumi=0, cum=cumDel/10; int j=0;
	for(int i=0; i<getCnt(); i++) {
		cumi+=_pdf(i); _cdf(i)=cumi;
		while(cum < cumi) { _cdfInd(j++)=i; cum+=cumDel; }
	}
	assert( j==cdfCount );
}

double			RF::sampleNonSetCdf(double cumsum) const
{
	if( cumsum==0 ) cumsum=_pdf.sum();
	if( cumsum==0 ) error( "Cannot sample: empty pdf");
	double v=randf()*cumsum, sum=0.0; int ind;
	for( ind=0; ind<getCnt(); ind++) {
		sum+=_pdf(ind); if( sum>=v && _pdf(ind)>0.0 ) break;
	}
	if( ind==getCnt() ) error("cumsum invalid");
	return getVal( ind );
}

void			RF::sample(				Matrixd &V, int rows, int cols ) const
{
	if(!cdfInit()) error("CDF not set"); assert(rows>=0 && cols>=0);
	V.setDims(rows,cols); for(int i=0; i<rows*cols; i++) V(i)=sample();
}

void			RF::sample(				vectord &v, int n ) const
{
	if(!cdfInit()) error("CDF not set"); assert(n>=0);
	v.clear(); v.resize(n); for(int i=0; i<n; i++) v[i]=sample();
}

void			RF::sampleNoReplace(	Matrixd &V, int rows, int cols )
{
	vectord v; int n=rows*cols; sampleNoReplace(v,n); assert(n==rows*cols);
	V.setDims(rows,cols); for(int i=0; i<V.numel(); i++) V(i)=v[i];
}

void			RF::sampleNoReplace(	vectord &v, int &n )
{
	assert(n>=0); v.clear();
	int nMax = (int) (_pdf>0).sum(); n=min(n,nMax);
	if( n==nMax ) {
		for(int i=0; i<getCnt(); i++) if(_pdf(i)>0.0)
			v.push_back( getVal(i) );
	} else {
		v.resize(n); RF tmp=*this;
		double cumsum=tmp._pdf.sum(), v1; int ind;
		for(int i=0; i<n; i++ ) {
			v1=tmp.sampleNonSetCdf(cumsum); v[i]=v1;
			ind=getInd(v1); cumsum-=tmp._pdf(ind);
			tmp._pdf(ind)=0.0;
		}
	}
}
