#include "Savable.h"
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
void			ObjImg::writeToStrm(ofstream &strm) {
	strm << _type << ' ';
	strm << _name << ' ';
	strm.write((char*)&_elNum,sizeof(_elNum));
	if(_elNum>0) {
		strm.write((char*)&_elBytes,sizeof(_elBytes));
		strm.write(_el,_elNum*_elBytes);
	}
	int n=_objImgs.size(); strm.write((char*)&n,sizeof(n));
	for( int i=0; i<n; i++ ) _objImgs[i].writeToStrm(strm);
}

void			ObjImg::readFrmStrm(ifstream &strm) {
	strm >> _type; strm.get();
	strm >> _name; strm.get();
	strm.read((char*)&_elNum,sizeof(_elNum));
	if(_elNum>0) {
		strm.read((char*)&_elBytes,sizeof(_elBytes));
		_el = new char[_elNum*_elBytes];
		strm.read(_el,_elNum*_elBytes);
	}
	int n; strm.read((char*)&n,sizeof(n)); 
	if(n>0) _objImgs.resize(n);
	for( int i=0; i<n; i++ ) _objImgs[i].readFrmStrm(strm);
}

void			ObjImg::writeToTxtStrm(ofstream &os,int indent) {
	for(int i=0; i<indent*2; i++) os.put(' '); char temp[20];
	os << setw(10) << left << _type;
	if( _elNum>=1 ) {
		if( _elNum==1 )
			os << setw(20) << left << _name;
		else {
			sprintf(temp,"%s[%i]",_name,_elNum);
			os << setw(20) << left << temp;
		} 
		os << "= "; toStrm( os ); os << endl;
	} else {		
		int n=_objImgs.size(); 
		sprintf(temp,"%s[%i]:",_name,n); os << temp << endl;
		for( int i=0; i<n; i++ ) _objImgs[i].writeToTxtStrm(os,indent+1);		
	}
}

void			ObjImg::readFrmTxtStrm(ifstream &is) 
{
	//char temp[32];
	//is >> _type >> _name >> temp;
	//cout << _type << " " << _name << " " << temp;
	//if( strcmp(temp,"=")==0 ) {
	//	frmStrm( is );
	//	cout << "woo" << endl;
	//} else {
	//	//int n=
	//	//for( int i=0; i<n; i++ ) _objImgs[i].readFrmTxtStrm(os);
	//}

	//is >> _type; is.get();
	//is >> _name; is.get();
	//is >> _elNum; is.get();
	//if(_elNum>0) {
	//	is >> _elBytes; is.get();
	//	//_el = new char[_elNum*_elBytes];
	//	//is >> *((int*) _el); is.get();
	//}
	//int n; is >> n; is.get();
	//if(n>0) _objImgs.resize(n);
	//for( int i=0; i<n; i++ ) _objImgs[i].readFrmStrm(is);
}

bool			ObjImg::saveToFile( const char *fName, bool binary )
{
	ofstream strm; remove( fName );
	strm.open(fName, binary? ios::out|ios::binary : ios::out );
	if (strm.fail()) {
		abortError( "unable to save:", fName, __LINE__, __FILE__ );
		return false;
	}
	if(binary) writeToStrm(strm); else writeToTxtStrm(strm);
	strm.close();
	return true;
}

bool			ObjImg::loadFrmFile( const char *fName, ObjImg &oi, bool binary )
{
	ifstream strm;
	strm.open(fName, binary? ios::in|ios::binary : ios::in );
	if( strm.fail() ) {
		abortError( "unable to load: ", fName, __LINE__, __FILE__ );
		return false;
	}
	if(binary) oi.readFrmStrm(strm); else oi.readFrmTxtStrm(strm);
	strm.close();
	return true;
}

void			ObjImg::toStrm( ofstream &os )
{
	#define TOSTRM(TYPE) \
	if(strcmp(_type,#TYPE)==0) { \
		Primitive<TYPE> p( (TYPE*) _el, _elNum ); os << p; return; }
	assert( _el!=NULL && _elNum>0 );
	TOSTRM(int)
	TOSTRM(long)
	TOSTRM(float)
	TOSTRM(double)
	TOSTRM(bool)
	TOSTRM(char)
	abortError( "Unknown type", _type, __LINE__, __FILE__ );
	#undef TOSTRM
}

void			ObjImg::frmStrm( ifstream &is )
{
	//#define FRMSTRM(TYPE) \
	//if(strcmp(_type,#TYPE)==0) { \
	//	Primitive<TYPE> p( NULL, 0 ); \
	//	is >> p; _elNum=p._n; _elBytes=sizeof(TYPE); \
	//	_el=(char*) p._val; return; \
	//}
	//assert( _el==NULL && _elNum==0 );
	//FRMSTRM(int)
	//FRMSTRM(long)
	//FRMSTRM(float)
	//FRMSTRM(double)
	//FRMSTRM(bool)
	//FRMSTRM(char)
	//abortError( "Unknown type", _type, __LINE__, __FILE__ );
	//#undef FRMSTRM
}

/////////////////////////////////////////////////////////////////////////////////
Savable*		Savable::createObj( const char *cname ) 
{
	#define CREATE_PRIMITIVE(T) \
		if(!strcmp(cname,#T)) return (Savable*) new Primitive<T>();
	#define CREATE(CLASS) \
		if(!strcmp(cname,#CLASS)) return (Savable*) new CLASS();

	CREATE_PRIMITIVE(int);
	CREATE_PRIMITIVE(long);
	CREATE_PRIMITIVE(float);
	CREATE_PRIMITIVE(double);
	CREATE_PRIMITIVE(bool);
	CREATE_PRIMITIVE(char);
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
