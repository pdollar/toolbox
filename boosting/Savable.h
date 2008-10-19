#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"
#include "Haar.h"

class Savable
{
public:
	enum saveType { LEAF, RECT, HAAR };

	void check( saveType type, char *name=NULL ) {
		if( _type!=type )
			abortError( "Invalid type", __LINE__, __FILE__ );
		if( name!=NULL && strcmp(_name,name) )
			abortError( "Invalid name:", name, __LINE__, __FILE__ );
	}

public:
	saveType _type;
	char _name[64];
};

typedef vector< Savable* > VecSavable;

class SavObj : public Savable
{
public:
	SavObj( char *name, int n, saveType type ) { 
		strcpy(_name,name); _vals.resize(n); _type=type;
	}

	void checkLen( int minL, int maxL ) {
		assert(_vals.size()>=minL && _vals.size()<=maxL );
	}

public:
	VecSavable _vals;
};

class SavLeaf : public Savable
{
public:
	 template< class T > SavLeaf( char *name, T *src, int elNum=1 ) { 
		_type=LEAF; strcpy(_name,name);
		_elBytes=sizeof(T); _elNum=elNum;
		_val = new char[_elNum*_elBytes];
		strcpy(_typeName,typeid(T).name());
		memcpy(_val,src,_elNum*_elBytes);
	}

	~SavLeaf() { delete [] _val; }

	template< class T > void load( char *name, T *tar ) {
		assert( strcmp(_name,name)==0 );
		assert( sizeof(T)==_elBytes );
		assert( strcmp(_typeName,typeid(T).name())==0 );
		memcpy(tar,_val,_elNum*_elBytes);
	}

private:
	char *_val;
	char _typeName[16]; //large?
	char _elBytes;
	int _elNum;
};

#endif