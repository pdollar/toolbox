#ifndef _HAAR_FEATURES_H_
#define _HAAR_FEATURES_H_

#include "Public.h"
#include "Matrix.h"
#include "Rect.h"
#include "IntegralImage.h"

class Haar;
typedef vector<Haar> VecHaar;

//// SAMPLE CODE:
//// 1) create an integral image
//Matrixf I; I.Load( "C:/code/pbt/public/I.tif" ); 
//IntegralImage II; II.prepare( I, true );
//
//// 2) single Haar feature and it application to image
//Haar h; h.createSyst( 4, 50, 50, 9, 9, 0, 0 );
//ColorImage hI; h.toVisible( hI );
//hI.Scale().Save( "C:/code/pbt/h.tif" ); 
//Matrixf resp; h.compImageResp( resp, II, 1, false );
//resp.Scale().Save( "C:/code/pbt/R.tif" ); 
//
//// 3) visualize simple Haars and their application to image
//VecHaar haars; 
//HaarSetPrm haarSetPrm; 
//haarSetPrm._width = haarSetPrm._height = 50;
//Haar::makeHaarSet( haars, haarSetPrm );
//cout << haars.size() << endl;
//Haar::saveVisualization( haars, "C:/code/pbt/haars", true );
//for( size_t i=0; i<haars.size(); i++ )
//	cout << (haars[i].getDescr()) << endl;
//Haar::compImageResps( "C:/code/pbt/haar", haars, II, 1, false );


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

class HaarSetPrm
{
public:
					HaarSetPrm();

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
class Haar
{
public:
	void 			writeToStrm( ofstream &strm );
	void 			readFrmStrm( ifstream &strm );

	// create / alter:
    void			createSyst(	int type, int w, int h, int fw, int fh, int tp, int lf, bool flip=false );
	void			moveTo( int tpNew, int lfNew );
	bool			finalize();

	// get info:
	int				height()  const		{ return _boundRect.height(); };
	int				width()   const		{ return _boundRect.width(); };
	float			area()	  const		{ return _areaTotal; }
	float			areaPos() const		{ return _areaPos; }
	float			areaNeg() const		{ return _areaNeg; }
	int				getTp()	  const		{ return _boundRect.getTp(); };
	int				getLf()   const		{ return _boundRect.getLf(); };
	int&			iwidth()			{ return _iwidth; };
	int&			iheight()			{ return _iheight; };
	int				getNumRects() const { return _nRects; };
	VecRect&		getRects()			{ return _rects; };
	string			getDescr() const;

	// comparison (for sort, ect):
	friend int		compare(	const Haar &haar1, const Haar &haar2);
	friend bool		operator==(	const Haar &haar1, const Haar &haar2);
	friend bool		operator<(	const Haar &haar1, const Haar &haar2);

	// visualization:
	void			compImageResp( Matrixf &resp, IntegralImage &II, int moment, bool normalize );
	void			compImageHistDist( Matrixf &resp, IntegralImage *IIs, int nImages, bool normalize );

	// compute haars:
	float			compResp1(		const IntegralImage &II, bool normalize ) const;
	float			compResp2(		const IntegralImage &II, bool normalize ) const;
	float			compHistDist(	const IntegralImage *IIs,  const int nImages, bool normalize ) const;
	float			compHistDist(	const IntegralImage **IIs, const int nImages, bool normalize ) const;

	// make set of Haars:
	static void		makeHaarSet( VecHaar &haars, HaarSetPrm &haarSetPrm );
	static void		freeDistant( VecHaar &haars, HaarSetPrm &haarSetPrm );
	static void		unique(		 VecHaar &haars  );

protected:
	void			createRects( int n );
	static int		minWidth( int type );
	static int		minHeight( int type );

protected:
	int				_iwidth;
	int				_iheight;
	int				_minArea;
	int				_maxArea;
	int				_nRects;
	VecRect			_rects;

	Rect			_boundRect;
	float			_areaPos;
	float			_areaNeg;
	float			_areaPosInv;
	float			_areaNegInv;
	float			_areaTotal;
};

inline float		Haar::compResp1(	const IntegralImage &II, bool normalize ) const
{
	float sum=0.0f; int l,r,t,b;
	for( int i=0; i<_nRects; i++) {
		l = _rects[i].getLf();  t=_rects[i].getTp(); 
		r = _rects[i].getRt();  b=_rects[i].getBt();
		sum += _rects[i].getWeight() * (float) II.rectSum(l,t,r,b);
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
		l = _rects[i].getLf();  t=_rects[i].getTp(); 
		r = _rects[i].getRt();  b=_rects[i].getBt();
		float weight = _rects[i].getWeight();
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
				l = _rects[i].getLf();  t=_rects[i].getTp();
				r = _rects[i].getRt();  b=_rects[i].getBt();
				float weight = _rects[i].getWeight();
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
				l = _rects[i].getLf();  t=_rects[i].getTp(); 
				r = _rects[i].getRt();  b=_rects[i].getBt();
				sumPos   += _rects[i].getWeight() * (float) IIs[j].rectSum(l,t,r,b);
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
				l = _rects[i].getLf();  t=_rects[i].getTp();
				r = _rects[i].getRt();  b=_rects[i].getBt();
				float weight = _rects[i].getWeight();
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
				l = _rects[i].getLf();  t=_rects[i].getTp();
				r = _rects[i].getRt();  b=_rects[i].getBt();
				sumPos   += _rects[i].getWeight() * (float) IIs[j]->rectSum(l,t,r,b);
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