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
	virtual					~Savable() {};

	virtual const char*		getCname() const = 0 ;

	virtual void			save( ObjImg &oi, const char *name ) = 0;

	virtual void			load( const ObjImg &oi, const char *name=NULL ) = 0;

public:
	virtual bool			customToTxt() const { return false; }

	virtual void			writeToTxt( ostream &os ) const {};

	virtual void			readFrmTxt( istream &is ) {};

public:
	static Savable*			createObj( const char *cname );

	static Savable*			createObj( ObjImg &oi );

	static Savable*			cloneObj( Savable *obj );
};


/////////////////////////////////////////////////////////////////////////////////
class ObjImg
{
public:
							ObjImg() { _el=NULL; _elNum=0; };

							~ObjImg ();

	void					init( const char *name, const char *type, int n );

	void					check( int minL, int maxL, const char *name=NULL, const char *type=NULL ) const;

	const char*				getCname() const { return _cname; };

	bool					saveToFile( const char *fName, bool binary=false );

	static bool				loadFrmFile( const char *fName, ObjImg &oi, bool binary=false );

private:
	void					writeToStrm( ofstream &os, bool binary, int indent=0 );

	void					readFrmStrm( ifstream &is, bool binary );

private:
	char					_cname[32];

	char					_name[32];

private:
	char					*_el;

	int						_elNum;

	size_t					_elBytes;

	template<class> friend class Primitive; 

public:
	VecObjImg				_objImgs;
};

/////////////////////////////////////////////////////////////////////////////////
template< class T > class Primitive : public Savable
{
public:
							Primitive() : _owner(1), _val(NULL), _n(0) {};

							Primitive( T *src, int n=1 )  : _owner(0), _val(src), _n(n) {}

							~Primitive() { freeVal(); }

	void					freeVal() { if(_owner && _val!=NULL) { delete [] _val; _val=NULL; } }

	virtual const char*		getCname() const { return typeid(T).name(); };

	virtual void			save( ObjImg &oi, const char *name );

	virtual void			load( const ObjImg &oi, const char *name=NULL );

	virtual bool			customToTxt() const { return true; }

	virtual void			writeToTxt( ostream &os ) const;

	virtual void			readFrmTxt( istream &is );

private:
	T						*_val;

	int						_n;

	const bool				_owner;
};

template<class T> void		Primitive<T>::save( ObjImg &oi, const char *name )
{
	size_t nBytes=sizeof(T);
	oi.init( name, getCname(), 0 );
	oi._el = new char[nBytes*_n];
	oi._elBytes=nBytes; oi._elNum=_n;
	memcpy(oi._el,_val,nBytes*_n);
}

template<class T> void		Primitive<T>::load( const ObjImg &oi, const char *name )
{
	freeVal();
	oi.check( 0, 0, name, getCname() );
	size_t nBytes=oi._elBytes; _n=oi._elNum;
	if(_owner ) _val=new T[nBytes*_n];
	memcpy(_val,oi._el,nBytes*_n);
}

template<class T> void		Primitive<T>::writeToTxt( ostream &os ) const
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