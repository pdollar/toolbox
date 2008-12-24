#ifndef RAND_H
#define RAND_H

#include "Public.h"
#include "Matrix.h"

// Uniform [0,1) random number generator
float					randf();

// Uniform [minV,mavV] random integer generator
int						randi( int minV=0, int mavV=5 );

 // Gaussian random number generator
double					randgauss( double mean=0.0, double sigma=1.0 );

// returns random permuation of integers 0 through n-1; if k is specified only returns first k elts
void					randperm( vectori &permuted, int n, int k=-1 );

// randomly permutes vector
template<class T> void	randperm( vector<T> &v );

// sample d dimensional gaussian with given mean/std 
template<class T> void	sampleGaussian( Matrix<T> &B, double *mean, double *std, int d, int n, double w );

// sample d dimensional uniform distribution with given ranges
template<class T> void	sampleUniform( Matrix<T> &B, double *minVs, double *maxVs, int d, int n, double w );

// sample 2D uniform distribution outside of a rectangle with given ranges
template<class T> void	sampleUniformOutsideRect( Matrix<T> &B, double *minVs, double *maxVs, double *rMinVs, double *rMaxVs, int n, double w );

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

class RF
{
// Random Field (generating random samples from an arbitrary distribution)
// //SAMPLE USAGE (generate a 100x100 set of samples from a mean=0,var=1 Gaussian):
// RF R; R.setGaussian( 0, 1, .001 ); R.setCdf(); Matrixd B; R.sample( B, 100, 100 );
// cout << R << "mean=" << B.Mean() << " var=" << B.variance() << endl;
// Rasterd hist, C; C=B; C.Histogram( hist, 20 ); cout << hist;

public:
	void					writeToStrm(ofstream &strm);

	void					readFrmStrm(ifstream &strm);

	friend ostream&			operator<<(ostream &os, const RF &rf);

public:
	// create/alter RF (w determines granularity of sampling; ie w==1 only samples integers)
	void					init( double minV, double mavV, double w );

	void					setOneBin( double x, double p );

	void					addToBin( double x, double p );

	void					setAllBins( double p );

	bool					normalize();

	void					gaussSmooth( double sigma );

	void					smooth( const Matrixd &kernel1 );

	void					setUniform( double minV, double mavV, double w );

	void					setUniformInt( int minV, int mavV );

	void					setGaussian( double mean=0.0, double sigma=1.0, double w=.01 );

	void					setPoisson( double lambda );

	template<class T> void	set( const vector<T> &v, double minV=0.0, double mavV=0.0, double w=1.0 );

	template<class T> void	set( const Matrix<T> &v, double minV=0.0, double mavV=0.0, double w=1.0 );

public: 
	// inspect properties of RF
	double					pdf( double x) const;

	double					cdf( double x) const;

	double					mean() const;

	double					variance() const;

	double					minVal() const { return _minV; };

	double					maxVal() const { return getVal(getCount()-1); };

public:
	// SAMPLING -- is very fast if we precompute the cdf. However, anytime the  pdf changes need to call 
	// setCdf() again, so in this case it's simply better to use sampleNonSetCdf().  This is the case in 
	// sampling without replacement. In feneral, sample() is significantly faster than sampleNonSetCdf().
	bool					setCdf( int countPerBin=100 );

	void					clearCdf() { _cdfLookup.SetDimension(0,0); _cdfCount=0; };

	double					sample() const;

	double					sampleNonSetCdf(double cumsum=0) const;

	template<class T> void	sample(				Matrix<T> &B, int rows, int cols ) const;

	template<class T> void	sample(				vector<T> &v, int nSample ) const;

	template<class T> void	sampleNonSetCdf(	Matrix<T> &B, int rows, int cols );

	template<class T> void	sampleNonSetCdf(	vector<T> &v, int nSample );

	template<class T> void	sampleNoReplace(	Matrix<T> &B, int rows, int cols );

	template<class T> void	sampleNoReplace(	vector<T> &v, int &nSample );

public:
	// access -- index refers to the location that a value x would fall in _pdf. 
	// Note: bin 0 includes all values x such that: (_minV-w/2 <= x < _minV+_w/2)
	// getIndex(x) returns the index of the nearest bin to x. Conversely getVal(index) returns
	// the value at the corresponding bin. Note that getVal(getIndex(x))!=x because of rounding.
	int						getCount()					const { return _cnt; };

	int						getIndex(const double x)	const { return (int)((x-_minV)*_wInv+.5); }

	double					getVal(const int index)		const { return _minV+_w*index; };

	bool					inRange( const int index)	const { return (index>=0 && index<getCount()); };

	double					getInterval()				const { return _w;};

	bool					cdfInitialized()			const { return _cdfCount>0; };

public:
	// _pdf is the probibility distribution. To get the probability of some value x, first need to
	// convert x into an index into the _pdf. For this _minV (value first bin in _pdf corresponds to)
	// and _intev (the w between successive bins in the _pdf) are used (see Index(x)). 
	Matrixd					_pdf;
	Matrixd					_cdf;

private:
	// _cnt gives the number of bins in _pdf.  _minV is the value corersponding to first bin of pdf.
	// For sampling efficiency (generating random values based on the distribution), one can precompute 
	// the cumulative distribution. _cdfLookup(V), where 0<=V<=1, gives the index at which the _pdf 
	// has a cumulative value of V. This index is than easily converted into a sample x. Drawing a 
	// sample by uniformly generating V and following the procedure above is equivalent to sampling 
	// from the original probability distribution.  _cdfCount==0 indicates _cdfLookup not initialized.
	int						_cnt;
	double					_minV;
	double					_w;
	double					_wInv;
	Matrixi					_cdfLookup;
	int						_cdfCount;
};

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

inline double			RF::sample() const
{
	if( _cdfCount==0 ) return -1.0;
	int index= (int) (randf()*_cdfCount);
	return getVal( _cdfLookup(index) );
}

template<class T> void	RF::sample(				Matrix<T> &B, int rows, int cols ) const
{
	if(_cdfCount==0) abortError( "CDF not set", __LINE__, __FILE__ );
	assert(rows>=0 && cols>=0);
	B.SetDimension( rows, cols );
	for( int r=0; r<rows; r++ )
		for( int c=0; c<cols; c++ )
			B(r,c) = (T) sample();
}

template<class T> void	RF::sample(				vector<T> &v, int nSample ) const
{
	if(_cdfCount==0) abortError( "CDF not set", __LINE__, __FILE__ );
	assert(nSample>=0);
	v.clear(); v.resize(nSample);
	for( size_t i=0; i<(size_t)nSample; i++ )
		v[i] = (T) sample();
}

template<class T> void	RF::sampleNonSetCdf(	Matrix<T> &B, int rows, int cols )
{
	assert(rows>=0 && cols>=0);
	B.SetDimension( rows, cols );
	for( int r=0; r<rows; r++ )
		for( int c=0; c<cols; c++ )
			B(r,c) = (T) sampleNonSetCdf();
}

template<class T> void	RF::sampleNonSetCdf(	vector<T> &v, int nSample )
{
	assert(nSample>=0);
	v.clear(); v.resize(nSample);
	for( size_t i=0; i<(size_t)nSample; i++ )
		v[i] = (T) sampleNonSetCdf();
}

template<class T> void	RF::sampleNoReplace(	Matrix<T> &B, int rows, int cols )
{
	assert(rows>=0 && cols>=0);
	RF temp = *this;
	B.SetDimension( rows, cols );
	for( int r=0; r<rows; r++ )
		for( int c=0; c<cols; c++ ) {
			B(r,c) = (T) temp.sampleNonSetCdf();
			temp.setOneBin( B(r,c), 0.0 );
		}
}

template<class T> void	RF::sampleNoReplace(	vector<T> &v, int &nSample )
{
	assert(nSample>=0); v.clear(); 
	int maxSamples = (int) (_pdf>0).Sum();
	if( nSample>=maxSamples ) {
		nSample=maxSamples;
		for( int index=0; index<getCount(); index++)
			if( _pdf(index)>0.0 ) 
				v.push_back( (T) getVal(index) );
	} else {
		v.resize(nSample);
		RF tmp = *this;
		double cumsum = tmp._pdf.Sum(), v1; int ind;
		for( size_t i=0; i<(size_t)nSample; i++ ) {
			v1 = tmp.sampleNonSetCdf(cumsum);
			v[i] = (T) v1;
			ind = getIndex(v1);
			cumsum -= tmp._pdf( ind );
			tmp._pdf( ind ) = 0.0;
		}
	}
}

template<class T> void	RF::set( const vector<T> &v, double minV, double mavV, double w )
{
	if( minV==mavV ) { minV=0.0; mavV=v.size()-1; }
	init(minV,mavV,w);
	for( size_t i=0; i<v.size(); i++ )
		_pdf(i) = (double) v[i];
	normalize();
}

template<class T> void	RF::set( const Matrix<T> &v, double minV, double mavV, double w )
{
	if( minV==mavV ) { minV=0.0; mavV=v.size()-1; }
	init(minV,mavV,w);
	for( int i=0; i<v.size(); i++ )
		_pdf(i) = (double) v(i);
	normalize();
}

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

template<class T> void	randperm( vector<T> &v )
{
	vectori order; randperm(order,v.size()); reorder<T>(v,order);
}

template<class T> void	sampleGaussian( Matrix<T> &B, double *mean, double *std, int d, int n, double w )
{
	RF rf; Matrixf B1, B2; B.SetDimension( n, 0 );
	for( int i=0; i<d; i++ ) {
		rf.setGaussian(mean[i],std[i],w); rf.setCdf(); 
		rf.sample( B1, n, 1 ); B.AppendRight( B1, B2 ); B = B2;
	}
}

template<class T> void	sampleUniform( Matrix<T> &B, double *minVs, double *maxVs, int d, int n, double w )
{
	RF rf; Matrix<T> B1, B2; B.SetDimension( n, 0 );
	for( int i=0; i<d; i++ ) {
		rf.setUniform(minVs[i],maxVs[i],w); rf.setCdf(); 
		rf.sample( B1, n, 1 ); B.AppendRight( B1, B2 ); B = B2;
	}
}

template<class T> void	sampleUniformOutsideRect( Matrix<T> &B, double *minVs, double *maxVs, double *rMinVs, double *rMaxVs, int n, double w )
{
	double totArea = (maxVs[0]-minVs[0])*(maxVs[1]-minVs[1]);
	double boxArea = (rMaxVs[0]-rMinVs[0])*(rMaxVs[1]-rMinVs[1]);
	double sArea = totArea-boxArea;
	double A1, A2;
	A1 = (maxVs[0]-minVs[0])*(rMinVs[1]-minVs[1]);
	A2 = (rMinVs[0]-minVs[0])*(rMaxVs[1]-rMinVs[1]);

	int n1 = (int) (n*A1/sArea);
	int n2 = (int) (n*A2/sArea);
	
	double tminVs[2], tmaxVs[2];
	Matrix<T> B1, B2, B3;

	tminVs[0] = minVs[0]; tminVs[1] = minVs[1];
	tmaxVs[0] = maxVs[0]; tmaxVs[1] = rMinVs[1];
	sampleUniform( B1, tminVs, tmaxVs, 2, n1, w );

	tminVs[0] = minVs[0]; tminVs[1] = rMaxVs[1];
	tmaxVs[0] = maxVs[0]; tmaxVs[1] = maxVs[1];
	sampleUniform( B2, tminVs, tmaxVs, 2, n1, w );

	B1.AppendBelow( B2, B3 );

	tminVs[0] = minVs[0]; tminVs[1] = rMinVs[1];
	tmaxVs[0] = rMinVs[0]; tmaxVs[1] = rMaxVs[1];
	sampleUniform( B1, tminVs, tmaxVs, 2, n2, w );

	B3.AppendBelow( B1, B2 );

	tminVs[0] = rMaxVs[0]; tminVs[1] = rMinVs[1];
	tmaxVs[0] = maxVs[0]; tmaxVs[1] = rMaxVs[1];
	sampleUniform( B1, tminVs, tmaxVs, 2, n2, w );

	B2.AppendBelow( B1, B3 );
	B = B3;
	
}

#endif