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
	virtual const char*		getCname() const = 0 ;

	virtual void			save( ObjImg &oi, char *name ) = 0;

	virtual void			load( ObjImg &oi, char *name=NULL ) = 0;

	static Savable*			createObj( const char *cname );

	static Savable*			cloneObj( Savable *obj );
};


/////////////////////////////////////////////////////////////////////////////////
class ObjImg
{
public:
							ObjImg() { _el=NULL; _elNum=0; };

							~ObjImg ();

	Savable*				create();

	void					set( const char *name, const char *type, int n );

	void					check( int minL, int maxL, const char *name=NULL, const char *type=NULL );

	bool					saveToFile( const char *fName, bool binary=false );

	static bool				loadFrmFile( const char *fName, ObjImg &oi, bool binary=false );

private:
	void					writeToStrm(ofstream &os);

	void					readFrmStrm(ifstream &is);

	void					writeToTxt(ofstream &os, int indent=0);

	void					readFrmTxt(ifstream &is);

private:
	char					_type[32];

	char					_name[32];

public:
	VecObjImg				_objImgs;

private:
	char					*_el;

	short					_elBytes;

	int						_elNum;

	template<class> friend class Primitive; 
};

/////////////////////////////////////////////////////////////////////////////////
class PrimitiveBase : public Savable
{
public:
	virtual void			writeToTxt( ostream &os ) = 0;

	virtual void			readFrmTxt( istream &is ) = 0;
};

template< class T > class Primitive : public PrimitiveBase
{
public:
							Primitive() : _owner(1), _val(NULL), _n(0) {};

							Primitive( T *src, int n=1 )  : _owner(0), _val(src), _n(n) {}

							~Primitive() { free(); }

	void					free() { if(_owner && _val!=NULL) { delete [] _val; _val=NULL; } }

	virtual const char*		getCname() const { return typeid(T).name(); };

	virtual void			save( ObjImg &oi, char *name );

	virtual void			load( ObjImg &oi, char *name=NULL );

	virtual void			writeToTxt( ostream &os );

	virtual void			readFrmTxt( istream &is );

private:
	T						*_val;

	int						_n;

	const bool				_owner;
};

template<class T> void		Primitive<T>::save( ObjImg &oi, char *name )
{
	size_t nBytes=sizeof(T);
	oi.set( name, getCname(), 0 );
	oi._el = new char[nBytes*_n];
	oi._elBytes=nBytes; oi._elNum=_n;
	memcpy(oi._el,_val,nBytes*_n);
}

template<class T> void		Primitive<T>::load( ObjImg &oi, char *name )
{
	free();
	oi.check( 0, 0, name, getCname() );
	size_t nBytes=oi._elBytes; _n=oi._elNum;
	if(_owner ) _val=new T[nBytes*_n];
	memcpy(_val,oi._el,nBytes*_n);
}

template<class T> void		Primitive<T>::writeToTxt( ostream &os )
{
	if( strcmp("char",getCname())==0 )
		os<<'"' << _val << '"';
	else if( _n==1 ) 
		os<<*_val;
	else {
		os << "[ " ; for(int i=0; i<_n; i++) os << _val[i] << " "; os << "]"; 
	}
}

template<class T> void		Primitive<T>::readFrmTxt( istream &is )
{	
	char c=is.get(); assert(c==' ');
	if( strcmp("char",getCname())==0 ) {
		c=is.get(); assert(c=='"');
		char *tmp=new char[1000000]; is.get(tmp,1000000);
		_n = strlen(tmp); assert(tmp[_n-1]=='"'); tmp[_n-1]='\0';
		_val=new T[_n]; memcpy(_val,tmp,_n*sizeof(T)); delete [] tmp;
	} else if( is.peek()=='[' ) {
		c=is.get(); assert(c=='[');
		T *tmp = new T[1000000]; _n=0;
		while(1) {
			is >> tmp[_n++]; c=is.get(); assert(c==' ');
			if( is.peek()==']' ) { is.get(); break; }
		}
		_val=new T[_n]; memcpy(_val,tmp,_n*sizeof(T)); delete [] tmp;
	} else {
		_val = new T[1]; _n=1;
		is >> *_val;
	}
}

#endif