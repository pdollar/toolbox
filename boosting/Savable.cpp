#include "Savable.h"

#include "Matrix.h"
#include "Haar.h"

/////////////////////////////////////////////////////////////////////////////////
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
	abortError( "unknown type", cname, __LINE__, __FILE__ );
	return NULL;

	#undef CREATE_PRIMITIVE
	#undef CREATE
}

Savable*		Savable::create( const ObjImg &oi, const char *name )
{
	Savable *s = create(oi.getCname());
	s->load( oi, name ); return s;
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
	abortError( "unknown type", cname, __LINE__, __FILE__ );
	return NULL;

	#undef CLONE1
	#undef CLONE2
}

mxArray*		Savable::toMxArray() 
{
	#ifndef MATLAB_MEX_FILE
		return NULL;
	#else
		ObjImg oi; save(oi,"savable");
		return oi.toMxArray();	
	#endif
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

void			ObjImg::init( const char *name, const char *type, int n ) 
{
	assert( _el==NULL && _objImgs.size()==0 );
	strcpy(_name,name);
	strcpy(_cname,type);
	_el			= NULL;
	_elNum		= 0;
	_elBytes	= 0;
	if(n>0) _objImgs.resize(n);
}

void			ObjImg::check( int minL, int maxL, const char *name, const char *type ) const
{
	if( type!=NULL && strcmp(_cname,type) )
		abortError( "Invalid type", type, __LINE__, __FILE__ );
	if( name!=NULL && strcmp(_name,name) )
		abortError( "Invalid name:", name, __LINE__, __FILE__ );
	if( int(_objImgs.size())<minL )
		abortError( "Too few children:", __LINE__, __FILE__ );
	if( int(_objImgs.size())>maxL )
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

bool			ObjImg::saveToFile( const char *fName, bool binary )
{
	ofstream os; remove( fName );
	os.open(fName, binary? ios::out|ios::binary : ios::out );
	if(os.fail()) { abortError( "save failed:", fName, __LINE__, __FILE__ ); return 0; }
	writeToStrm(os,binary);
	os.close();	return 1;
}

bool			ObjImg::loadFrmFile( const char *fName, ObjImg &oi, bool binary )
{
	ifstream is;
	is.open(fName, binary? ios::in|ios::binary : ios::in );
	if(is.fail()) { abortError( "load failed:", fName, __LINE__, __FILE__ ); return 0; }
	oi.readFrmStrm(is,binary);
	is.close(); return 1;
}

mxArray*		ObjImg::toMxArray()
{
	#ifndef MATLAB_MEX_FILE
		return NULL;
	#else
		mxArray *M; Savable *s=Savable::create(_cname);
		if( s->customMxArray() ) {
			s->load(*this,_name);
			M = s->toMxArray();
		} else {
			int i,n=_objImgs.size(); char **names=(char**) mxCalloc(n,sizeof(char*));
			for( i=0; i<n; i++ ) names[i]=(char*) mxCalloc(512,sizeof(char));			
			for( i=0; i<n; i++ ) sprintf(names[i],_objImgs[i]._name);
			M = mxCreateStructMatrix(1, 1, n, (const char**) names);
			for( i=0; i<n; i++ ) mxSetFieldByNumber(M,0,i,_objImgs[i].toMxArray());
		}
		delete s; return M;
	#endif
}

/////////////////////////////////////////////////////////////////////////////////
void			VecSavable::save( ObjImg &oi, const char *name )
{
	int n=_v.size();
	oi.init(name,getCname(),n);
	for( int i=0; i<n; i++ )		
		_v[i]->save(oi._objImgs[i],"[vec-element]");
}

void			VecSavable::load( const ObjImg &oi, const char *name )
{
	int n = oi._objImgs.size();
	oi.check(n,n,name,getCname());
	for( int i=0; i<n; i++ )
		_v.push_back( Savable::create(oi._objImgs[i],"[vec-element]") );
}

mxArray*		VecSavable::toMxArray() 
{
	#ifndef MATLAB_MEX_FILE
		return NULL;
	#else
		int i,j,m,n=_v.size(); mxArray *M=NULL, *M1, *V;
		if(n==0) return mxCreateStructMatrix(0,0,0,NULL);
		for(int i=0; i<n; i++) {
			M1=_v[i]->toMxArray(); assert(mxIsStruct(M1));
			if( i==0 ) {
				m=mxGetNumberOfFields(M1);
				char **names=(char**) mxCalloc(m, sizeof(char*));
				for(j=0; j<m; j++) names[j]=(char*) mxCalloc(512,sizeof(char));
				for(j=0; j<m; j++) sprintf(names[j],mxGetFieldNameByNumber(M1,j));
				M=mxCreateStructMatrix( 1, n, m, (const char**) names );
			}
			for(int j=0; j<m; j++) {
				V=mxDuplicateArray(mxGetFieldByNumber(M1,0,j));
				mxSetFieldByNumber(M,i,j,V);
			}
			mxDestroyArray(M1);
		}
		return M;
	#endif
}
