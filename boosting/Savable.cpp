/**************************************************************************
* Savable.cpp
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
**************************************************************************/
#include "Savable.h"
#include <iomanip>

#include "Matrix.h"
#include "Haar.h"

Savable*		Savable::create( const char *cname )
{
#define CREATE(T) \
	if(!strcmp(cname,#T)) return (Savable*) new T();

	CREATE(VecSavable);
	CREATE(Matrix<int>);
	CREATE(Matrix<float>);
	CREATE(Matrix<double>);
	CREATE(Matrix<uchar>);
	CREATE(Rect);
	CREATE(Haar);
	abortError( "unknown cname", cname, __LINE__, __FILE__ );
	return NULL;

#undef CREATE
}

Savable*		Savable::clone( Savable *obj )
{
#define CLONE1(T) \
	if(!strcmp(cname,#T)) return (Savable*)new T(*((T*) obj));
#define CLONE2(T) \
	if(!strcmp(cname,#T)) { T *obj=new T(); (*obj)=*((T*) obj); return (Savable*) obj; }

	const char *cname = obj->getCname();
	CLONE1(Matrix<int>);
	CLONE1(Matrix<float>);
	CLONE1(Matrix<double>);
	CLONE1(Matrix<uchar>);
	abortError( "unknown cname", cname, __LINE__, __FILE__ );
	return NULL;

#undef CLONE1
#undef CLONE2
}

/////////////////////////////////////////////////////////////////////////////////
void			ObjImg::clear()
{
	_cname[0]	= '\0';
	_name[0]	= '\0';
	if( _el!=NULL ) delete [] _el;
	_el			= NULL;
	_elNum		= 0;
	_elBytes	= 0;
	for( size_t i=0; i<_children.size(); i++ ) _children[i].clear();
	_children.clear();
}

void			ObjImg::init( const char *name, const char *cname, int n )
{
	assert( _el==NULL && _children.size()==0 );
	assert( strlen(name)>0 );
	strcpy(_name,name);
	strcpy(_cname,cname);
	_el			= NULL;
	_elNum		= 0;
	_elBytes	= 0;
	if(n>0) _children.resize(n);
}

void			ObjImg::check( const char *name, const char *cname, int minN, int maxN ) const
{
	int n = _children.size();
	if( strcmp(_cname,cname) )
		abortError( "Invalid cname", cname, __LINE__, __FILE__ );
	if( strcmp(_name,name) )
		abortError( "Invalid name:", name, __LINE__, __FILE__ );
	if( n<minN )
		abortError( "Too few children:", __LINE__, __FILE__ );
	if( n>maxN )
		abortError( "Too many children:", __LINE__, __FILE__ );
	if( maxN==0 && (_elNum==0 || _el==NULL) )
		abortError( "Primitive type not initialized:", __LINE__, __FILE__ );
	if( maxN>0 && (_elNum>0 || _el!=NULL) )
		abortError( "Primitive should not be initialized:", __LINE__, __FILE__ );
}

Savable*		ObjImg::toSavable( const char *name ) const
{
	Savable *s = Savable::create( _cname );
	s->frmObjImg( *this, name ); return s;
}

void			ObjImg::frmSavable( const char *name, const Savable *s )
{
	s->toObjImg( *this, name );
}

mxArray*		ObjImg::toMxArray() const
{
#ifdef MATLAB_MEX_FILE
#define GETID(M,T) if(!strcmp(_cname,PRIMNAME(T))) id=M;
	// primitive to non-struct mxArray
	if(_elNum>0) {
		mxClassID id = mxUNKNOWN_CLASS;
		GETID( mxINT32_CLASS, int );     GETID( mxINT64_CLASS, long );
		GETID( mxSINGLE_CLASS, float );  GETID( mxDOUBLE_CLASS, double );
		GETID( mxLOGICAL_CLASS, bool );  GETID( mxCHAR_CLASS, char );
		GETID( mxUINT8_CLASS, uchar );
		assert(id!=mxUNKNOWN_CLASS);
		if( id==mxCHAR_CLASS ) {
			return mxCreateString(_el);
		} else {
			mxArray *M = mxCreateNumericMatrix(1,_elNum,id,mxREAL);
			memcpy(mxGetData(M),_el,_elNum*_elBytes); return M;
		}
	}
	// check to see if underlying Savable object has custom toMxArray
	mxArray *M; Savable *s=Savable::create(_cname);
	if( !s->customMxArray() ) delete s; else {
		s->frmObjImg(*this,_name); M=s->toMxArray(); delete s; return M;
	}
	// standard toMxArray (to Matlab struct array)
	int i,n=_children.size(); char **names=(char**) mxCalloc(n+1,sizeof(char*));
	for( i=0; i<n+1; i++ ) names[i]=(char*) mxCalloc(512,sizeof(char));
	sprintf(names[0],"cname"); for(i=0; i<n; i++) strcpy(names[i+1],_children[i]._name);
	M = mxCreateStructMatrix(1, 1, n+1, (const char**) names);
	mxSetFieldByNumber(M,0,0,mxCreateString(_cname));
	for( i=0; i<n; i++ ) mxSetFieldByNumber(M,0,i+1,_children[i].toMxArray()); return M;
#undef GETID
#else
	return NULL;
#endif
}

void			ObjImg::frmMxArray( const mxArray *M )
{
#ifdef MATLAB_MEX_FILE
#define GETCNAME(M,T) if(id==M) { _elBytes=sizeof(T); strcpy(_cname,PRIMNAME(T)); }
	// primitive from non-struct mxArray
	if( !mxIsStruct(M) ) {
		clear(); assert(mxGetM(M)==1); _elNum=mxGetN(M);
		mxClassID id = mxGetClassID(M); _elBytes=0;
		GETCNAME( mxINT32_CLASS, int );    GETCNAME( mxINT64_CLASS, long );
		GETCNAME( mxSINGLE_CLASS, float ); GETCNAME( mxDOUBLE_CLASS, double );
		GETCNAME( mxLOGICAL_CLASS, bool ); GETCNAME( mxCHAR_CLASS, char );
		GETCNAME( mxUINT8_CLASS, uchar );
		assert(_elBytes>0);
		if(!strcmp(_cname,"char")) {
			assert(mxIsChar(M)); _elNum++;
			_el=new char[_elNum]; mxGetString(M,_el,_elNum);
		} else {
			assert(mxIsNumeric(M) || mxIsLogical(M));
			int nBytes=_elNum*_elBytes;
			_el=new char[nBytes]; memcpy(_el,mxGetData(M),nBytes);
		}
		return;
	}
	// check to see if underlying Savable object has custom frmMxArray
	assert(!strcmp("cname",mxGetFieldNameByNumber(M,0)));
	mxArray *cname=mxGetFieldByNumber(M,0,0);
	mxGetString(cname,_cname,mxGetN(cname)+1);
	Savable *s = Savable::create(_cname);
	if( !s->customMxArray() ) delete s; else {
		s->frmMxArray(M); s->toObjImg(*this,"tmp"); delete s; return;
	}
	// standard frmMxArray (to Matlab struct array)
	int n=mxGetNumberOfFields(M)-1; if(n>0) _children.resize(n);
	for( int i=0; i<n; i++ ) {
		const char *name = mxGetFieldNameByNumber(M,i+1);
		_children[i].frmMxArray(mxGetFieldByNumber(M,0,i+1));
		sprintf(_children[i]._name,name);
	}
#undef GETCNAME
#endif
}

/////////////////////////////////////////////////////////////////////////////////
bool			ObjImg::toFile( const char *fName, bool binary )
{
	ofstream os; remove( fName ); os.open(fName, binary? ios::out|ios::binary : ios::out );
	if(os.fail()) { abortError( "toFile failed:", fName, __LINE__, __FILE__ ); return 0; }
	toStrm(os,binary); os.close(); return 1;
}

bool			ObjImg::frmFile( const char *fName, bool binary )
{
	ifstream is; is.open(fName, binary? ios::in|ios::binary : ios::in );
	if(is.fail()) { abortError( "frmFile failed:", fName, __LINE__, __FILE__ ); return 0; }
	frmStrm(is,binary); char t[128]; is>>t; assert(strlen(t)==0); is.close(); return 1;
}

void			ObjImg::toStrm( ofstream &os, bool binary, int indent )
{
	if( binary ) {
		os << _cname << ' ' << _name << ' ';
		os.write((char*)&_elNum,sizeof(_elNum));
		if(_elNum>0) {
			// primitive toStrm(binary=1)
			os.write((char*)&_elBytes,sizeof(_elBytes));
			os.write(_el,_elNum*_elBytes);
		} else {
			// standard toStrm(binary=1)
			int n=_children.size(); os.write((char*)&n,sizeof(n));
			for( int i=0; i<n; i++ ) _children[i].toStrm(os,binary);
		}
	} else {
		for(int i=0; i<indent*2; i++) os.put(' ');
		os << setw(16) << left << _cname << " ";
		// primitive toStrm(binary=0)
		if(_elNum>0) { primToTxt(os); return; }
		// custom toTxt
		Savable *s = Savable::create(_cname);
		if( !s->customTxt() ) delete s; else {
			os << setw(20) << left << _name << "= ";
			s->frmObjImg(*this,_name); s->toTxt(os);
			os << endl; delete s; return;
		}
		// standard toStrm(binary=0)
		int n=_children.size(); char tmp[20];
		sprintf(tmp,"%s ( %i ):",_name,n); os << tmp << endl;
		for( int i=0; i<n; i++ ) _children[i].toStrm(os,binary,indent+1);
	}
}

void			ObjImg::frmStrm( ifstream &is, bool binary )
{
	clear(); is >> _cname >> _name;
	if( binary ) {
		is.get(); is.read((char*)&_elNum,sizeof(_elNum));
		if(_elNum>0) {
			// primitive frmStrm(binary=1)
			is.read((char*)&_elBytes,sizeof(_elBytes));
			_el=new char[_elNum*_elBytes];
			is.read(_el,_elNum*_elBytes);
		} else {
			// standard frmStrm(binary=1)
			int n; is.read((char*)&n,sizeof(n));
			if(n>0) _children.resize(n);
			for( int i=0; i<n; i++ ) _children[i].frmStrm(is,binary);
		}
	} else {
		char tmp[32]; is >> tmp;
		if( strcmp(tmp,"=")==0 ) {
			assert(is.get()==' ');
			// primitive frmStrm(binary=1)
			if(primFrmTxt(is)) return;
			// custom frmTxt
			Savable *s = Savable::create(_cname);
			s->frmTxt(is); s->toObjImg(*this,_name);
			delete s;
		} else {
			// standard frmStrm(binary=0)
			assert(strcmp(tmp,"(")==0);
			int n; is>>n; is>>tmp; assert(strcmp(tmp,"):")==0);
			if(n>0) _children.resize(n);
			for( int i=0; i<n; i++ ) _children[i].frmStrm(is,binary);
		}
	}
}

void			ObjImg::primToTxt( ofstream &os )
{
#define PWR(T1,T2) \
	if(!strcmp(_cname,PRIMNAME(T1))) for(int i=0; i<_elNum; i++) \
	os << setprecision(10) << T2(*((T1*) (_el+i*_elBytes))) << (i<_elNum-1 ? " " : "");

	os << setw(20) << left << _name << "= ";
	if(!strcmp(_cname,"char")) { os << '"' << _el << '"'; return; }
	if(_elNum>1) os << "[ ";
	PWR(int,int); PWR(long,long); PWR(float,float);
	PWR(double,double); PWR(bool,bool); PWR(uchar,int);
	if(_elNum>1) os << " ]"; os << endl;

#undef PWR
}

bool			ObjImg::primFrmTxt( ifstream &is )
{
#define PRD(T1,T2) \
	if(!strcmp(_cname,PRIMNAME(T1))) { \
	_elBytes=sizeof(T2); T2 *tmp; \
	if( is.peek()!='[' ) { tmp=new T2[1]; is>>*tmp; _elNum=1; } else { \
	assert(is.get()=='['); tmp=new T2[1000000]; _elNum=0; \
	while(is.peek()!=']') { is>>tmp[_elNum++]; assert(is.get()==' '); } is.get(); \
	} \
	_el=new char[_elNum*_elBytes]; memcpy(_el,tmp,_elNum*_elBytes); \
	delete [] tmp; isPrim=true; \
	}

	bool isPrim=false;
	if(!strcmp(_cname,"char")) {
		assert(is.get()=='"'); int n;
		char *tmp=new char[1000000]; is.get(tmp,1000000);
		_elBytes=1; _elNum=n=strlen(tmp); assert(tmp[n-1]=='"'); tmp[n-1]='\0';
		_el=new char[n]; memcpy(_el,tmp,n*sizeof(char));
		delete [] tmp; isPrim=true;
	}
	PRD(int,int); PRD(long,long); PRD(float,float);
	PRD(double,double); PRD(bool,bool); PRD(uchar,int);
	if(!strcmp(_cname,"uchar")) {
		uchar *tmp=new uchar[_elNum];
		for(int i=0; i<_elNum; i++) tmp[i]=(uchar) *(_el+i*_elBytes);
		delete [] _el; _el=(char*) tmp; _elBytes=1;
	}
	if(isPrim) assert(is.get()==10);
	return isPrim;

#undef PRD
}

/////////////////////////////////////////////////////////////////////////////////
const char**	mxStructGetFieldNames( const mxArray *M )
{
#ifdef MATLAB_MEX_FILE
	assert(mxIsStruct(M)); int j,m=mxGetNumberOfFields(M);
	char **fns=(char**) mxCalloc(m, sizeof(char*));
	for(j=0; j<m; j++) fns[j]=(char*) mxCalloc(512,sizeof(char));
	for(j=0; j<m; j++) strcpy(fns[j],mxGetFieldNameByNumber(M,j));
	return (const char**) fns;
#else
	return NULL;
#endif
}

mxArray**		mxStructArraySplit( const mxArray *M, int &n )
{
#ifdef MATLAB_MEX_FILE
	int i, j, m=mxGetNumberOfFields(M); n=mxGetN(M);
	mxArray **MS=new mxArray*[n]; const char **fns=mxStructGetFieldNames(M);
	for(i=0; i<n; i++) MS[i]=mxCreateStructMatrix(1,1,m,fns);
	for(i=0; i<n; i++) for(j=0; j<m; j++)
		mxSetFieldByNumber(MS[i],0,j,mxDuplicateArray(mxGetFieldByNumber(M,i,j)));
	return MS;
#else
	return NULL;
#endif
}

mxArray*		mxStructArrayMerge( mxArray **MS, int n )
{
#ifdef MATLAB_MEX_FILE
	if(n==0) return mxCreateStructMatrix(0,0,0,NULL);
	int i, j, m=mxGetNumberOfFields(MS[0]);
	mxArray *M=mxCreateStructMatrix(1,n,m,mxStructGetFieldNames(MS[0]));
	for(i=0; i<n; i++) for(j=0; j<m; j++)
		mxSetFieldByNumber(M,i,j,mxDuplicateArray(mxGetFieldByNumber(MS[i],0,j)));
	return M;
#else
	return NULL;
#endif
}

void			VecSavable::toObjImg( ObjImg &oi, const char *name ) const
{
	int n=_v.size(); oi.init(name,getCname(),n);
	for(int i=0; i<n; i++) _v[i]->toObjImg(oi._children[i],"[elt]");
}

void			VecSavable::frmObjImg( const ObjImg &oi, const char *name )
{
	int n=oi._children.size(); if(n==0) return; oi.check(name,getCname(),n,n);
	for(int i=0; i<n; i++) _v.push_back(oi._children[i].toSavable("[elt]"));
}

mxArray*		VecSavable::toMxArray() const
{
#ifdef MATLAB_MEX_FILE
	int i,n=_v.size(); mxArray **VS=new mxArray*[n];
	for(i=0; i<n; i++) { ObjImg oi; _v[i]->toObjImg(oi,"tmp"); VS[i]=oi.toMxArray(); }
	const char *fns[]={"cname","val"}; mxArray *M=mxCreateStructMatrix(1,1,2,fns);
	mxSetFieldByNumber(M,0,0,mxCreateString(getCname()));
	mxSetFieldByNumber(M,0,1,mxStructArrayMerge(VS,n));
	for(i=0; i<n; i++) mxDestroyArray(VS[i]); delete [] VS; return M;
#else
	return NULL;
#endif
}

void			VecSavable::frmMxArray( const mxArray *M )
{
#ifdef MATLAB_MEX_FILE
	int i,n; assert(mxGetNumberOfFields(M)==2);
	assert(!strcmp(mxGetFieldNameByNumber(M,0),"cname"));
	assert(!strcmp(mxGetFieldNameByNumber(M,1),"val"));
	mxArray **VS=mxStructArraySplit(mxGetFieldByNumber(M,0,1),n); _v.resize(n);
	for(i=0; i<n; i++) { ObjImg oi; oi.frmMxArray(VS[i]); _v[i]=oi.toSavable(""); }
	for(i=0; i<n; i++) mxDestroyArray(VS[i]); delete [] VS;
#endif
}
