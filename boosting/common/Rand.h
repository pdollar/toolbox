/**************************************************************************
* Random number generators (use RF for arbitrary distributions).
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

// Uniform [0,1) random float generator (from Numerical Recipes in C)
float	randf();

// Uniform [minV,mavV] random integer generator
int		randi( int minV=0, int mavV=1 );

// Gaussian random number generator
double	randgauss( double mean=0, double sig=1 );

// Random permuation of integers 0 to n-1; if k>0 only returns first k elts
void	randperm( vectori &p, int n, int k=-1 );

// n samples from d-dimensional gaussian with given mean/sig per d (V is nxd)
void	sampleGaussian( Matrixd &V, int d, int n, double w, double *mean, double *sig );

// n samples from d-dimensional uniform distribution with given ranges per d (V is nxd)
void	sampleUniform( Matrixd &V, int d, int n, double w, double *minV, double *maxV );

/**************************************************************************
* Random Field (RF) is used to generate random samples from an arbitrary
* probability distribution. A RF is basically a histogram that represents
* an arbitrary probability density function (pdf). The histogram is stored
* as a vector _pdf, along with the real value corresponding to the first
* bin (_minV) and the real width of a bin (_w). To convert between real
* values and bin indices use ind=getInd(x) and x=getVal(ind). Note that
* bin 0 includes all x such that _minV-w/2 <= x < _minV+_w/2, and that
* getVal(getInd(x))!=x because of rounding.
*
* Sampling a random value according to the pdf can be performed directly
* using sampleNonSetCdf() (inefficient) or after precomputing the cdf using
* sample() (fast).  The call setCdf() precomputes both the cumulative
* density function (cdf), where _cdf(ind)=sum(_pdf(1:ind)), and the inverse
* mapping _cdfInd s.t. ind=_cdfInd(_cdf(ind)). Using the inverse mapping
* and a random value f drawn uniformly from [0,1], we obtain ind=_cdfInd(f)
* s.t. f=_cdf(ind). So, drawing f and using x=getVal(_cdfInd(f)) is the
* same as drawing x directly from the true pdf up to numerical error. Note
* that if any changes are made to _pdf, the cdf must be recomputed, so if
* _pdf changes frequently use sampleNonSetCdf() instead.
*
* Example usage, generate 100 samples from a mean=0/var=1 Gaussian:
*  RF R; R.setGaussian(0,1,.001); R.setCdf(); Matrixd V; R.sample(V,100,1);
*  cout << "mu=" << V.mean() << " var=" << V.variance() << endl;
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
	void					setUniform( double minV, double mavV, double w=1.0 );
	void					setGaussian( double mean=0, double sig=1, double w=.01 );
	void					setPoisson( double lambda );
	void					set( const vectord &v, double minV=0, double mavV=0, double w=1 );
	void					set( const Matrixd &v, double minV=0, double mavV=0, double w=1 );
	Matrixd&				getPdf() { return _pdf; }

	// access (ind refers to the location that a value x would fall in _pdf)
	int						getCnt()				const { return _pdf.cols(); };
	int						getInd( double x )		const { return int((x-_minV)*_wInv+.5); }
	double					getVal( int ind )		const { return _minV+_w*ind; };
	double					minVal()				const { return _minV; };
	double					maxVal()				const { return getVal(getCnt()-1); };
	bool					cdfInit()				const { return _cdfInv.cols()>0; };
	double					pdf( double x )			const;
	double					cdf( double x )			const;
	double					mean()					const;
	double					variance()				const;

	// sample distribution (call setCdf() before using sample() or use sampleNonSetCdf())
	void					setCdf( int cntPerBin=100 );
	void					clearCdf() { _cdf.clear(); _cdfInv.clear(); };
	double					sample() const;
	double					sampleNonSetCdf( double cumsum=0 ) const;
	void					sample( Matrixd &V, int rows, int cols ) const;
	void					sample( vectord &v, int n ) const;
	void					sampleNoReplace( Matrixd &V, int rows, int cols ) const;
	void					sampleNoReplace( vectord &v, int &n ) const;

private:
	// probability density function (pdf) and cumulative density function (cdf)
	Matrixd					_pdf;
	double					_minV;
	double					_w;
	double					_wInv;
	Matrixd					_cdf;
	Matrixi					_cdfInv;
};

inline double			RF::sample() const
{
	ifdebug(if(!cdfInit()) error("CDF not set"));
	int ind = _cdfInv(int(randf()*_cdfInv.cols()));
	return getVal(ind);
}

#endif
