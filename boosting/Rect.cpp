#include "Rect.h"

			Rect::Rect()
{

	_wt = 1.0f;
	setPos(0,0,0,0);
}

			Rect::Rect( int lf, int rt, int tp, int bt )
{ 
	_wt = 1.0f;
	setPos(lf,rt,tp,bt); 
}

void		Rect::writeToStrm( ofstream &strm )
{
	strm.write((char*)&_lf, sizeof(_lf));
	strm.write((char*)&_rt, sizeof(_rt));
	strm.write((char*)&_tp, sizeof(_tp));
	strm.write((char*)&_bt, sizeof(_bt));
	strm.write((char*)&_wt, sizeof(_wt));
}

void		Rect::readFrmStrm( ifstream &strm )
{
	int lf,rt,tp,bt; float weight;
	strm.read((char*)&lf, sizeof(lf));
	strm.read((char*)&rt, sizeof(rt));
	strm.read((char*)&tp, sizeof(tp));
	strm.read((char*)&bt, sizeof(bt));
	strm.read((char*)&weight, sizeof(weight));
	setPos( lf, rt, tp, bt );
	_wt = weight;
}

bool		Rect::isValid()	const
{
	return ( _lf<=_rt && _tp<=_bt );
}

void		Rect::setPos( int lf, int rt, int tp, int bt )
{
	_lf = lf;  _rt = rt;  _tp = tp;  _bt = bt;
}

void		Rect::shift(int jshift, int ishift)
{
	setPos(_lf+ishift, _rt+ishift, _tp+jshift, _bt+jshift );
}

void		Rect::shift( int lfshift, int rtshift, int tpshift, int btshift )
{
	_lf += lfshift;  _rt += rtshift;  _tp += tpshift;  _bt += btshift;
}

void		Rect::getUnion( Rect &uRect, const VecRect &rects )
{
	int lf=10000, rt=-10000, tp=10000, bt=-10000;
	for( int i=0; i<(int)rects.size(); i++ ) {
		lf=min(rects[i]._lf,lf);
		rt=max(rects[i]._rt,rt);
		tp=min(rects[i]._tp,tp);
		bt=max(rects[i]._bt,bt);
	}
	uRect.setPos(lf,rt,tp,bt); 
}

/////////////////////////////////////////////////////////////////////////////////
bool		operator== (const Rect &rect1, const Rect &rect2)
{
	if(	rect1._lf!=rect2._lf ||
		rect1._rt!=rect2._rt ||
		rect1._tp!=rect2._tp ||
		rect1._bt!=rect2._bt )
		return false;
	else
		return( rect1._wt==rect2._wt );
}

int			compare(    const Rect &rect1, const Rect &rect2)
{
	if(      rect1._lf<rect2._lf )
		return -1;
	else if( rect1._lf>rect2._lf ) 
		return 1;
	else if( rect1._rt<rect2._rt )
		return -1;
	else if( rect1._rt>rect2._rt ) 
		return 1;
	else if( rect1._tp<rect2._tp )
		return -1;
	else if( rect1._tp>rect2._tp ) 
		return 1;
	else if( rect1._bt<rect2._bt )
		return -1;
	else if( rect1._bt>rect2._bt ) 
		return 1;
	else if( rect1._wt<rect2._wt )
		return -1;
	else if( rect1._wt>rect2._wt )
		return 1;
	else 
		return 0;
}

bool		operator<  (const Rect &rect1, const Rect &rect2)
{
	return( compare(rect1,rect2)<0 );
}