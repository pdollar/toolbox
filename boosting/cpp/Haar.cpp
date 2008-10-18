#include "Haar.h"
//#include "Rand.h"

void		Haar::writeToStrm( ofstream &strm )
{
	strm.write((char*)&_iwidth,		sizeof(_iwidth));
	strm.write((char*)&_iheight,	sizeof(_iheight));
	strm.write((char*)&_minArea,	sizeof(_minArea));
	strm.write((char*)&_maxArea,	sizeof(_maxArea));
	strm.write((char*)&_nRects,		sizeof(_nRects));
	for( int i=0; i<_nRects; i++ )
		_rects[i].writeToStrm(strm);
}

void		Haar::readFrmStrm( ifstream &strm )
{
	strm.read((char*)&_iwidth,		sizeof(_iwidth));
	strm.read((char*)&_iheight,		sizeof(_iheight));
	strm.read((char*)&_minArea,		sizeof(_minArea));
	strm.read((char*)&_maxArea,		sizeof(_maxArea));
	strm.read((char*)&_nRects,		sizeof(_nRects));
	createRects(_nRects);
	for( int i=0; i<_nRects; i++ )
		_rects[i].readFrmStrm(strm);
	bool valid=finalize(); assert(valid);
}

bool		operator==(	const Haar &h1, const Haar &h2)
{
	if( h1._nRects!=h2._nRects ) 
		return false;
	for( int i=0; i<h1._nRects; i++ )
		if( !(h1._rects[i]==h2._rects[i]) )
			return false;
	if (h1._iwidth!=h2._iwidth || h1._iheight!=h2._iheight ||
		h1._minArea!=h2._minArea || h1._maxArea!=h2._maxArea)
		return false;
	else
		return true;
}

int			compare(	const Haar &h1, const Haar &h2)
{
	if(      h1._nRects < h2._nRects )
		return -1;
	else if( h1._nRects > h2._nRects ) 
		return 1;

	for( int i=0; i<h1._nRects; i++ ) {
		int comp = compare(h1._rects[i],h2._rects[i]);
		if( comp!=0 ) return comp;
	}

	if(      h1._iwidth < h2._iwidth )
		return -1;
	else if( h1._iwidth > h2._iwidth )
		return 1;
	else if( h1._iheight < h2._iheight )
		return -1;
	else if( h1._iheight > h2._iheight )
		return 1;
	else if( h1._minArea < h2._minArea )
		return -1;
	else if( h1._minArea > h2._minArea )
		return 1;
	else if( h1._maxArea < h2._maxArea )
		return -1;
	else if( h1._maxArea > h2._maxArea )
		return 1;
	else
		return 0;

}

bool		operator<(	const Haar &h1, const Haar &h2)
{
	return( compare(h1,h2)<0 );
}

/////////////////////////////////////////////////////////////////////////////////
void		Haar::createSyst( int type, int width, int height, int fw, int fh, int tp, int lf, bool flip )
{
	assert( fw>=1 && fh>=1 );
	_iwidth = width;
	_iheight = height;
	_minArea = 1;
	_maxArea = width*height;
	int fw2, fh2, fw3, fh3, fw4;

	// check if big enough
	assert( fw>=minWidth(type) && fh>=minHeight(type));

	// creating according to type
	switch( type )
	{	
	case 0: // single square
		createRects(1);
		_rects[0].setPos( 0,  fw-1, 0, fh-1 );
		_rects[0].setWeight( 1.0f );
		break;

	case 1: // diagonal diff ul/lr
		createRects(2);
		fh2 = fh/2; fw2 = fw/2; 
		_rects[0].setPos( 0,  fw2-1, 0, fh2-1 );
		_rects[1].setPos( fw2,  fw-1, fh2, fh-1 );
		_rects[0].setWeight( 1.0 );
		_rects[1].setWeight( -1.0f );
		break;

	case 2: // diagonal diff ur/ll
		createRects(2);
		fh2 = fh/2; fw2 = fw/2; 
		_rects[0].setPos( fw2,  fw-1, 0, fh2-1 );
		_rects[1].setPos( 0,  fw2-1, fh2, fh-1 );
		_rects[0].setWeight( 1.0 );
		_rects[1].setWeight( -1.0f );
		break;

	case 3: // opp diagonals
		createRects(4);
		fh2 = fh/2; fw2 = fw/2; 
		_rects[0].setPos( 0,  fw2-1, 0, fh2-1 );
		_rects[1].setPos( fw2,  fw-1, 0, fh2-1 );
		_rects[2].setPos( fw2,  fw-1, fh2, fh-1 );
		_rects[3].setPos( 0,  fw2-1, fh2, fh-1 );
		_rects[0].setWeight( 1.0 );
		_rects[1].setWeight( -1.0 );
		_rects[2].setWeight( 1.0f );
		_rects[3].setWeight( -1.0f );
		break;
		
	case 4: // center-surround
		createRects(2);
		fw2 = fw/2; fh2 = fh/2;
		_rects[0].setPos( 0,  fw-1, 0, fh-1 );
		_rects[1].setPos( (fw-fw2)/2, (fw+fw2)/2-1, (fh-fh2)/2, (fh+fh2)/2-1);
		_rects[0].setWeight( 1.0f );
		_rects[1].setWeight( -4.0f );
		break;

	case 5: // edge
		createRects(2);
		fw2 = fw/2; 
		_rects[0].setPos( 0, fw2-1, 0,  fh-1 );
		_rects[1].setPos( fw2, fw-1, 0,  fh-1 );
		_rects[0].setWeight( 1.0f );
		_rects[1].setWeight( -1.0f );
		break;

	case 6: // ridge +-+
		createRects(2);
		fw2 = fw/3; fw3 = (fw*2)/3; 
		_rects[0].setPos( 0,  fw-1, 0, fh-1 );
		_rects[1].setPos( fw2,  fw3-1, 0, fh-1 );
		_rects[0].setWeight( 1.0f );
		_rects[1].setWeight( -3.0f );
		break;

	case 7: // separated difference (1 space)
		createRects(2);
		fw2 = fw/3; fw3 = (fw*2)/3; 
		_rects[0].setPos( 0,  fw2-1, 0, fh-1 );
		_rects[1].setPos( fw3,  fw-1, 0, fh-1 );
		_rects[0].setWeight( 1.0f );
		_rects[1].setWeight( -1.0f );
		break;

	case 8: // ridge +--+
		createRects(2);
		fw2 = fw/4; fw3 = (fw*3)/4; 
		_rects[0].setPos( 0,  fw-1, 0, fh-1 );
		_rects[1].setPos( fw2,  fw3-1, 0, fh-1 );
		_rects[0].setWeight( 1.0f );
		_rects[1].setWeight( -2.0f );
		break;

	case 9: // separated difference (2 spaces)
		createRects(2);
		fw2 = fw/4; fw3 = (fw*2)/4; fw4 = (fw*3)/4;
		_rects[0].setPos( 0,  fw2-1, 0, fh-1 );
		_rects[1].setPos( fw4,  fw-1, 0, fh-1 );
		_rects[0].setWeight( 1.0f );
		_rects[1].setWeight( -1.0f );
		break;
	
	case 10:  // 4 boxes, arranged in pattern (1)
		createRects(4);
		fw2 = fw/3; fw3 = (fw*2)/3; 
		fh2 = fh/3; fh3 = (fh*2)/3; 
		_rects[0].setPos( 0, fw2-1, fh2, fh3-1 );
		_rects[1].setPos( fw2, fw3-1, fh3, fh-1 );
		_rects[2].setPos( fw2, fw3-1, 0, fh2-1 );
		_rects[3].setPos( fw3, fw-1, fh2, fh3-1 );
		_rects[0].setWeight( 1.0f );
		_rects[1].setWeight( -1.0f );
		_rects[2].setWeight( 1.0f );
		_rects[3].setWeight( -1.0f );
		break;

	case 11: // 4 boxes, arranged in pattern (2)
		createRects(4);
		fw2 = fw/3; fw3 = (fw*2)/3; 
		fh2 = fh/3; fh3 = (fh*2)/3; 
		_rects[0].setPos( fw2, fw3-1, 0, fh2-1 );
		_rects[1].setPos( 0, fw2-1, fh2, fh3-1 );
		_rects[2].setPos( fw3, fw-1, fh2, fh3-1 );
		_rects[3].setPos( fw2, fw3-1, fh3, fh-1 );
		_rects[0].setWeight( 1.0f );
		_rects[1].setWeight( -1.0f );
		_rects[2].setWeight( 1.0f );
		_rects[3].setWeight( -1.0f );
		break;

	default:
		assert(false); // unknown type
		break;
	}

	// flip around diagonal 
	if( flip ) {
		for( int i=0; i<_nRects; i++ )
			_rects[i].setPos( _rects[i].getTp(), _rects[i].getBt(), 
							  _rects[i].getLf(), _rects[i].getRt() );
	}

	// finish creating
	Rect::getUnion(_boundRect,_rects);
	moveTo(tp, lf);
}

void		Haar::moveTo( int tpNew, int lfNew )
{
	int jshift,ishift;
	jshift = tpNew-_boundRect.getTp();
	ishift = lfNew-_boundRect.getLf();
	for( int i=0; i<_nRects; i++ )
		_rects[i].shift(jshift, ishift);
}

bool		Haar::finalize()
{
	if(_nRects==0 ) return false;

	sort( _rects.begin(), _rects.end() );
	float z = _rects[0].getWeight();
	for( int i=0; i<_nRects; i++ )
		_rects[i].setWeight( _rects[i].getWeight()/z );
	sort( _rects.begin(), _rects.end() );

	_areaPos = _areaNeg = 0.0f;
	for( int i=0; i<_nRects; i++ ) {
		float weight = _rects[i].getWeight();
		if( weight > 0  )
			_areaPos  += weight * (float)_rects[i].area();
		else
			_areaNeg  -= weight * (float)_rects[i].area();
	}
	_areaPosInv=1.0f/_areaPos;  _areaNegInv=1.0f/_areaNeg;
	_areaTotal = _areaPos+_areaNeg;

	Rect::getUnion(_boundRect,_rects);

	bool valid = (_boundRect.getLf()>=0 && _boundRect.getRt()<_iwidth &&
				  _boundRect.getTp()>=0 && _boundRect.getBt()<_iheight );
	for( int i=0; i<_nRects; i++ )
		valid = valid && _rects[i].isValid() 
		&& _rects[i].area()>=_minArea && _rects[i].area()<=_maxArea;
	return valid;
}

void		Haar::createRects( int n )
{
	_nRects = n; 
	_rects.resize(_nRects);
}

int			Haar::minWidth( int type )
{
	switch( type ) {
	case 0:  return 1;	break; 
	case 1:  return 2;	break;
	case 2:  return 2;	break;
	case 3:  return 2;	break;
	case 4:	 return 3;	break;
	case 5:	 return 1;	break;
	case 6:	 return 1;	break;
	case 7:	 return 1;	break;
	case 8:	 return 1;	break;
	case 9:	 return 1;	break;
	case 10: return 3;	break;
	case 11: return 3;	break;
	default: assert(false); return 0; break; 
	}
}

int			Haar::minHeight( int type )
{
	switch( type ) {
	case 0:  return 1;	break; 
	case 1:  return 2;	break;
	case 2:  return 2;	break;
	case 3:  return 2;	break;
	case 4:	 return 3;	break;
	case 5:	 return 2;	break;
	case 6:	 return 3;	break;
	case 7:	 return 3;	break;
	case 8:	 return 4;	break;
	case 9:	 return 4;	break;
	case 10: return 3;	break;
	case 11: return 3;	break;
	default: assert(false); return 0; break;
	}
}

/////////////////////////////////////////////////////////////////////////////////
string		Haar::getDescr() const
{
	char descr[64];
	sprintf( descr, "nRct=%i w=%2i h=%2i tp=%2i lf=%2i", _nRects,
				width(), height(), _boundRect.getTp(), _boundRect.getLf() );
	return descr;
}

void		Haar::compImageResp( Matrixf &resp, IntegralImage &II, int moment, bool normalize )
{
	moveTo(0,0); 
	int r,c,w,h;
	w = II.width() - width() + 1;
	h = II.height() - height() + 1;
	resp.setDims(h,w,0);

	switch(moment) {
	case 1: 
		for( r=0; r<h; r++ ) for( c=0; c<w; c++ ) {
			II.setRoi( c, r, c+width()-1, r+height()-1 );
			resp(r,c) = compResp1( II, normalize );
		}
		break;
	case 2: 
		for( r=0; r<h; r++ ) for( c=0; c<w; c++ ) {
			II.setRoi( c, r, c+width()-1, r+height()-1 );
			resp(r,c) = compResp2( II, normalize );
		}
		break;
	default:
		abortError( "Illegal moment", __LINE__, __FILE__ );
	}
}

void		Haar::compImageHistDist( Matrixf &resp, IntegralImage *IIs, int nImages, bool normalize )
{
	moveTo(0,0); 
	int r,c,w,h;
	w = IIs[0].width() - width() + 1;
	h = IIs[0].height() - height() + 1;
	resp.setDims(h,w,0);
	for( r=0; r<h; r++ ) for( c=0; c<w; c++ ) {
		for( int n=1; n<nImages; n++ ) {
			IIs[n].setRoi( c, r, c+width()-1, r+height()-1 );
		}
		resp(r,c) = compHistDist( IIs, nImages, normalize );
	}
}

/////////////////////////////////////////////////////////////////////////////////
bool		isInEllipse( double x, double y, double axisX, double axisY, double xCen, double yCen )
{
	double a,b,c; //major length, minor length,focal length
	double f1x,f1y,f2x,f2y; //focal points
	if( axisX > axisY ) {
		a=axisX; b=axisY;
		c = sqrt( a*a - b*b );
		f1x = xCen + c; f2x = xCen - c;
		f1y = yCen; f2y = yCen;
	} else {
		a=axisY; b=axisX;
		c = sqrt( a*a - b*b );
		f1x = xCen; f2x = xCen;
		f1y = yCen+c; f2y = yCen-c;
	}
	double d1 = sqrt((x-f1x)*(x-f1x) + (y-f1y)*(y-f1y));
	double d2 = sqrt((x-f2x)*(x-f2x) + (y-f2y)*(y-f2y));
	return( (d1+d2)<=2*a );
}

bool		isInRect( double x, double y, double wd, double ht, double xCen, double yCen )
{
	return (x>=(xCen-wd/2.0) && x<=(xCen+wd/2.0) && y>=(yCen-ht/2.0) && y<=(yCen+ht/2.0));
}

			HaarSetPrm::HaarSetPrm() 
{
	_width			= 0;
	_height			= 0;
	_minArea		= 1;
	_maxArea		= INT_MAX;
	_random			= false;

	for( int i=0; i<12; i++ ) _useType[i] = true;
	_nLocs			= 1;
	_nSizes			= 1;
	_minAreaFr		= .5f;
	_sizeFactor		= 2.0f; 
	_overlap		= .6f;

	_nRandom		= 0;
	_maxRects		= 2;
	_sizeBias		= 3.0;

	_constWd		= 0;
	_constHt		= 0;
	_centerDist		= 0; 
	_elliptical		= false;
}

string		HaarSetPrm::getDescr()
{
	string descr = "HaarSetPrm:\n";
	//descr += makeDescr( "width", _width );
	//descr += makeDescr( "height", _height );
	//descr += makeDescr( "minArea", _minArea );
	//descr += makeDescr( "maxArea", _maxArea );
	//descr += makeDescr( "random", _random );
	//if( _random ) {
	//	descr += makeDescr( "nRandom", _nRandom );
	//	descr += makeDescr( "maxRects", _maxRects );
	//	descr += makeDescr( "sizeBias", _sizeBias );
	//} else {
	//	descr += makeDescr( "useType", _useType, 12 );
	//	descr += makeDescr( "nLocs", _nLocs );
	//	descr += makeDescr( "nSizes", _nSizes );
	//	descr += makeDescr( "minAreaFr", _minAreaFr );
	//	descr += makeDescr( "sizeFactor", _sizeFactor );
	//	descr += makeDescr( "overlap", _overlap );
	//}
	//descr += makeDescr( "constWd", _constWd );
	//descr += makeDescr( "constHt", _constHt );
	//descr += makeDescr( "centerDist", _centerDist );
	//descr += makeDescr( "elliptical", _elliptical );
	return descr;
}

void		HaarSetPrm::writeToStrm( ofstream &strm )
{
	strm.write((char*)&_width,		sizeof(_width));
	strm.write((char*)&_height,		sizeof(_height));
	strm.write((char*)&_minArea,	sizeof(_minArea));
	strm.write((char*)&_maxArea,	sizeof(_maxArea));
	strm.write((char*)&_random,		sizeof(_random));

	strm.write((char*)&_nRandom,	sizeof(_nRandom));
	strm.write((char*)&_maxRects,	sizeof(_maxRects));
	strm.write((char*)&_sizeBias,	sizeof(_sizeBias));

	for( int i=0; i<12; i++ )
		strm.write((char*)&_useType[i], sizeof(_useType[i]));
	strm.write((char*)&_minAreaFr,	sizeof(_minAreaFr));
	strm.write((char*)&_nLocs,		sizeof(_nLocs));
	strm.write((char*)&_nSizes,		sizeof(_nSizes));
	strm.write((char*)&_sizeFactor,	sizeof(_sizeFactor));
	strm.write((char*)&_overlap,	sizeof(_overlap));

	strm.write((char*)&_constWd,	sizeof(_constWd));
	strm.write((char*)&_constHt,	sizeof(_constHt));
	strm.write((char*)&_centerDist,	sizeof(_centerDist));
	strm.write((char*)&_elliptical,	sizeof(_elliptical));	
}

void		HaarSetPrm::readFrmStrm( ifstream &strm )
{
	strm.read((char*)&_width,		sizeof(_width));
	strm.read((char*)&_height,		sizeof(_height));
	strm.read((char*)&_minArea,		sizeof(_minArea));
	strm.read((char*)&_maxArea,		sizeof(_maxArea));
	strm.read((char*)&_random,		sizeof(_random));

	strm.read((char*)&_nRandom,		sizeof(_nRandom));
	strm.read((char*)&_maxRects,	sizeof(_maxRects));
	strm.read((char*)&_sizeBias,	sizeof(_sizeBias));

	for( int i=0; i<12; i++ )
		strm.read((char*)&_useType[i], sizeof(_useType[i]));
	strm.read((char*)&_minAreaFr,	sizeof(_minAreaFr));
	strm.read((char*)&_nLocs,		sizeof(_nLocs));
	strm.read((char*)&_nSizes,		sizeof(_nSizes));
	strm.read((char*)&_sizeFactor,	sizeof(_sizeFactor));
	strm.read((char*)&_overlap,		sizeof(_overlap));

	strm.read((char*)&_constWd,		sizeof(_constWd));
	strm.read((char*)&_constHt,		sizeof(_constHt));
	strm.read((char*)&_centerDist,	sizeof(_centerDist));
	strm.read((char*)&_elliptical,	sizeof(_elliptical));	
}

void		Haar::makeHaarSet(	VecHaar &haars, HaarSetPrm &haarSetPrm )
{
	int width	= haarSetPrm._width;
	int height	= haarSetPrm._height;
	int minArea	= haarSetPrm._minArea;
	int maxArea	= haarSetPrm._maxArea;
	bool random	= haarSetPrm._random;
	haars.clear(); Haar haar;

	if( random ) {

	} else {
		bool *useType		= haarSetPrm._useType;
		float minAreaFr		= haarSetPrm._minAreaFr;
		int nLocs			= haarSetPrm._nLocs;
		int nSizes			= haarSetPrm._nSizes;
		float sizeFactor	= haarSetPrm._sizeFactor;
		float overlap		= haarSetPrm._overlap;
		overlap = max(0.0f,min(1.0f,overlap));
		minAreaFr = max(0.0f,min(1.0f,minAreaFr));

		int j1, j2, i1, i2, fw, fh, fw1, fh1; 
		float t_ctr, l_ctr, t_stp, l_stp; int t_num, l_num, t, l;		
		for( int type=0; type<12; type++ ) if( useType[type] ) {
			for( i1=0; i1<nSizes; i1++ )
			for( i2=0; i2<nSizes; i2++ ) {
				fw = (int) ceil( (float)width  * minAreaFr * pow(sizeFactor,(float)i1) ); 
				fh = (int) ceil( (float)height * minAreaFr * pow(sizeFactor,(float)i2) );
				for( int flip=0; flip<=1; flip++ ) {
					if(flip) { fh1=fw; fw1=fh; } else { fw1=fw; fh1=fh; }
					l_stp = max( 1.0f, fw1*(1.0f-overlap) );
					t_stp = max( 1.0f, fh1*(1.0f-overlap) );
					t_ctr = ((float)height-fh1)/2;   
					l_ctr = ((float)width-fw1)/2;
					t_num = min((nLocs-1)/2,(int)ceil(t_ctr/t_stp));
					l_num = min((nLocs-1)/2,(int)ceil(l_ctr/l_stp));
					for( j1=-t_num; j1<=t_num; j1++ )
					for( j2=-l_num; j2<=l_num; j2++ ) {
						t = (int) (t_ctr + j1*t_stp+.5f);
						l = (int) (l_ctr + j2*l_stp+.5f);
						haar.createSyst( type, width, height, fw, fh, t, l, flip>0 );
						haar._minArea = minArea;
						haar._maxArea = maxArea;
						if( haar.finalize() ) haars.push_back(haar);
					}
				}
			}
			unique( haars );
		}
		unique( haars ); freeDistant( haars, haarSetPrm );
	}
}

void		Haar::freeDistant(	VecHaar &haars, HaarSetPrm &haarSetPrm )
{
	int width		= haarSetPrm._width;
	int height		= haarSetPrm._height;
	int constWd		= haarSetPrm._constWd;
	int constHt		= haarSetPrm._constHt;
	bool elliptical	= haarSetPrm._elliptical;
	float centerDist = haarSetPrm._centerDist;

	if( constWd==0 || constWd>width ) constWd=width;
	if( constHt==0 || constHt>height ) constHt=height;
	if( centerDist<=0 && constWd==width && constHt==height ) return;

	Rect bRect; int l,r,t,b;  float w,h,xc,yc;
	xc = ((float) width) /2.0f - .5f;  yc = ((float) height)/2.0f - .5f;
	VecHaar::iterator haar = haars.begin();
	while( haar!=haars.end() ) {
		bRect = haar->_boundRect;
		w = (float)constWd; if(centerDist>0) w=min(w,centerDist*float(bRect.width()));
		h = (float)constHt; if(centerDist>0) w=min(w,centerDist*float(bRect.height()));
		l=bRect.getLf(); r=bRect.getRt(); t=bRect.getTp(); b=bRect.getBt();
		if( (elliptical  && isInEllipse(l,t,w/2,h/2,xc,yc) && isInEllipse(l,b,w/2,h/2,xc,yc)
						 && isInEllipse(r,t,w/2,h/2,xc,yc) && isInEllipse(r,b,w/2,h/2,xc,yc)) ||
		    (!elliptical && isInRect(l,t,w,h,xc,yc) && isInRect(l,b,w,h,xc,yc)
						 && isInRect(r,t,w,h,xc,yc) && isInRect(r,b,w,h,xc,yc)) )
			haar++;
		else
			haar = haars.erase( haar );
	}
}

void		Haar::unique(		VecHaar &haars  )
{
	sort( haars.begin(), haars.end() );
	VecHaar::iterator last = std::unique( haars.begin(), haars.end() );
	haars.erase( last, haars.end() );
}