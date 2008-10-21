#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"

class ObjImg; 

template< class T > class Primitive;

typedef vector< ObjImg > VecObjImg;

/////////////////////////////////////////////////////////////////////////////////
class Savable
{
public:
	virtual const char*		getCname() = 0;

	virtual void			save( ObjImg &oi, char *name ) = 0;

	virtual void			load( ObjImg &oi, char *name=NULL ) = 0;
};

Savable* createObject( const char* cname );

Savable* cloneObject( Savable *obj );

/////////////////////////////////////////////////////////////////////////////////
class ObjImg
{
public:
							ObjImg() { _el=NULL; _elNum=0; };

							~ObjImg ();

	void					set( const char *name, const char *type, int n );

	void					check( int minL, int maxL, const char *name=NULL, const char *type=NULL );

	virtual void			writeToStrm(ofstream &strm);

	virtual void			readFrmStrm(ifstream &strm);
	
	bool					saveToFile( const char *fName );

	static bool				loadFrmFile( const char *fName, ObjImg &oi );

protected:
	char					_type[32];

	char					_name[32];

public:
	VecObjImg				_objImgs;

private:
	char					*_el;

	uchar					_elBytes;

	int						_elNum;

	template<class> friend class Primitive; 
};

/////////////////////////////////////////////////////////////////////////////////
template< class T > class Primitive
{
public:
							Primitive() { _val=NULL; _n=0; };

							Primitive( T *src, int n=1 );

	void					save( ObjImg &oi, char *name );

	void					load( ObjImg &oi, char *name=NULL );

private:
	T						*_val;

	int						_n;
};

template< class T >			Primitive<T>::Primitive( T *src, int n ) 
{
	_n=n; _val=src;
}

template<class T> void		Primitive<T>::save( ObjImg &oi, char *name )
{
	uchar nBytes=sizeof(T);
	oi.set( name, typeid(T).name(), 0 );
	oi._el = new char[nBytes*_n];
	oi._elBytes=nBytes; oi._elNum=_n;
	memcpy(oi._el,_val,nBytes*_n);
}

template<class T> void		Primitive<T>::load( ObjImg &oi, char *name )
{
	oi.check( 0, 0, name, typeid(T).name() );
	uchar nBytes=oi._elBytes; _n=oi._elNum; 
	memcpy(_val,oi._el,nBytes*_n);
}

#endif