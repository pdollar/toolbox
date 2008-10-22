#include "Savable.h"

#include "Matrix.h"
#include <iomanip>

				ObjImg::~ObjImg() 
{
	_objImgs.clear();
	if( _el!=NULL ) delete [] _el;
}

Savable*		ObjImg::create()
{
	Savable *s = Savable::createObj(_type);
	s->load( *this ); return s;
}

void			ObjImg::set( const char *name, const char *type, int n ) 
{ 
	assert( _el==NULL && _objImgs.size()==0 );
	strcpy(_name,name);
	strcpy(_type,type);
	_el			= NULL;
	_elNum		= 0;
	_elBytes	= 0;
	if(n>0) _objImgs.resize(n);
}

void			ObjImg::check( int minL, int maxL, const char *name, const char *type )
{
	if( type!=NULL && strcmp(_type,type) )
		abortError( "Invalid type", type, __LINE__, __FILE__ );
	if( name!=NULL && strcmp(_name,name) )
		abortError( "Invalid name:", name, __LINE__, __FILE__ );
	assert(int(_objImgs.size())>=minL );
	assert(int(_objImgs.size())<=maxL );
}

/////////////////////////////////////////////////////////////////////////////////
void			ObjImg::writeToStrm(ofstream &os) {
	os << _type << ' ' << _name << ' ';
	os.write((char*)&_elNum,sizeof(_elNum));
	if(_elNum>0) {
		os.write((char*)&_elBytes,sizeof(_elBytes));
		os.write(_el,_elNum*_elBytes);
	}
	int n=_objImgs.size(); os.write((char*)&n,sizeof(n));
	for( int i=0; i<n; i++ ) _objImgs[i].writeToStrm(os);
}

void			ObjImg::readFrmStrm(ifstream &is) {
	is >> _type >> _name; is.get();
	is.read((char*)&_elNum,sizeof(_elNum));
	if(_elNum>0) {
		is.read((char*)&_elBytes,sizeof(_elBytes));
		_el = new char[_elNum*_elBytes];
		is.read(_el,_elNum*_elBytes);
	}
	int n; is.read((char*)&n,sizeof(n)); 
	if(n>0) _objImgs.resize(n);
	for( int i=0; i<n; i++ ) _objImgs[i].readFrmStrm(is);
}

void			ObjImg::writeToTxt(ofstream &os,int indent) {
	for(int i=0; i<indent*2; i++) os.put(' ');
	os << setw(16) << left << _type;
	if( _elNum>=1 ) {
		os << setw(20) << left << _name << "= ";
		PrimitiveBase *p = (PrimitiveBase*) Savable::createObj(_type);
		p->load(*this); p->writeToTxt( os ); os << endl; delete p;
	} else {		
		int n=_objImgs.size(); char temp[20];
		sprintf(temp,"%s [ %i ]:",_name,n); os << temp << endl;
		for( int i=0; i<n; i++ ) _objImgs[i].writeToTxt(os,indent+1);		
	}
}

void			ObjImg::readFrmTxt(ifstream &is) 
{
	char temp[32];
	is >> _type >> _name >> temp;
	if( strcmp(temp,"=")==0 ) {
		PrimitiveBase *p = (PrimitiveBase*) Savable::createObj(_type);
		p->readFrmTxt( is ); p->save(*this,_name); delete p;
	} else {
		assert(strcmp(temp,"[")==0);
		int n; is>>n; is>>temp; assert(strcmp(temp,"]:")==0);
		if(n>0) _objImgs.resize(n);
		for( int i=0; i<n; i++ ) _objImgs[i].readFrmTxt(is);
	}
}

bool			ObjImg::saveToFile( const char *fName, bool binary )
{
	ofstream os; remove( fName );
	os.open(fName, binary? ios::out|ios::binary : ios::out );
	if (os.fail()) {
		abortError( "unable to save:", fName, __LINE__, __FILE__ );
		return false;
	}
	if(binary) writeToStrm(os); else writeToTxt(os);
	os.close();
	return true;
}

bool			ObjImg::loadFrmFile( const char *fName, ObjImg &oi, bool binary )
{
	ifstream is;
	is.open(fName, binary? ios::in|ios::binary : ios::in );
	if( is.fail() ) {
		abortError( "unable to load: ", fName, __LINE__, __FILE__ );
		return false;
	}
	if(binary) oi.readFrmStrm(is); else oi.readFrmTxt(is);
	is.close();
	return true;
}

/////////////////////////////////////////////////////////////////////////////////
Savable*		Savable::createObj( const char *cname ) 
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
	CREATE(Matrix<int>);
	CREATE(Matrix<float>);
	CREATE(Matrix<double>);
	abortError( "unknown type", cname, __LINE__, __FILE__ );
	return NULL;

	#undef CREATE_PRIMITIVE
	#undef CREATE
}

Savable*		Savable::cloneObj( Savable *obj )
{
	#define CLONE1(CLASS,SRC) \
		if (!strcmp(cname,#CLASS)) return (Savable*)new CLASS(*((CLASS*) SRC));
	#define CLONE2(CLASS,SRC) \
		if (!strcmp(cname,#CLASS)) { CLASS *obj=new CLASS(); (*obj)=*((CLASS*) SRC); return (Savable*) obj; }
	const char *cname = obj->getCname();
	abortError( "unknown type", cname, __LINE__, __FILE__ );
	return NULL;
	#undef CLONE1
	#undef CLONE2
}
