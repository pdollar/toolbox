#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"

class Savable : public Cloneable
{
public:
	void					checkType( char *type=NULL );

	void					checkName( char *name=NULL );

	virtual void			writeToStrm(ofstream &strm);

	virtual void			readFrmStrm(ifstream &strm);
	
	bool					saveToFile( const char *fName );

	static Savable*			loadFrmFile( const char *fName );

protected:
	char					_type[32];

	char					_name[32];
};

typedef vector< Savable* > VecSavable;

class SavObj : public Savable
{
public:
							SavObj() {};

							SavObj( char *name, char *type, int n );

							~SavObj ();

	virtual const char*		getCname() { return "SavObj"; }

public:
	void					checkLen( int minL, int maxL );

	virtual void			writeToStrm(ofstream &strm);

	virtual void			readFrmStrm(ifstream &strm);

public:
	VecSavable				_vals;
};

class SavLeaf : public Savable
{
public:
	enum primType { UNKNOWN, INT, LONG, FLOAT, DOUBLE, CHAR, BOOL };

							SavLeaf() {};

	template< class T >		SavLeaf( char *name, T *src, int elNum=1 );

							~SavLeaf() { delete [] _val; }

	virtual const char*		getCname() { return "SavLeaf"; }

public:
	template< class T > void		load( char *name, T *tar );

	template< class T >	primType	getPrimType( T val );

	virtual void			writeToStrm(ofstream &strm);

	virtual void			readFrmStrm(ifstream &strm);

private:
	char					*_val;

	primType				_pType;

	short					_elBytes;

	int						_elNum;
};

/////////////////////////////////////////////////////////////////////////////////

template< class T >				SavLeaf::SavLeaf( char *name, T *src, int elNum ) {
	strcpy(_type,"Primitive"); strcpy(_name,name);
	_elBytes=sizeof(T); _elNum=elNum;
	_val = new char[_elNum*_elBytes];
	_pType = getPrimType( *src );
	memcpy(_val,src,_elNum*_elBytes);
}

template< class T > void		SavLeaf::load( char *name, T *tar ) {
	checkType( "Primitive" );
	checkName( name );
	assert( _pType==getPrimType(*tar) );
	assert( sizeof(T)==_elBytes );
	memcpy(tar,_val,_elNum*_elBytes);
}

template< class T > SavLeaf::primType	SavLeaf::getPrimType( T val ) {
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

#endif