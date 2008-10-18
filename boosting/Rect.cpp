#include "Rect.h"

			Rect::Rect()
{
	setWeight(1.0f); 
	setPos(0,0,0,0);
}

			Rect::Rect( int lf, int rt, int tp, int bt )
{ 
	setWeight(1.0f); 
	setPos(lf,rt,tp,bt); 
}

void		Rect::writeToStrm( ofstream &strm )
{
	strm.write((char*)&_lf, sizeof(_lf));
	strm.write((char*)&_rt, sizeof(_rt));
	strm.write((char*)&_tp, sizeof(_tp));
	strm.write((char*)&_bt, sizeof(_bt));
	strm.write((char*)&_weight, sizeof(_weight));
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
	setWeight( weight );
}

bool		Rect::isValid()	const
{
	return ( getLf()<=getRt() && getTp()<=getBt() );
}

void		Rect::setPos( int lf, int rt, int tp, int bt )
{
	_lf = lf;  _rt = rt;  _tp = tp;  _bt = bt;
}

void		Rect::shift(int jshift, int ishift)
{
	setPos( getLf()+ishift, getRt()+ishift, getTp()+jshift, getBt()+jshift );
}

void		Rect::shift( int lfshift, int rtshift, int tpshift, int btshift )
{
	_lf += lfshift;  _rt += rtshift;  _tp += tpshift;  _bt += btshift;
}

void		Rect::getBoundingRect( Rect &bndRect, const VecRect &rects )
{
	int lf=10000, rt=-10000, tp=10000, bt=-10000;
	for( int i=0; i<(int)rects.size(); i++ ) {
		lf=min(rects[i].getLf(),lf);
		rt=max(rects[i].getRt(),rt);
		tp=min(rects[i].getTp(),tp);
		bt=max(rects[i].getBt(),bt);
	}
	bndRect.setPos(lf,rt,tp,bt); 
}

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

bool		operator== (const Rect &rect1, const Rect &rect2)
{
	if(		rect1.getLf()!=rect2.getLf() ||
			rect1.getRt()!=rect2.getRt() ||
			rect1.getTp()!=rect2.getTp() ||
			rect1.getBt()!=rect2.getBt() )
		return false;
	else
		return( rect1.getWeight()==rect2.getWeight() );
}

int			compare(    const Rect &rect1, const Rect &rect2)
{
	if(      rect1.getLf()<rect2.getLf() )
		return -1;
	else if( rect1.getLf()>rect2.getLf() ) 
		return 1;
	else if( rect1.getRt()<rect2.getRt() )
		return -1;
	else if( rect1.getRt()>rect2.getRt() ) 
		return 1;
	else if( rect1.getTp()<rect2.getTp() )
		return -1;
	else if( rect1.getTp()>rect2.getTp() ) 
		return 1;
	else if( rect1.getBt()<rect2.getBt() )
		return -1;
	else if( rect1.getBt()>rect2.getBt() ) 
		return 1;
	else if( rect1.getWeight()<rect2.getWeight() )
		return -1;
	else if( rect1.getWeight()>rect2.getWeight() )
		return 1;
	else 
		return 0;
}

bool		operator<  (const Rect &rect1, const Rect &rect2)
{
	return( compare(rect1,rect2)<0 );
}