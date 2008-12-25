/**************************************************************************
* Random number generators (and RF for arbitrary distributions).
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
**************************************************************************/
#ifndef RAND_H
#define RAND_H

#include "Common.h"
#include "Matrix.h"
#include "Savable.h"

// Uniform [0,1) random float generator
float	randf();

// Uniform [minV,mavV] random integer generator
int		randi( int minV=0, int mavV=1 );

// Gaussian random number generator
double	randgauss( double mean=0, double sig=1 );

// returns random permuation of integers 0 to n-1; if k given only returns first k elts
void	randperm( vectori &p, int n, int k=-1 );

// n samples from d-dimensional gaussian with given mean/sig per d (V is nxd)
void	sampleGaussian( Matrixd &V, int d, int n, double w, double *mean, double *sig );

// n samples from d-dimensional uniform distribution with given ranges per d (V is nxd)
void	sampleUniform( Matrixd &V, int d, int n, double w, double *minV, double *maxV );

/**************************************************************************
* Random Field (generating random samples from an arbitrary distribution)
* _pdf is the probibility distribution. To get the probability of some value x, first need to
* convert x into an ind into the _pdf. For this _minV (value first bin in _pdf corresponds to)
* and _w (the width between successive bins in the _pdf) are used (see getInd(x)).
* Note: bin 0 includes all values x such that: (_minV-w/2 <= x < _minV+_w/2)
* getInd(x) returns the ind of the nearest bin to x. Conversely getVal(ind) returns
* the value at the corresponding bin. Note that getVal(getInd(x))!=x because of rounding.
* For sampling efficiency (generating random values based on the distribution), one can precompute
* the cumulative distribution using setCdf(). _cdfInd(V), where 0<=V<=1, gives the ind at which the _pdf
* has a cumulative value of V. This ind is than easily converted into a sample x. Drawing a
* sample by uniformly generating V and following the procedure above is equivalent to sampling
* from the original probability distribution.
* Example: generate 100 samples from a mean=0/var=1 Gaussian:
* RF R; R.setGaussian(0,1,.001); R.setCdf(); Matrixd V; R.sample(V,100,1);
* cout <<V<<endl <<"mu="<<V.mean() <<" var="<<V.variance() << endl;
**************************************************************************/
class RF : public Savable
{
public:
	// implement Savable
	virtual const char*		getCname() const { return "RF"; };
	virtual void			toObjImg( ObjImg &oi, const char *name ) const;
	virtual void			frmObjImg( const ObjImg &oi, const char *name=NULL );

	// create/alter RF (w determines granularity of sampling; ie w==1 only samples integers)
	void					init( double minV, double mavV, double w );
	void					normalize();
	void					setUniform( double minV, double mavV, double w );
	void					setUniformInt( int minV, int mavV );
	void					setGaussian( double mean=0, double sig=1, double w=.01 );
	void					setPoisson( double lambda );
	void					set( const vectord &v, double minV=0, double mavV=0, double w=1 );
	void					set( const Matrixd &v, double minV=0, double mavV=0, double w=1 );
	Matrixd&				getPdf() { return _pdf; }

	// access (ind refers to the location that a value x would fall in _pdf)
	int						getCnt()				const { return _pdf.cols(); };
	int						getInd( double x )		const { return int((x-_minV)*_wInv+.5); }
	double					getVal( int ind )		const { return _minV+_w*ind; };
	bool					inRange( int ind )		const { return (ind>=0 && ind<getCnt()); };
	double					getInterval()			const { return _w;};
	bool					cdfInit()				const { return _cdfInd.cols()>0; };
	double					minVal()				const { return _minV; };
	double					maxVal()				const { return getVal(getCnt()-1); };
	double					pdf( double x )			const;
	double					cdf( double x )			const;
	double					mean()					const;
	double					variance()				const;

	// sample distribution (call setCdf() before using sample())
	void					setCdf( int cntPerBin=100 );
	void					clearCdf() { _cdf.clear(); _cdfInd.clear(); };
	double					sample() const;
	double					sampleNonSetCdf( double cumsum=0 ) const;
	void					sample(				Matrixd &V, int rows, int cols ) const;
	void					sample(				vectord &v, int n ) const;
	void					sampleNoReplace(	Matrixd &V, int rows, int cols );
	void					sampleNoReplace(	vectord &v, int &n );

private:
	// probability density function (pdf) and cumulative density function (cdf)
	double					_minV;
	double					_w;
	double					_wInv;
	Matrixd					_pdf;
	Matrixd					_cdf;
	Matrixi					_cdfInd;
};

inline double			RF::sample() const
{
	if(!cdfInit()) error("CDF not set");
	int ind = int(randf()*_cdfInd.cols());
	return getVal( _cdfInd(ind) );
}

#endif
