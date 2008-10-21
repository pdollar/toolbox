#include "Savable.h"

void			Savable::checkType( char *type ) {
	if( type==NULL && strcmp(_type,type) )
		abortError( "Invalid type", type, __LINE__, __FILE__ );
}

void			Savable::checkName( char *name ) {
	if( name!=NULL && strcmp(_name,name) )
		abortError( "Invalid name:", name, __LINE__, __FILE__ );
}

void			Savable::writeToStrm(ofstream &strm) {
	strm.write(_type,sizeof(char)*32);
	strm.write(_name,sizeof(char)*32);
}

void			Savable::readFrmStrm(ifstream &strm) {
	strm.read(_type,sizeof(char)*32);
	strm.read(_name,sizeof(char)*32);
}

bool			Savable::saveToFile( const char *fName )
{
	std::ofstream strm; remove( fName );
	strm.open(fName, std::ios::out|std::ios::binary);
	if (strm.fail()) {
		abortError( "unable to save:", fName, __LINE__, __FILE__ );
		return false;
	}

	strm << getCname() << '\0';
	writeToStrm( strm );

	strm.close();
	return true;
}

Savable*		Savable::loadFrmFile( const char *fName )
{
	char cname[512]; std::ifstream strm;
	strm.open(fName, std::ios::in|std::ios::binary);
	if( strm.fail() ) {
		abortError( "unable to load: ", fName, __LINE__, __FILE__ );
		return NULL;
	}

	strm >> cname; strm.get();
	Savable *savable = (Savable*) createObject(cname);
	savable->readFrmStrm( strm );

	strm.close();
	return savable;
}

/////////////////////////////////////////////////////////////////////////////////
				SavObj::SavObj( char *name, char *type, int n ) { 
	strcpy(_name,name); strcpy(_type,type); _vals.resize(n); 
}

				SavObj::~SavObj() {
	for( int i=0; i<(int)_vals.size(); i++ )
		delete _vals[i]; 
	_vals.clear();
}

void			SavObj::checkLen( int minL, int maxL ) {
	assert(int(_vals.size())>=minL );
	assert(int(_vals.size())<=maxL );
}

void			SavObj::writeToStrm(ofstream &strm) {
	Savable::writeToStrm( strm );		
	int n=_vals.size(); strm.write((char*)&n,sizeof(n));
	for( int i=0; i<n; i++ ) {
		strm << _vals[i]->getCname() << '\0';
		_vals[i]->writeToStrm(strm);
	}
}

void			SavObj::readFrmStrm(ifstream &strm) {
	Savable::readFrmStrm( strm );
	int n; char cname[128];
	strm.read((char*)&n,sizeof(n)); _vals.resize(n);
	for( int i=0; i<n; i++ ) {
		strm >> cname; strm.get();
		_vals[i]=(Savable*) createObject(cname);
		_vals[i]->readFrmStrm(strm);
	}
}

/////////////////////////////////////////////////////////////////////////////////
void			SavLeaf::writeToStrm(ofstream &strm) {
	Savable::writeToStrm( strm );
	strm.write((char*)&_pType,sizeof(_pType));
	strm.write((char*)&_elBytes,sizeof(_elBytes));
	strm.write((char*)&_elNum,sizeof(_elNum));
	strm.write(_val,_elNum*_elBytes);
}

void			SavLeaf::readFrmStrm(ifstream &strm) {
	Savable::readFrmStrm( strm );
	strm.read((char*)&_pType,sizeof(_pType));
	strm.read((char*)&_elBytes,sizeof(_elBytes));
	strm.read((char*)&_elNum,sizeof(_elNum));
	_val = new char[_elNum*_elBytes];
	strm.read(_val,_elNum*_elBytes);
}