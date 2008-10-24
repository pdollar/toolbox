#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"
#include <iomanip>

#ifdef MATLAB_MEX_FILE
	#include "mex.h"
#else
	//#define MATLAB_MEX_FILE
	typedef void mxArray;
	typedef int mxClassID;
#endif

class ObjImg; 

typedef vector< ObjImg > VecObjImg;

template< class T > class Primitive;

/////////////////////////////////////////////////////////////////////////////////
class Savable
{
public:
	virtual					~Savable() {};

	virtual const char*		getCname() const = 0;

	bool					saveToFile( const char *fName, bool binary=false );
	static Savable*			loadFrmFile( const char *fName, bool binary=false );

	mxArray*				toMxArray();
	static Savable*			frmMxArray( const mxArray *M );

	static Savable*			create( const char *cname );
	static Savable*			clone( Savable *obj );

protected:
	virtual void			save( ObjImg &oi, const char *name ) = 0;
	virtual void			load( const ObjImg &oi, const char *name ) = 0;

	virtual bool			customToTxt() const { return 0; }
	virtual void			writeToTxt( ostream &os ) const { assert(0); };
	virtual void			readFrmTxt( istream &is ) { assert(0); };

	virtual bool			customMxArray() const { return 0; }
	virtual mxArray*		toMxArray1() { assert(0); return NULL; };
	virtual void			frmMxArray1( const mxArray *M ) { assert(0); };

	friend					ObjImg;
};

/////////////////////////////////////////////////////////////////////////////////
class ObjImg
{
public:
							ObjImg() { _el=NULL; clear(); };

							~ObjImg() { clear(); };

	void					clear();

	void					init( const char *name, const char *type, int n );

	void					check( int minL, int maxL, const char *name=NULL, const char *type=NULL ) const;

	const char*				getCname() const { return _cname; };

protected:
	mxArray*				toMxArray();

	void					frmMxArray( const mxArray *M, const char *name );

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

public:
	VecObjImg				_objImgs;

	friend					Savable;

	template<class> friend class Primitive; 
};

/////////////////////////////////////////////////////////////////////////////////
template< class T > class Primitive : public Savable
{
public:
							Primitive() : _owner(1), _val(NULL), _n(0) {};

							Primitive( T *src, int n=1 )  : _owner(0), _val(src), _n(n) {}

							~Primitive() { clear(); }

	void					clear() { if(!_owner) return; if(_val!=NULL) delete [] _val; _val=NULL; _n=0; }

	const T*				getVal() { return _val; }

	virtual const char*		getCname() const { return typeid(T).name(); };

	virtual void			save( ObjImg &oi, const char *name );

	virtual void			load( const ObjImg &oi, const char *name );

public:
	virtual bool			customToTxt() const { return true; }

	virtual void			writeToTxt( ostream &os ) const { pWriteToTxt( *this, os ); };

	virtual void			readFrmTxt( istream &is ) { assert(_owner); clear(); pReadFrmTxt(*this,is); }

	template<class T1> friend void pReadFrmTxt( Primitive<T1> &p, istream &is );

	template<class T1> friend void pWriteToTxt( const Primitive<T1> &p, ostream &os );

public:
	virtual bool			customMxArray() const { return true; }

	virtual mxArray*		toMxArray1();

	virtual void			frmMxArray1( const mxArray *M );

private:
	T						*_val;

	int						_n;

	const bool				_owner;
};

template<class T> void		pWriteToTxt( const Primitive<T> &p, ostream &os )
{
	if( p._n==1 )
		os << setprecision(10) << *p._val;
	else {
		os << "[ " ;
		for(int i=0; i<p._n; i++) os << setprecision(10) << p._val[i] << " ";
		os << "]";
	}
}

template<class T> void		pReadFrmTxt( Primitive<T> &p, istream &is )
{
	if( is.peek()=='[' ) {
		char c=is.get(); assert(c=='[');
		T *tmp=new T[1000000]; int n=0;
		while(1) {
			is >> tmp[n++]; c=is.get(); assert(c==' ');
			if( is.peek()==']' ) { is.get(); break; }
		}
		p._n=n; p._val=new T[n]; memcpy(p._val,tmp,n*sizeof(T)); delete [] tmp;
	} else {
		p._n=1; p._val=new T[1]; is >> *p._val;
	}
}

template<> inline void		pWriteToTxt<char>( const Primitive<char> &p, ostream &os )
{
	os << '"' << p._val << '"';
}

template<> inline void		pReadFrmTxt<char>( Primitive<char> &p, istream &is )
{
	char c=is.get(); assert(c=='"'); int n;
	char *tmp=new char[1000000]; is.get(tmp,1000000);
	p._n=n=strlen(tmp); assert(tmp[n-1]=='"'); tmp[n-1]='\0';
	p._val=new char[n]; memcpy(p._val,tmp,n*sizeof(char));
	delete [] tmp;
}

template<> inline void		pWriteToTxt<uchar>( const Primitive<uchar> &p, ostream &os )
{
	Primitive<int> pInt; int n=p._n;
	pInt._n=n; pInt._val=new int[n];
	for(int i=0; i<n; i++) pInt._val[i]=(int) p._val[i]; 	
	pInt.writeToTxt(os);
}

template<> inline void		pReadFrmTxt<uchar>( Primitive<uchar> &p, istream &is )
{
	Primitive<int> pInt; pInt.readFrmTxt(is); int n=pInt._n;
	p._n=n; p._val=new uchar[n];
	for(int i=0; i<n; i++) p._val[i]=(uchar) pInt._val[i]; 	
}

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
	clear();
	oi.check( 0, 0, name, getCname() );
	size_t nBytes=oi._elBytes; _n=oi._elNum;
	if(_owner ) _val=new T[nBytes*_n]; else assert(_val!=NULL);
	memcpy(_val,oi._el,nBytes*_n);
}

inline mxClassID			charToMxId( const char* cname)
{
	#ifdef MATLAB_MEX_FILE
		if(!strcmp(cname,"int")) return mxINT32_CLASS;
		else if(!strcmp(cname,"long")) return mxINT64_CLASS;
		else if(!strcmp(cname,"float")) return mxSINGLE_CLASS;
		else if(!strcmp(cname,"double")) return mxDOUBLE_CLASS;
		else if(!strcmp(cname,"bool")) return mxLOGICAL_CLASS;
		else if(!strcmp(cname,"char")) return mxCHAR_CLASS;
		else if(!strcmp(cname,"unsigned char")) return mxUINT8_CLASS;
		else assert(false); return mxUNKNOWN_CLASS;
	#else
		return 0;
	#endif
}

inline const char*			mxIdToChar( mxClassID id ) 
{
	#ifdef MATLAB_MEX_FILE
		switch( id ) {	
		case mxINT32_CLASS: return "int";
		case mxINT64_CLASS: return "long";
		case mxSINGLE_CLASS: return "float";
		case mxDOUBLE_CLASS: return "double";
		case mxLOGICAL_CLASS: return "bool";
		case mxCHAR_CLASS: return "char";
		case mxUINT8_CLASS: return "unsigned char";
		default: assert(false); return "unknown type";
		}
	#else
		return NULL;
	#endif
}

template<class T> mxArray*	Primitive<T>::toMxArray1()
{
	#ifdef MATLAB_MEX_FILE
		mxClassID id = charToMxId(getCname());
		if(id==mxCHAR_CLASS) {
			return mxCreateString((char*)_val);
		} else {
			mxArray *M = mxCreateNumericMatrix(1,_n,id,mxREAL);
			void *p = mxGetData(M); memcpy(p,_val,sizeof(T)*_n);
			return M;
		}
	#else 
		return NULL;
	#endif
}

template<class T> void		Primitive<T>::frmMxArray1( const mxArray *M )
{
	#ifdef MATLAB_MEX_FILE
		assert(_owner); clear();
		assert((mxIsNumeric(M) || mxIsChar(M) || mxIsLogical(M)) && mxGetM(M)==1);
		if(!strcmp(getCname(),"char")) {
			_n=mxGetN(M)+1; _val=new T[_n];
			mxGetString(M,(char*)_val,_n);
		} else {
			_n=mxGetN(M); _val=new T[_n];
			void *p=mxGetData(M); memcpy(_val,p,sizeof(T)*_n);
		}
	#endif
}

/////////////////////////////////////////////////////////////////////////////////
class VecSavable : public Savable
{
public:
	virtual const char*		getCname() const {return "VecSavable"; };

	virtual void			save( ObjImg &oi, const char *name );

	virtual void			load( const ObjImg &oi, const char *name );

	virtual bool			customMxArray() const { return true; }
	virtual mxArray*		toMxArray1();
	virtual void			frmMxArray1( const mxArray *M );

public:
	vector< Savable* >		_v;
};

#endif