#ifndef RAND_H
#define RAND_H

#include "Common.h"
#include "Matrix.h"

// Uniform [0,1) random number generator
float					randf();

// Uniform [minV,mavV] random integer generator
int						randi( int minV=0, int mavV=1 );

// Gaussian random number generator
double					randgauss( double mean=0.0, double sigma=1.0 );

// returns random permuation of integers 0 through n-1; if k is specified only returns first k elts
void					randperm( vectori &p, int n, int k=-1 );

// n samples from d-dimensional gaussian with given mean/std per d (V is nxd)
void					sampleGaussian( Matrixd &V, double *mean, double *std, int d, int n, double w );

// n samples from d-dimensional uniform distribution with given ranges per d (V is nxd)
void					sampleUniform( Matrixd &V, double *minVs, double *maxVs, int d, int n, double w );

/**
* Random Field (generating random samples from an arbitrary distribution)
* SAMPLE USAGE (generate a 100x100 set of samples from a mean=0,var=1 Gaussian):
* RF R; R.setGaussian( 0, 1, .001 ); R.setCdf(); Matrixd B; R.sample( B, 100, 100 );
* cout << R << "mean=" << B.Mean() << " var=" << B.variance() << endl;
* Rasterd hist, C; C=B; C.Histogram( hist, 20 ); cout << hist;
*/
class RF
{

public:
	//void					writeToStrm(ofstream &strm);

	//void					readFrmStrm(ifstream &strm);

public:
	// create/alter RF (w determines granularity of sampling; ie w==1 only samples integers)
	void					init( double minV, double mavV, double w );

	void					setOneBin( double x, double p );

	void					addToBin( double x, double p );

	void					setAllBins( double p );

	bool					normalize();

	void					setUniform( double minV, double mavV, double w );

	void					setUniformInt( int minV, int mavV );

	void					setGaussian( double mean=0.0, double sigma=1.0, double w=.01 );

	void					setPoisson( double lambda );

	void					set( const vectord &v, double minV=0.0, double mavV=0.0, double w=1.0 );

	void					set( const Matrixd &v, double minV=0.0, double mavV=0.0, double w=1.0 );

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

	void					clearCdf() { _cdfLookup.setDims(0,0); _cdfCount=0; };

	double					sample() const;

	double					sampleNonSetCdf(double cumsum=0) const;

	void					sample(				Matrixd &B, int rows, int cols ) const;

	void					sample(				vectord &v, int nSample ) const;

	void					sampleNonSetCdf(	Matrixd &B, int rows, int cols );

	void					sampleNonSetCdf(	vectord &v, int nSample );

	void					sampleNoReplace(	Matrixd &B, int rows, int cols );

	void					sampleNoReplace(	vectord &v, int &nSample );

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

inline double			RF::sample() const
{
	if( _cdfCount==0 ) return -1.0;
	int index= (int) (randf()*_cdfCount);
	return getVal( _cdfLookup(index) );
}

#endif
