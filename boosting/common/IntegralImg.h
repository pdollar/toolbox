/**************************************************************************
* Integral Image for fast computation of Haar features (see Haar.h).
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
**************************************************************************/
#ifndef _ITEGRALIMG_H_
#define _ITEGRALIMG_H_

#include "Matrix.h"

class IntegralImg
{
public:
	IntegralImg() { clear(); };

	~IntegralImg() { clear(); };

	void	clear();

	bool	prepared() { return _II.numel()>0; }

	template<class T> void prepare( const Matrix<T> &I );

	void	setRoi( int lf, int tp, int rt, int bt );

	void	getRoi( int &lf, int &tp, int &rt, int &bt );

	double	getRoiMu() const { return _roiMu; }

	double	getRoiSig() const { return _roiSig; }

	double	getRoiSigInv() const { return _roiSigInv; }

	int		height() const {return _h-1;};

	int		width() const {return _w-1;};

	double	rectSum(		int lf, int tp, int rt, int bt ) const;

	double	rectSumSq(		int lf, int tp, int rt, int bt ) const;

public:
	int		_roiLf, _roiTp, _roiRt, _roiBt;
	double	_roiMu, _roiSig, _roiSigInv;
	int		_h, _w;
	Matrixd	_II, _sqrII;
};

inline void				IntegralImg::clear()
{
	_II.clear(); _sqrII.clear();
	_w = _h = _roiLf = _roiTp = _roiRt = _roiBt = 0;
	_roiMu = 0.0; _roiSig = 1.0; _roiSigInv = 1.0;
}

inline void				IntegralImg::setRoi(		int lf, int tp, int rt, int bt )
{
	if( _roiLf==lf && _roiTp==tp && _roiRt==rt && _roiBt==bt ) return;
	_roiLf	= _roiTp = 0;
	double areaInv = 1.0/double((rt-lf+1)*(bt-tp+1));
	double m1 = rectSum(lf, tp, rt, bt) * areaInv;
	double m2 = rectSumSq(lf, tp, rt, bt) * areaInv;
	_roiMu = m1;
	_roiSig = sqrt(max(m2 - m1 * m1, 0.0)) + .000001;
	_roiSigInv = 1.0/_roiSig;
	_roiLf=lf; _roiTp=tp; _roiRt=rt; _roiBt=bt;
}

inline void				IntegralImg::getRoi(		int &lf, int &tp, int &rt, int &bt )
{
	lf=_roiLf; tp=_roiTp; rt=_roiRt; bt=_roiBt;
}

inline double			IntegralImg::rectSum(		int lf, int tp, int rt, int bt ) const
{
	lf+=_roiLf; rt+=_roiLf+1; tp+=_roiTp; bt+=_roiTp+1;
	ifdebug( assert( tp>=0 && lf>=0 && bt<_h && rt<_w && tp<bt && lf<rt ) );
	return (_II(tp, lf) + _II(bt, rt) - _II(tp, rt) - _II(bt, lf));
}

inline double			IntegralImg::rectSumSq(	int lf, int tp, int rt, int bt ) const
{
	lf+=_roiLf; rt+=_roiLf+1; tp+=_roiTp; bt+=_roiTp+1;
	ifdebug( assert( tp>=0 && lf>=0 && bt<_h && rt<_w && tp<bt && lf<rt ) );
	return (_sqrII(tp, lf) + _sqrII(bt, rt) - _sqrII(tp, rt) - _sqrII(bt, lf));
}

template<class T> void	IntegralImg::prepare( const Matrix<T> &I )
{
	double v; int i, j;
	_w = I.cols() + 1;
	_h = I.rows() + 1;
	_II.setDims( _h, _w ); _sqrII.setDims( _h, _w );

	// 1) set first row/column to II to be 0
	for( i = 0; i < _w; i++) _II(0, i) = _sqrII(0, i) = 0;
	for( j = 0; j < _h; j++) _II(j, 0) = _sqrII(j, 0) = 0;

	// 2) create first real row/column of II
	v = I(0,0); _II(1,1)=v; _sqrII(1,1)=v*v;
	for( i = 2; i < _w; i++) {
		v = I(0, i-1);
		_II(1, i) = _II(1, i-1) + v;
		_sqrII(1, i) = _sqrII(1, i-1) + v*v;
	}
	for( j = 2; j < _h; j++) {
		v = I(j-1, 0);
		_II(j, 1) = _II(j-1, 1) + v;
		_sqrII(j, 1) = _sqrII(j-1, 1) + v*v;
	}

	// 3) create remainder of II
	for( j = 2; j < _h; j++) for( i = 2; i < _w; i++) {
		v = I(j-1, i-1);
		_II(j, i) = _II(j-1, i) + _II(j, i-1) - _II(j-1, i-1) + v;
		_sqrII(j, i) = _sqrII(j-1, i) + _sqrII(j, i-1) - _sqrII(j-1, i-1) + v*v;
	}
}

#endif
