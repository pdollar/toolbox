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
	void					writeToStrm(ofstream &strm);

	void					readFrmStrm(ifstream &strm);

	void					writeToTxtStrm(ofstream &strm,int indent=0);

	void					readFrmTxtStrm(ifstream &strm);

	void					toStrm( ofstream &os );
	
	void					frmStrm( ifstream &is );

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
template< class T > class Primitive : Savable
{
public:
							Primitive() : _owner(1), _val(NULL), _n(0) {};

							Primitive( T *src, int n=1 )  : _owner(0), _val(src), _n(n) {}

							~Primitive() { free(); }

	void					free() { if(_owner && _val!=NULL) { delete [] _val; _val=NULL; } }

	virtual const char*		getCname() const { return typeid(T).name(); };

	virtual void			save( ObjImg &oi, char *name );

	virtual void			load( ObjImg &oi, char *name=NULL );

	template <class T1>	friend ostream& operator<<(ostream &os, const Primitive<T1> &p );
	
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

template<class T> ostream&	operator<<(ostream &os, const Primitive<T> &p )
{
	if( strcmp("char",p.getCname())==0 )
		os<<p._val;
	else if( p._n==1 ) 
		os<<*p._val;
	else {
		os << "[ " ; for(int i=0; i<p._n; i++) os << p._val[i] << " "; os << "]"; 
	}
	return os;
}

//template <class T1> friend istream&	operator>>(istream& is, const Primitive<T1> &p );
//template<class T> istream&	operator>>(istream& is, const Primitive<T> &p )
//{
//	char *line = new char[10000000];
//	if( strcmp("char",p.getCname())==0 ) {
//		is.getline( line, 10000000 );
//		//_val = new char[
//		cout << line << endl;
//		cout << strlen(line) << endl;
//	}
//	//else if( p._n==1 ) 
//	//	is<<*p._val;
//	//else {
//	//	is << "[ " ; for(int i=0; i<p._n; i++) is << p._val[i] << " "; is << "]"; 
//	//}
//	delete [] line;
//	return is;
//}

#endif