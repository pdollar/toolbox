#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"
#include "Haar.h"

class Savable;
typedef vector<Savable> VecSavable;


class Savable
{
public:
	
	const void load( void &val, const saveTypes type1 ) {
		assert( type==type1 );
		switch( type ) 
		{
		case HAAR:
			val = new Haar( vals );
		default:
			assert(false); break;
		}
	}

public:
	
	enum saveTypes { PRIMITIVE, ARRAY, HAAR };
	// const?
	saveTypes type;
	char name[64];
	VecSavable vals;
};

template<class T> class SavablePrimitive : Savable
{
public:
	SavableBasic( char *name1, T &val1 ) { 
		type=PRIMITIVE; strcpy(name,name1); val=val1; 
	}

	const void load( T &val1, const saveTypes type1 ) { 
		assert( type1==PRMITIVE ); val1=val;
	}

private:
	T val;
};

template<class T*> class SavableArray : Savable
{
public:
	SavableArray( char *name1, T *val1, int n1 ) {
		type=ARRAY; strcpy(name,name1);
		n=n1; // also copy array
	}

	const void load( T *&val1, const saveTypes type1 ) {
		assert( type==type1 );
		val1 = new T[n];
		// also copy array
	}

private:
	T* vals;
	int n;
};

#endif