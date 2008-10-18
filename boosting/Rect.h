#ifndef RECT_H
#define RECT_H

#include <vector>
#include <iostream>
#include <fstream>
using namespace std;

class Rect;
typedef vector< Rect > VecRect;

class Rect
{
public:
					Rect();
					Rect( int lf, int rt, int tp, int bt );

	void			writeToStrm( ofstream &strm );
	void			readFrmStrm( ifstream &strm );

	int				area()		const {return (_rt-_lf+1)*(_bt-_tp+1); };
	int				height()	const {return _bt-_tp+1;};
	int				width()		const {return _rt-_lf+1;};
	bool			isValid()	const;

	int				getLf()	const { return _lf; }
	int				getRt()	const { return _rt; }
	int				getTp()	const { return _tp; }
	int				getBt() const { return _bt; }

	void			setLf( int lf ) { _lf=lf; }
	void			setRt( int rt ) { _rt=rt; }
	void			setTp( int tp ) { _tp=tp; }
	void			setBt( int bt ) { _bt=bt; }

	void			shift( const int jshift, const int ishift );
	void			shift( int lfshift, int rtshift, int tpshift, int btshift );
	void			setPos( const int lf, int rt, int tp, int bt );

	void			setWeight( float weight ) { _weight = weight; };
	float			getWeight()	const { return _weight; }

	static void		getBoundingRect( Rect &bndRect, const VecRect &rects );

	friend int		compare(	const Rect &rect1, const Rect &rect2);
	friend bool		operator==(	const Rect &rect1, const Rect &rect2);
	friend bool		operator<(	const Rect &rect1, const Rect &rect2);

private:
	// define a rectangle
	int				_lf;
	int				_rt;
	int				_tp;
	int				_bt;
	float			_weight;
};

#endif