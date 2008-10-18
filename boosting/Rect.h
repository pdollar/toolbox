#ifndef RECT_H
#define RECT_H

#include "Public.h"

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

	void			shift( const int jshift, const int ishift );
	void			shift( int lfshift, int rtshift, int tpshift, int btshift );
	void			setPos( const int lf, int rt, int tp, int bt );

	static void		getUnion( Rect &uRect, const VecRect &rects );

	friend int		compare(	const Rect &rect1, const Rect &rect2);
	friend bool		operator==(	const Rect &rect1, const Rect &rect2);
	friend bool		operator<(	const Rect &rect1, const Rect &rect2);

public:
	// define a rectangle
	int				_lf;
	int				_rt;
	int				_tp;
	int				_bt;
	float			_wt;
};

#endif