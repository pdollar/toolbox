#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"

/////////////////////////////////////////////////////////////////////////////////
class Savable : public Cloneable
{
public:
	void	checkType( char *type=NULL ) {
		if( type==NULL && strcmp(_type,type) )
			abortError( "Invalid type", type, __LINE__, __FILE__ );
	}

	void	checkName( char *name=NULL ) {
		if( name!=NULL && strcmp(_name,name) )
			abortError( "Invalid name:", name, __LINE__, __FILE__ );
	}

	virtual void	writeToStrm(ofstream &strm) {
		strm.write(_type,sizeof(char)*32);
		strm.write(_name,sizeof(char)*32);
	}

	virtual void	readFrmStrm(ifstream &strm) {
		strm.read(_type,sizeof(char)*32);
		strm.read(_name,sizeof(char)*32);
	}
	
	bool	saveToFile( const char *fName )
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

	static Savable* loadFrmFile( const char *fName )
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

protected:
	char	_type[32];
	char	_name[32];
};

typedef vector< Savable* > VecSavable;

/////////////////////////////////////////////////////////////////////////////////
class SavObj : public Savable
{
public:
	SavObj() {};

	SavObj( char *name, char *type, int n ) { 
		strcpy(_name,name); strcpy(_type,type); _vals.resize(n); 
	}

	~SavObj() {
		for( int i=0; i<(int)_vals.size(); i++ )
			delete _vals[i]; 
		_vals.clear();
	}

	virtual const char* getCname() { return "SavObj"; }

public:
	void	checkLen( int minL, int maxL ) {
		assert(int(_vals.size())>=minL );
		assert(int(_vals.size())<=maxL );
	}

	virtual void	writeToStrm(ofstream &strm) {
		Savable::writeToStrm( strm );		
		int n=_vals.size(); strm.write((char*)&n,sizeof(n));
		for( int i=0; i<n; i++ ) {
			strm << _vals[i]->getCname() << '\0';
			_vals[i]->writeToStrm(strm);
		}
	}

	virtual void	readFrmStrm(ifstream &strm) {
		Savable::readFrmStrm( strm );
		int n; char cname[128];
		strm.read((char*)&n,sizeof(n)); _vals.resize(n);
		for( int i=0; i<n; i++ ) {
			strm >> cname; strm.get();
			_vals[i]=(Savable*) createObject(cname);
			_vals[i]->readFrmStrm(strm);
		}
	}

public:
	VecSavable _vals;
};

/////////////////////////////////////////////////////////////////////////////////
class SavLeaf : public Savable
{
public:
	enum primType { UNKNOWN, INT, LONG, FLOAT, DOUBLE, CHAR, BOOL };

	SavLeaf() {};

	template< class T > SavLeaf( char *name, T *src, int elNum=1 ) {
		strcpy(_type,"Primitive"); strcpy(_name,name);
		_elBytes=sizeof(T); _elNum=elNum;
		_val = new char[_elNum*_elBytes];
		_pType = getPrimType( *src );
		memcpy(_val,src,_elNum*_elBytes);
	}

	~SavLeaf() { delete [] _val; }

	virtual const char* getCname() { return "SavLeaf"; }

public:
	template< class T > void load( char *name, T *tar ) {
		checkType( "Primitive" );
		checkName( name );
		assert( _pType==getPrimType(*tar) );
		assert( sizeof(T)==_elBytes );
		memcpy(tar,_val,_elNum*_elBytes);
	}

	template< class T > primType getPrimType( T val ) {
		primType p; const char *stype=typeid(T).name();
		if(strcmp(stype,"int")==0) p=INT;
		else if(strcmp(stype,"long")==0) p=LONG;
		else if(strcmp(stype,"float")==0) p=FLOAT;
		else if(strcmp(stype,"double")==0) p=DOUBLE;
		else if(strcmp(stype,"char")==0) p=CHAR;
		else if(strcmp(stype,"bool")==0) p=BOOL;
		else abortError( "Unknown type", __LINE__, __FILE__ );
		return p;
	}

	virtual void	writeToStrm(ofstream &strm) {
		Savable::writeToStrm( strm );
		strm.write((char*)&_pType,sizeof(_pType));
		strm.write((char*)&_elBytes,sizeof(_elBytes));
		strm.write((char*)&_elNum,sizeof(_elNum));
		strm.write(_val,_elNum*_elBytes);
	}

	virtual void	readFrmStrm(ifstream &strm) {
		Savable::readFrmStrm( strm );
		strm.read((char*)&_pType,sizeof(_pType));
		strm.read((char*)&_elBytes,sizeof(_elBytes));
		strm.read((char*)&_elNum,sizeof(_elNum));
		_val = new char[_elNum*_elBytes];
		strm.read(_val,_elNum*_elBytes);
	}

private:
	char *_val;
	primType _pType;
	short _elBytes;
	int _elNum;
};

#endif