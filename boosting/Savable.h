#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"
#include "Haar.h"

class Savable
{
public:
	enum saveType { PRIMITIVE, ARRAY, RECT, HAAR };

	void check( char *name1, saveType type1 ) {
		assert( type==type1 );
		assert( strcmp(name,name1)==0 );
	}

public:
	saveType type;
	char name[64];
};

typedef vector< Savable* > VecSavable;

/////////////////////////////////////////////////////////////////////////////////

class SavObj : public Savable
{
public:
	SavObj( int n, saveType type1 ) { vals.resize(n); }

	void checkLen( int minL, int maxL ) {
		assert(vals.size()>=minL && vals.size()<=maxL );
	}

public:
	VecSavable vals;
};

/////////////////////////////////////////////////////////////////////////////////

template< class T > class SavPrim : public Savable
{
public:
	SavPrim( T &val1, char *name1 ) { 
		strcpy(name,name1);
		type=PRIMITIVE;
		val=val1; 
	}

	void load( T &tar ) {
		tar=val;
	}

private:
	T val;
};

template<class T> class SavArray : public Savable
{
public:
	SavArray( T *val1, int n1, char *name1 ) {
		strcpy(name,name1);
		type=ARRAY;
		n=n1; // also copy array
	}

	virtual bool isLeaf() { return true; }

private:
	T* vals;
	int n;
};


#endif