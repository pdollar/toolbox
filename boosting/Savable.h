#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"

class Savable
{
public:
	void checkType( char *type=NULL ) {
		if( type==NULL && strcmp(_type,type) )
			abortError( "Invalid type", type, __LINE__, __FILE__ );
	}

	void checkName( char *name=NULL ) {
		if( name!=NULL && strcmp(_name,name) )
			abortError( "Invalid name:", name, __LINE__, __FILE__ );
	}

public:
	char _type[32];
	char _name[32];
};

typedef vector< Savable* > VecSavable;

/////////////////////////////////////////////////////////////////////////////////

class SavObj : public Savable
{
public:
	SavObj( char *name, char *type, int n ) { 
		strcpy(_name,name); strcpy(_type,type); _vals.resize(n); 
	}

	void checkLen( int minL, int maxL ) {
		assert(int(_vals.size())>=minL );
		assert(int(_vals.size())<=maxL );
	}

public:
	VecSavable _vals;
};

/////////////////////////////////////////////////////////////////////////////////

class SavLeaf : public Savable
{
public:
	enum primType { UNKNOWN, INT, LONG, FLOAT, DOUBLE, CHAR, BOOL };

	template< class T > SavLeaf( char *name, T *src, int elNum=1 ) {
		strcpy(_type,"LEAF"); strcpy(_name,name);
		_elBytes=sizeof(T); _elNum=elNum;
		_val = new char[_elNum*_elBytes];
		_pType = getPrimType( *src );
		memcpy(_val,src,_elNum*_elBytes);
	}

	~SavLeaf() { delete [] _val; }

	template< class T > void load( char *name, T *tar ) {
		checkType( "LEAF" );
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

private:
	char *_val;
	primType _pType;
	short _elBytes;
	int _elNum;
};

#endif