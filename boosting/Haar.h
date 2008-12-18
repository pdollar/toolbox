#ifndef _HAAR_H_
#define _HAAR_H_

#include "Public.h"
#include "Savable.h"
#include "Matrix.h"
#include "IntegralImage.h"

class Haar; class Rect;
typedef vector<Haar> VecHaar;
typedef vector< Rect > VecRect;

//// SAMPLE CODE
//// 1) create an integral image
//Matrixf I; I.Load( "C:/code/pbt/public/I.tif" ); 
//IntegralImage II; II.prepare( I, true );
//
//// 2) single Haar feature and it application to image
//Haar h; h.createSyst( 4, 50, 50, 9, 9, 0, 0 );
//ColorImage hI; h.toVisible( hI );
//hI.Scale().Save( "C:/code/pbt/h.tif" ); 
//Matrixf resp; h.convHaar( resp, II, 1, false );
//resp.Scale().Save( "C:/code/pbt/R.tif" ); 
//
//// 3) visualize simple Haars and their application to image
//VecHaar haars; 
//HaarPrm haarPrm; 
//haarPrm._width = haarPrm._height = 50;
//Haar::makeHaarSet( haars, haarPrm );
//cout << haars.size() << endl;
//Haar::saveVisualization( haars, "C:/code/pbt/haars", true );
//for( size_t i=0; i<haars.size(); i++ )
//	cout << (haars[i].getDescr()) << endl;
//Haar::convHaars( "C:/code/pbt/haar", haars, II, 1, false );

/////////////////////////////////////////////////////////////////////////////////
class Rect : public Savable
{
public:
					Rect();
					Rect( int lf, int rt, int tp, int bt );

	// implement Savable
	virtual const char* getCname() const { return "Rect"; };
	virtual void	toObjImg( ObjImg &oi, const char *name ) const;
	virtual void	frmObjImg( const ObjImg &oi, const char *name=NULL );
	virtual bool	customTxt() const { return true; }
	virtual void	toTxt( ofstream &os ) const;
	virtual void	frmTxt( ifstream &is );

	// get/set basic properties
	int				area()		const {return (_rt-_lf+1)*(_bt-_tp+1); };
	int				height()	const {return _bt-_tp+1;};
	int				width()		const {return _rt-_lf+1;};
	bool			isValid()	const;
	void			shift( int jshift, int ishift );
	void			shift( int lfshift, int rtshift, int tpshift, int btshift );
	void			setPos( int lf, int rt, int tp, int bt );

	static void		getUnion( Rect &uRect, const VecRect &rects );

	// comparison (for sort, ect)
	friend int		compare(	const Rect &rect1, const Rect &rect2);
	friend bool		operator==(	const Rect &rect1, const Rect &rect2);
	friend bool		operator<(	const Rect &rect1, const Rect &rect2);

public:
	int				_lf, _rt, _tp, _bt;
	float			_wt;
};

/////////////////////////////////////////////////////////////////////////////////
//// Haars (systematically designed)
//
// Type 0:		// Type 1:		// Type 2:		// Type 3:		// Type 4:
//	_			//  _ _			//  _ _			//  _ _			//  _ _ _
// |+|			// |+| |		// | |+|		// |+|-|		// |-|-|-|
//				// | |-|		// |-| |		// |-|+|		// |-|+|-|
//				//				//				//				// |-|-|-|
//
// Type 5:		// Type 6:		// Type 7:		// Type 8:		// Type 9:
//  _ _			//  _ _ _		//  _ _ _		//  _ _ _ _		//  _ _ _ _
// |-|+|		// |+|-|+|		// |+| |-|		// |+|-|-|+|	// |+| | |-|
//
//
// Type 10:		// Type 11:
//  _ _ _		//  _ _ _		
// | |+| |		// | |+| |		
// |+| |-|		// |-| |+|		
// | |-| |		// | |-| |		

class HaarPrm
{
public:
					HaarPrm();

	string			getDescr();

	void 			writeToStrm( ofstream &strm );

	void 			readFrmStrm( ifstream &strm );

public: // general haar prms
	int				_width;			// [1,inf] region width
	int				_height;		// [1,inf] region height
	int				_minArea;		// [1,inf] smallest valid size of any rectangle for haars
	int				_maxArea;		// [1,inf] largest valid size of any rectangle for haars
	bool			_random;		// [T/F]   generate random/systematic haars

public: // prms for systematicly designed haars only 
	bool			_useType[12];	// [T/F]   which haars to create
	int				_nLocs;			// [1,inf] number of positions (along both axes, may be inf)
	int				_nSizes;		// [1,inf] number of sizes (along both axes)
	float			_minAreaFr;		// [0,1]   minimum size of each Haar as fraction of patch size
	float			_sizeFactor;	// [0,inf] mult. difference between sizes 
	float			_overlap;		// [0,1]   fraction overlap between nearby features 

public: // prms for random haars only
	int				_nRandom;		// [1,inf] maximum number of random haars
	int				_maxRects;		// [1,inf] maximum number of rectangles per haar
	double			_sizeBias;		// [0,inf] bias toward larger rectangles

public: // prms to limit haar positions to central region
	int				_constWd;		// [0,inf] constrain haars to central image region of width=_constWd
	int				_constHt;		// [0,inf] constrain haars to central image region of width=_constHt
	float			_centerDist;	// [0,inf] constrain haars to central image region proportional to haar size
	bool			_elliptical;	// [T/F]   keep features in elliptical/rectangular pattern around center
};

/////////////////////////////////////////////////////////////////////////////////
class Haar : public Savable
{
public:
	// implement Savable
	virtual const char* getCname() const { return "Haar"; };
	virtual void	toObjImg( ObjImg &oi, const char *name ) const;
	virtual void	frmObjImg( const ObjImg &oi, const char *name=NULL );

	// create / alter
    void			createSyst(	int type, int w, int h, int fw, int fh, int tp, int lf, bool flip=false );
	void			moveTo( int tpNew, int lfNew );
	bool			finalize();

	// get info
	int				width()   const		{ return _boundRect.width(); };
	int				height()  const		{ return _boundRect.height(); };
	float			area()	  const		{ return _areaTotal; }
	float			areaPos() const		{ return _areaPos; }
	float			areaNeg() const		{ return _areaNeg; }
	int				getTp()	  const		{ return _boundRect._tp; };
	int				getLf()   const		{ return _boundRect._lf; };
	int				getNumRects() const { return _nRects; };
	VecRect&		getRects()			{ return _rects; };
	string			getDescr() const;

	// comparison (for sort, ect)
	friend int		compare(	const Haar &haar1, const Haar &haar2);
	friend bool		operator==(	const Haar &haar1, const Haar &haar2);
	friend bool		operator<(	const Haar &haar1, const Haar &haar2);

	// convolve w entire image
	void			convHaar( Matrixf &resp, IntegralImage &II, int moment, bool normalize );
	void			convHaarHist( Matrixf &resp, IntegralImage *IIs, int nImages, bool normalize );

	// compute haars
	float			compResp1(		const IntegralImage &II, bool normalize ) const;
	float			compResp2(		const IntegralImage &II, bool normalize ) const;
	float			compHistDist(	const IntegralImage *IIs,  const int nImages, bool normalize ) const;
	float			compHistDist(	const IntegralImage **IIs, const int nImages, bool normalize ) const;

	// make set of Haars
	static void		makeHaarSet( VecHaar &haars, HaarPrm &haarPrm );
	static void		freeDistant( VecHaar &haars, HaarPrm &haarPrm );
	static void		unique(		 VecHaar &haars  );

protected:
	void			createRects( int n );
	static int		minWidth( int type );
	static int		minHeight( int type );

protected: // define Haar
	int				_nRects;
	VecRect			_rects;

protected: // cached for speed
	Rect			_boundRect;
	float			_areaPos;
	float			_areaNeg;
	float			_areaPosInv;
	float			_areaNegInv;
	float			_areaTotal;
};

/////////////////////////////////////////////////////////////////////////////////
inline float		Haar::compResp1(	const IntegralImage &II, bool normalize ) const
{
	float sum=0.0f; int l,r,t,b;
	for( int i=0; i<_nRects; i++) {
		l = _rects[i]._lf;  t=_rects[i]._tp; 
		r = _rects[i]._rt;  b=_rects[i]._bt;
		sum += _rects[i]._wt * (float) II.rectSum(l,t,r,b);
	}

	if( normalize ) {
		// SUM(xi') = SUM( (xi-mu)/sigma ) = (SUM(xi) - area*mu)/sigma
		float mu = (float) II.getRoiMu();
		float sigmaInv = (float) II.getRoiSigInv();
		sum = (sum - (_areaPos-_areaNeg) * mu) * sigmaInv;
	} 
	return sum;
}

inline float		Haar::compResp2(	const IntegralImage &II, bool normalize ) const
{
	float sumPos, sumNeg, sumSqPos, sumSqNeg; int l,r,t,b;
	sumPos = sumNeg = sumSqPos = sumSqNeg=0.0f;
	for( int i=0; i<_nRects; i++) {
		l = _rects[i]._lf;  t=_rects[i]._tp; 
		r = _rects[i]._rt;  b=_rects[i]._bt;
		float weight = _rects[i]._wt;
		if( weight > 0  ) {
			sumPos   += weight * (float) II.rectSum(l,t,r,b);
			sumSqPos += weight * (float) II.rectSumSq(l,t,r,b);
		} else {
			sumNeg   -= weight * (float) II.rectSum(l,t,r,b);
			sumSqNeg -= weight * (float) II.rectSumSq(l,t,r,b);
		}
	}

	if( normalize ) {
		// SUM(xi'^2) = SUM( (xi-mu)^2/sigma^2 ) = (SUM(xi^2)-2*mu*SUM(xi) + mu^2*area) / sigma^2
		// SUM(xi') = SUM( (xi-mu)/sigma ) = (SUM(xi) - area*mu)/sigma
		float mu = (float) II.getRoiMu();
		float sigmaInv = (float) II.getRoiSigInv();
		sumSqPos = (sumSqPos -2.0f*sumPos*mu + mu*mu*_areaPos) * sigmaInv * sigmaInv;
		sumPos = (sumPos - _areaPos * mu) * sigmaInv;
		if( _areaNeg > 0 ) {
		sumSqNeg = (sumSqNeg -2.0f*sumNeg*mu + mu*mu*_areaNeg) * sigmaInv * sigmaInv;
		sumNeg = (sumNeg - _areaNeg * mu) * sigmaInv;
		}
	}

	sumPos *= _areaPosInv; sumSqPos *= _areaPosInv; 
	float stdPos = sumSqPos - sumPos*sumPos;
	//stdPos = sqrt(max(stdPos, 0.0));
	if( _areaNeg==0 ) return stdPos;

	sumNeg *= _areaNegInv; sumSqNeg *= _areaNegInv; 
	float stdNeg = sumSqNeg - sumNeg*sumNeg;
	//stdNeg = sqrt(max(stdNeg, 0.0));
	return (stdPos - stdNeg);
}

inline float		Haar::compHistDist(	const IntegralImage *IIs,  const int nImages, bool normalize ) const
{
	int l,r,t,b; int i, j; float mu, sigmaInv; float dist=0.0f;
	if( _areaNeg>0 ) {
		for( j=0; j<nImages; j++ ) {
			float sumPos, sumNeg; sumPos = sumNeg = 0.0f;
			for( i=0; i<_nRects; i++ ) {
				l = _rects[i]._lf;  t=_rects[i]._tp;
				r = _rects[i]._rt;  b=_rects[i]._bt;
				float weight = _rects[i]._wt;
				if( weight > 0  )
					sumPos   += weight * (float) IIs[j].rectSum(l,t,r,b);
				else
					sumNeg   -= weight * (float) IIs[j].rectSum(l,t,r,b);
			}
			if( normalize ) {
				mu = (float) IIs[j].getRoiMu(); sigmaInv = (float) IIs[j].getRoiSigInv();
				sumPos = (sumPos - _areaPos* mu) * sigmaInv;
				sumNeg = (sumNeg - _areaNeg* mu) * sigmaInv;
			}
			sumPos *= _areaPosInv; sumNeg *= _areaNegInv;
			float d = sumPos-sumNeg; d *= d; dist += d;
		}
	} else {
		for( j=0; j<nImages; j++ ) {
			float sumPos = 0.0f;
			for( i=0; i<_nRects; i++ ) {
				l = _rects[i]._lf;  t=_rects[i]._tp; 
				r = _rects[i]._rt;  b=_rects[i]._bt;
				sumPos   += _rects[i]._wt * (float) IIs[j].rectSum(l,t,r,b);
			}
			if( normalize ) {
				mu = (float) IIs[j].getRoiMu(); sigmaInv = (float) IIs[j].getRoiSigInv();
				sumPos = (sumPos - _areaPos* mu) * sigmaInv;
			}
			sumPos *= _areaPosInv;
			dist += sumPos*sumPos;
		}
	}
	return dist;
}

inline float		Haar::compHistDist(	const IntegralImage **IIs, const int nImages, bool normalize ) const 
{
	int l,r,t,b; int i, j; float mu, sigmaInv; float dist=0.0f;
	if( _areaNeg>0 ) {
		for( j=0; j<nImages; j++ ) {
			float sumPos, sumNeg; sumPos = sumNeg = 0.0f;
			for( i=0; i<_nRects; i++ ) {
				l = _rects[i]._lf;  t=_rects[i]._tp;
				r = _rects[i]._rt;  b=_rects[i]._bt;
				float weight = _rects[i]._wt;
				if( weight > 0  )
					sumPos   += weight * (float) IIs[j]->rectSum(l,t,r,b);
				else
					sumNeg   -= weight * (float) IIs[j]->rectSum(l,t,r,b);
			}
			if( normalize ) {
				mu = (float) IIs[j]->getRoiMu(); sigmaInv = (float) IIs[j]->getRoiSigInv();
				sumPos = (sumPos - _areaPos* mu) * sigmaInv;
				sumNeg = (sumNeg - _areaNeg* mu) * sigmaInv;
			}
			sumPos *= _areaPosInv; sumNeg *= _areaNegInv;
			float d = sumPos-sumNeg; d *= d; dist += d;
		}
	} else {
		for( j=0; j<nImages; j++ ) {
			float sumPos = 0.0f;
			for( i=0; i<_nRects; i++ ) {
				l = _rects[i]._lf;  t=_rects[i]._tp;
				r = _rects[i]._rt;  b=_rects[i]._bt;
				sumPos   += _rects[i]._wt * (float) IIs[j]->rectSum(l,t,r,b);
			}
			if( normalize ) {
				mu = (float) IIs[j]->getRoiMu(); sigmaInv = (float) IIs[j]->getRoiSigInv();
				sumPos = (sumPos - _areaPos* mu) * sigmaInv;
			} 
			sumPos *= _areaPosInv;
			dist += sumPos*sumPos;
		}
	}
	return dist;
}

#endif
