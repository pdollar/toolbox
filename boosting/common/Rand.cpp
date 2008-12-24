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

double			randgauss( double mean, double sigma )
{
	// Generate 2 Gaussian random number using 2 random numbers from the uniform distr.
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
	return( mean + y1 * sigma );
}

void			randperm( vectori &p, int n, int k )
{
	int i, r, t; if(k<0) k=n; if(k>n) k=n;
	p.clear(); p.resize(n,0); for(i=0; i<n; i++) p[i]=i;
	for( i=0; i<k; i++ ) { r=randi(i,n-1); t=p[r]; p[r]=p[i]; p[i]=t; }
	p.resize( k, 0 );
}

void			sampleGaussian( Matrixd &V, double *mean, double *std, int d, int n, double w )
{
	RF rf; Matrixd V1; V.setDims(n,d);
	for( int i=0; i<d; i++ ) {
		rf.setGaussian(mean[i],std[i],w);
		rf.setCdf(); rf.sample(V1,n,1);
		for(int j=0; j<n; j++) V(j,i)=V1(j,0);
	}
}

void			sampleUniform( Matrixd &V, double *minVs, double *maxVs, int d, int n, double w )
{
	RF rf; Matrixd V1; V.setDims(n,d);
	for( int i=0; i<d; i++ ) {
		rf.setUniform(minVs[i],maxVs[i],w);
		rf.setCdf(); rf.sample(V1,n,1);
		for(int j=0; j<n; j++) V(j,i)=V1(j,0);
	}
}

///////////////////////////////////////////////////////////////////////////////
//void			RF::writeToStrm(ofstream &strm)
//{
//	_pdf.writeToStrm( strm );
//	strm.write((char*)&_cnt,	sizeof(_cnt));
//	strm.write((char*)&_minV,	sizeof(_minV));
//	strm.write((char*)&_w,		sizeof(_w));
//	strm.write((char*)&_wInv,	sizeof(_wInv));
//}
//
//void			RF::readFrmStrm(ifstream &strm)
//{
//	_cdfCount = 0;
//	_pdf.readFrmStrm( strm );
//	strm.read((char*)&_cnt,		sizeof(_cnt));
//	strm.read((char*)&_minV,	sizeof(_minV));
//	strm.read((char*)&_w,		sizeof(_w));
//	strm.read((char*)&_wInv,	sizeof(_wInv));
//}

///////////////////////////////////////////////////////////////////////////////
void			RF::init( double minV, double mavV, double w )
{
	assert(minV<=mavV);
	_minV = minV;
	_w = w;
	_wInv = 1.0/_w;
	_cnt = (int) ((mavV-minV)*_wInv+1.01);
	assert(_cnt>0);
	_pdf.setDims(1,_cnt);
	setAllBins(0.0);
	_cdfCount = 0;
}

void			RF::setAllBins( double p)
{
	_pdf.setVal(p);
	_cdfCount = 0;
}

void			RF::setOneBin( double x, double p)
{
	int index = getIndex(x);
	if( inRange(index) )
		_pdf(index)=p;
	_cdfCount = 0;
}

void			RF::addToBin( double x, double p)
{
	int index = getIndex(x);
	if( inRange(index) )
		_pdf(index)+=p;
	_cdfCount = 0;
}

bool			RF::normalize()
{
	_cdfCount = 0;
	double sum = _pdf.sum();
	if( sum==0.0 ) return false; else {
		_pdf *= (1/sum);
		return true;
	}
}

void			RF::setUniform( double minV, double mavV, double w )
{
	RF::init( minV, mavV, w );
	setAllBins( 1.0 ); normalize();
}

void			RF::setUniformInt( int minV, int mavV )
{
	RF::init( (double) minV, (double) mavV, 1.0 );
	setAllBins( 1.0 ); normalize();
}

void			RF::setGaussian( double mean, double sigma, double w )
{
	RF::init( mean-4*sigma, mean+4*sigma, w );
	if (getCount()== 0) return;
	double x, sigma2 = sigma*sigma;
	double z = 1.0/sqrt(2*PI)/sigma;
	for( int i=0; i<getCount(); i++) {
		x = getVal( i ) - mean;
		_pdf(i) = z*exp(-x*x/(2*sigma2));
	}
	normalize();
}

void			RF::setPoisson( double lambda )
{
	if( lambda>100 ) error( "SetPoisson(lambda) only works if lambda<=100" );
	if( lambda < 10 )
		init( 0.0, 15.0*lambda, 1.0 );
	else
		init( 0.0, 150.0, 1.0 );

	double factorial=1;
	for (int i=0; i<getCount(); i++) { // overflow a bit after i>150
		_pdf(i) = pow(lambda,(double)i)/(exp(lambda)*factorial);
		factorial *= (double) (i+1);
	}
	normalize();
}

void			RF::set( const vectord &v, double minV, double mavV, double w )
{
	if( minV==mavV ) { minV=0.0; mavV=v.size()-1; }
	init(minV,mavV,w);
	for( size_t i=0; i<v.size(); i++ )
		_pdf(i) = (double) v[i];
	normalize();
}

void			RF::set( const Matrixd &v, double minV, double mavV, double w )
{
	if( minV==mavV ) { minV=0.0; mavV=v.numel()-1; }
	init(minV,mavV,w);
	for( int i=0; i<v.numel(); i++ )
		_pdf(i) = (double) v(i);
	normalize();
}

///////////////////////////////////////////////////////////////////////////////
double			RF::pdf( double x ) const
{
	int index = getIndex(x);
	if( inRange(index) )
		return _pdf(index);
	else
		return 0.0;
}

double			RF::cdf( double x ) const
{
	int index = getIndex(x);
	if( index >= getCount() ) return 1.0;
	if( _cdfCount>0 ) return _cdf( index );
	double cum=0.0;
	for (int j=0; j<=index; j++)
		cum += _pdf(j);
	return cum;
}

double			RF::mean() const
{
	double mean = 0;
	for( int i=0; i<getCount(); i++ )
		mean += _pdf(i)*getVal(i);
	return mean;
}

double			RF::variance() const
{
	double EX = 0.0, EX2 = 0.0, v;
	for( int i=0; i<getCount(); i++ ) {
		v = getVal(i);
		EX += _pdf(i)*v;
		EX2 += _pdf(i)*v*v;
	}
	return (EX2-EX*EX);
}

bool			RF::setCdf(int countPerBin)
{
	if( !normalize() ) return false;
	if( countPerBin<1 ) countPerBin=1;

	_cdfCount = min( 1000000, countPerBin*getCount() );

	// create loopup table
	_cdfLookup.setDims(1,_cdfCount);
	double cumi=0.0; int j=0;
	double cum_del = 1.0 / (double) _cdfCount;
	double cum = cum_del / 10.0;
	for( int i=0; i<getCount(); i++ ) {
		cumi += _pdf(i);
		while ( cum < cumi ) {
			_cdfLookup(j++) = i;
			cum += cum_del;
		}
	}
	assert( j==_cdfCount );

	// create _cdf
	_cdf.setDims(1,getCount());
	_cdf(0) = _pdf(0);
	for (int j=1; j<getCount(); j++)
		_cdf(j) = _cdf(j-1) + _pdf(j);

	return true;
}

double			RF::sampleNonSetCdf(double cumsum) const
{
	if( cumsum==0 ) cumsum=_pdf.sum();
	if( cumsum==0 ) error( "Cannot sample: empty pdf");
	double v=randf()*cumsum, sum=0.0;
	int size = _pdf.numel(); int index;
	for( index=0; index<getCount(); index++) {
		sum += _pdf(index);
		if( sum>=v && _pdf(index)>0.0 )
			break;
	}
	if( index==getCount() )
		return sampleNonSetCdf(); // cumsum invalid
	else
		return getVal( index );
}

///////////////////////////////////////////////////////////////////////////////
void			RF::sample(				Matrixd &B, int rows, int cols ) const
{
	if(_cdfCount==0) error("CDF not set");
	assert(rows>=0 && cols>=0);
	B.setDims( rows, cols );
	for( int r=0; r<rows; r++ )
		for( int c=0; c<cols; c++ )
			B(r,c) = sample();
}

void			RF::sample(				vectord &v, int nSample ) const
{
	if(_cdfCount==0) error("CDF not set");
	assert(nSample>=0);
	v.clear(); v.resize(nSample);
	for( size_t i=0; i<(size_t)nSample; i++ )
		v[i] = sample();
}

void			RF::sampleNonSetCdf(	Matrixd &B, int rows, int cols )
{
	assert(rows>=0 && cols>=0);
	B.setDims( rows, cols );
	for( int r=0; r<rows; r++ )
		for( int c=0; c<cols; c++ )
			B(r,c) = sampleNonSetCdf();
}

void			RF::sampleNonSetCdf(	vectord &v, int nSample )
{
	assert(nSample>=0);
	v.clear(); v.resize(nSample);
	for( size_t i=0; i<(size_t)nSample; i++ )
		v[i] = sampleNonSetCdf();
}

void			RF::sampleNoReplace(	Matrixd &B, int rows, int cols )
{
	assert(rows>=0 && cols>=0);
	RF temp = *this;
	B.setDims( rows, cols );
	for( int r=0; r<rows; r++ )
		for( int c=0; c<cols; c++ ) {
			B(r,c) = temp.sampleNonSetCdf();
			temp.setOneBin( B(r,c), 0.0 );
		}
}

void			RF::sampleNoReplace(	vectord &v, int &nSample )
{
	assert(nSample>=0); v.clear();
	int maxSamples = (int) (_pdf>0).Sum();
	if( nSample>=maxSamples ) {
		nSample=maxSamples;
		for( int index=0; index<getCount(); index++)
			if( _pdf(index)>0.0 )
				v.push_back( getVal(index) );
	} else {
		v.resize(nSample);
		RF tmp = *this;
		double cumsum = tmp._pdf.Sum(), v1; int ind;
		for( size_t i=0; i<(size_t)nSample; i++ ) {
			v1 = tmp.sampleNonSetCdf(cumsum);
			v[i] = v1;
			ind = getIndex(v1);
			cumsum -= tmp._pdf( ind );
			tmp._pdf( ind ) = 0.0;
		}
	}
}
