#include "Savable.h"

#include "Matrix.h"
#include "Haar.h"

/////////////////////////////////////////////////////////////////////////////////
bool			Savable::saveToFile( const char *fName, bool binary )
{
	ofstream os; remove( fName );
	os.open(fName, binary? ios::out|ios::binary : ios::out );
	if(os.fail()) { abortError( "save failed:", fName, __LINE__, __FILE__ ); return 0; }
	ObjImg oi; save(oi,"root");
	oi.writeToStrm(os,binary);
	os.close();	return 1;
}

Savable*		Savable::loadFrmFile( const char *fName, bool binary )
{
	ifstream is;
	is.open(fName, binary? ios::in|ios::binary : ios::in );
	if(is.fail()) { abortError( "load failed:", fName, __LINE__, __FILE__ ); return NULL; }
	ObjImg oi; oi.readFrmStrm(is,binary);
	Savable *s=create(oi.getCname()); s->load(oi,"root");
	is.close(); return s;
}

mxArray*		Savable::toMxArray()
{
#ifdef MATLAB_MEX_FILE
	if(customMxArray())
		return toMxArray1();
	else {
		ObjImg oi; save(oi,"root");
		return oi.toMxArray();
	}
#else
	return NULL;
#endif
}

Savable*		Savable::frmMxArray( const mxArray *M )
{
#ifdef MATLAB_MEX_FILE
	if( !mxIsStruct(M) ) {
		Savable *s = create(mxIdToChar(mxGetClassID(M)));
		s->frmMxArray1(M); return s;
	} else {
		ObjImg oi; oi.frmMxArray(M,"root");
		Savable *s = create(oi.getCname());
		s->load(oi,"root"); return s;
	}
#else
	return NULL;
#endif
}

Savable*		Savable::create( const char *cname )
{
#define CREATE_PRIMITIVE(T) \
	if(!strcmp(cname,#T)) return (Savable*) new Primitive<T>();
#define CREATE(T) \
	if(!strcmp(cname,#T)) return (Savable*) new T();

	CREATE_PRIMITIVE(int);
	CREATE_PRIMITIVE(long);
	CREATE_PRIMITIVE(float);
	CREATE_PRIMITIVE(double);
	CREATE_PRIMITIVE(bool);
	CREATE_PRIMITIVE(char);
	CREATE_PRIMITIVE(unsigned char);
	CREATE(VecSavable);
	CREATE(Matrix<int>);
	CREATE(Matrix<float>);
	CREATE(Matrix<double>);
	CREATE(Matrix<unsigned char>);
	CREATE(Rect);
	CREATE(Haar);	
	abortError( "unknown cname", cname, __LINE__, __FILE__ );
	return NULL;

#undef CREATE_PRIMITIVE
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
	CLONE1(Matrix<unsigned char>);
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
	_objImgs.clear();
}

void			ObjImg::init( const char *name, const char *cname, int n )
{
	assert( _el==NULL && _objImgs.size()==0 );
	strcpy(_name,name);
	strcpy(_cname,cname);
	_el			= NULL;
	_elNum		= 0;
	_elBytes	= 0;
	if(n>0) _objImgs.resize(n);
}

void			ObjImg::check( int minN, int maxN, const char *name, const char *cname ) const
{
	if( strcmp(_cname,cname) )
		abortError( "Invalid cname", cname, __LINE__, __FILE__ );
	if( strcmp(_name,name) )
		abortError( "Invalid name:", name, __LINE__, __FILE__ );
	if( int(_objImgs.size())<minN )
		abortError( "Too few children:", __LINE__, __FILE__ );
	if( int(_objImgs.size())>maxN )
		abortError( "Too many children:", __LINE__, __FILE__ );
}

void			ObjImg::writeToStrm( ofstream &os, bool binary, int indent )
{
	char cname[32]; strcpy(cname,_cname);
	for( int i=0; i<32; i++ ) if( cname[i]==' ' ) cname[i]='-';
	if( binary ) {
		os << cname << ' ' << _name << ' ';
		os.write((char*)&_elNum,sizeof(_elNum));
		if(_elNum>0) {
			os.write((char*)&_elBytes,sizeof(_elBytes));
			os.write(_el,_elNum*_elBytes);
		} else {
			int n=_objImgs.size(); os.write((char*)&n,sizeof(n));
			for( int i=0; i<n; i++ ) _objImgs[i].writeToStrm(os,binary);
		}
	} else {
		for(int i=0; i<indent*2; i++) os.put(' ');
		os << setw(16) << left << cname << " ";
		Savable *s = Savable::create(_cname);
		if( s->customToTxt() ) {
			os << setw(20) << left << _name << "= ";
			s->load(*this,_name); s->writeToTxt(os); os << endl;
		} else {
			int n=_objImgs.size(); char temp[20];
			sprintf(temp,"%s ( %i ):",_name,n); os << temp << endl;
			for( int i=0; i<n; i++ ) _objImgs[i].writeToStrm(os,binary,indent+1);
		}
		delete s;
	}
}

void			ObjImg::readFrmStrm( ifstream &is, bool binary )
{
	clear(); is >> _cname >> _name;
	for( int i=0; i<32; i++ ) if( _cname[i]=='-' ) _cname[i]=' ';
	if( binary ) {
		is.get();
		is.read((char*)&_elNum,sizeof(_elNum));
		if(_elNum>0) {
			is.read((char*)&_elBytes,sizeof(_elBytes));
			_el=new char[_elNum*_elBytes];
			is.read(_el,_elNum*_elBytes);
		} else {
			int n; is.read((char*)&n,sizeof(n));
			if(n>0) _objImgs.resize(n);
			for( int i=0; i<n; i++ ) _objImgs[i].readFrmStrm(is,binary);
		}
	} else {
		char temp[32]; is >> temp;
		if( strcmp(temp,"=")==0 ) {
			char c=is.get(); assert(c==' ');
			Savable *s = Savable::create(_cname);
			s->readFrmTxt(is); s->save(*this,_name);
			delete s;
		} else {
			assert(strcmp(temp,"(")==0);
			int n; is>>n; is>>temp; assert(strcmp(temp,"):")==0);
			if(n>0) _objImgs.resize(n);
			for( int i=0; i<n; i++ ) _objImgs[i].readFrmStrm(is,binary);
		}
	}
}

mxArray*		ObjImg::toMxArray()
{
#ifdef MATLAB_MEX_FILE
	mxArray *M; Savable *s=Savable::create(_cname);
	if( s->customMxArray() ) {
		s->load(*this,_name); M=s->toMxArray1();
	} else {
		int i,n=_objImgs.size(); char **names=(char**) mxCalloc(n+1,sizeof(char*));
		for( i=0; i<n+1; i++ ) names[i]=(char*) mxCalloc(512,sizeof(char));
		sprintf(names[0],"type"); for(i=0; i<n; i++) strcpy(names[i+1],_objImgs[i]._name);
		M = mxCreateStructMatrix(1, 1, n+1, (const char**) names);
		mxSetFieldByNumber(M,0,0,mxCreateString(_cname));
		for( i=0; i<n; i++ ) mxSetFieldByNumber(M,0,i+1,_objImgs[i].toMxArray());
	}
	delete s; return M;
#else
	return NULL;
#endif
}

void			ObjImg::frmMxArray( const mxArray *M, const char *name )
{
#ifdef MATLAB_MEX_FILE
	sprintf(_name,name);
	if( !mxIsStruct(M) ) {
		strcpy(_cname,mxIdToChar(mxGetClassID(M)));
	} else {
		assert(!strcmp("type",mxGetFieldNameByNumber(M,0)));
		mxArray *cname=mxGetFieldByNumber(M,0,0);
		mxGetString(cname,_cname,mxGetN(cname)+1);
	}
	Savable *s = Savable::create(_cname);
	if( s->customMxArray() ) {
		s->frmMxArray1(M); s->save(*this,name);
	} else {
		int n=mxGetNumberOfFields(M)-1; if(n>0) _objImgs.resize(n);
		for( int i=0; i<n; i++ ) {
			const char *name = mxGetFieldNameByNumber(M,i+1);
			_objImgs[i].frmMxArray(mxGetFieldByNumber(M,0,i+1),name);
		}
	}
	delete s;
#endif
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

mxArray**		mxStructArraySplit( const mxArray *M )
{
#ifdef MATLAB_MEX_FILE
	int i, j, n=mxGetN(M), m=mxGetNumberOfFields(M);
	mxArray **MS=new mxArray*[n];
	const char **fns=mxStructGetFieldNames(M);
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
	const char **fns=mxStructGetFieldNames(MS[0]);
	mxArray *M=mxCreateStructMatrix(1,n,m,fns);
	for(i=0; i<n; i++) for(j=0; j<m; j++)
		mxSetFieldByNumber(M,i,j,mxDuplicateArray(mxGetFieldByNumber(MS[i],0,j)));
	return M;
#else
	return NULL;
#endif
}

void			VecSavable::save( ObjImg &oi, const char *name )
{
	int n=_v.size();
	oi.init(name,getCname(),n);
	for( int i=0; i<n; i++ )		
		_v[i]->save(oi._objImgs[i],"[element]");
}

void			VecSavable::load( const ObjImg &oi, const char *name )
{
	int n=oi._objImgs.size();
	oi.check(n,n,name,getCname());
	for( int i=0; i<n; i++ ) {
		Savable *s = create(oi._objImgs[i].getCname());
		s->load(oi._objImgs[i],"[element]");
		_v.push_back( s );
	}
}

mxArray*		VecSavable::toMxArray1()
{
#ifdef MATLAB_MEX_FILE
	int i,j,m,n=_v.size(); mxArray **MS, *V, *M;
	if(n==0) return mxCreateStructMatrix(0,0,0,NULL);
	MS=new mxArray*[n]; for(i=0; i<n; i++) MS[i]=_v[i]->toMxArray();
	V=mxStructArrayMerge(MS,n); for(i=0; i<n; i++) mxDestroyArray(MS[i]);
	const char *fns[] = {"type","valType","val"}; delete [] MS;
	M=mxCreateStructMatrix( 1, 1, 3, fns );
	mxSetFieldByNumber(M,0,0,mxCreateString(getCname()));
	mxSetFieldByNumber(M,0,1,mxCreateString(_v[0]->getCname()));
	mxSetFieldByNumber(M,0,2,V);
	return M;
#else
	return NULL;
#endif
}

void			VecSavable::frmMxArray1( const mxArray *M )
{
#ifdef MATLAB_MEX_FILE
	assert(mxGetNumberOfFields(M)==3);
	assert(!strcmp(mxGetFieldNameByNumber(M,2),"val"));
	M=mxGetFieldByNumber(M,0,2); int n=mxGetN(M);
	mxArray **MS = mxStructArraySplit( M );
	for( int i=0; i<n; i++ ) {
		_v.push_back( Savable::frmMxArray(MS[i]) );
		mxDestroyArray( MS[i] );
	}
	delete [] MS;
#endif
}
