#include "Savable.h"

				ObjImg::~ObjImg() 
{
	_objImgs.clear();
	if( _el!=NULL ) delete [] _el;
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

void			ObjImg::writeToStrm(ofstream &strm) {
	strm.write(_type,sizeof(char)*32);
	strm.write(_name,sizeof(char)*32);
	strm.write((char*)&_elNum,sizeof(_elNum));
	if(_elNum>0) {
		strm.write((char*)&_elBytes,sizeof(_elBytes));
		strm.write(_el,_elNum*_elBytes);
	}
	int n=_objImgs.size(); strm.write((char*)&n,sizeof(n));
	for( int i=0; i<n; i++ ) _objImgs[i].writeToStrm(strm);
}

void			ObjImg::readFrmStrm(ifstream &strm) {
	strm.read(_type,sizeof(char)*32);
	strm.read(_name,sizeof(char)*32);	
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

bool			ObjImg::saveToFile( const char *fName )
{
	std::ofstream strm; remove( fName );
	strm.open(fName, std::ios::out|std::ios::binary);
	if (strm.fail()) {
		abortError( "unable to save:", fName, __LINE__, __FILE__ );
		return false;
	}
	writeToStrm( strm );
	strm.close();
	return true;
}

bool			ObjImg::loadFrmFile( const char *fName, ObjImg &oi )
{
	std::ifstream strm;
	strm.open(fName, std::ios::in|std::ios::binary);
	if( strm.fail() ) {
		abortError( "unable to load: ", fName, __LINE__, __FILE__ );
		return false;
	}
	oi.readFrmStrm( strm );
	strm.close();
	return true;
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
