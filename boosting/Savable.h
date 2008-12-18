/**************************************************************************
* Allow for serialization of C++ objects to various formats including: (1)
* editable text files, (2) binary files and (3) Matlab structs (mxArray).
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
**************************************************************************/

#ifndef SAVABLE_H
#define SAVABLE_H

#include "Public.h"

#ifdef MATLAB_MEX_FILE
#include "mex.h"
#else
typedef void mxArray;
typedef int mxClassID;
#endif

class ObjImg; class VecSavable;

/**************************************************************************
* Instances of subclasses of Savable can automatically be converted to/from
* a number of formats, including: (1) human editable text files, (2) binary
* files and (3) Matlab structures (mxArray). The third option (mxArray) is
* only available if compiling from within Matlab. All conversions are done
* using the intermediate class ObjImg (or Object Image), see below.
* Essentially, to allow conversion to the different types, a subclass only
% needs to define how to convert an object instance to/from an ObjImg. The
% only restriction on a Savable object is that while it may contain
% pointers ot other Savable objects, the pointers must form a tree with no
% cycles. Savable objects can also be cloned (provided they define a copy
% constructor) or instantiated based on class name.
**************************************************************************/
class Savable
{
public:
	virtual					~Savable() {};

	// unique string identifier of given class (subclasses MUST define)
	virtual const char*		getCname() const = 0;

	// create new or clone existing Savable objects
	static Savable*			create( const char *cname );
	static Savable*			clone( Savable *obj );

	// subclasses MUST implement conversion to/from ObjImg
	virtual void			toObjImg( ObjImg &oi, const char *name ) const = 0;
	virtual void			frmObjImg( const ObjImg &oi, const char *name ) = 0;

protected:
	// subclasses can have OPTIONAL custom conversion to/from text streams
	virtual bool			customTxt() const { return 0; }
	virtual void			toTxt( ofstream &os ) const { assert(0); };
	virtual void			frmTxt( ifstream &is ) { assert(0); };

	// subclasses can have OPTIONAL custom conversion to/from mxArray
	virtual bool			customMxArray() const { return 0; }
	virtual mxArray*		toMxArray() const { assert(0); return NULL; };
	virtual void			frmMxArray( const mxArray *M ) { assert(0); };

	friend class			ObjImg;
	friend class			VecSavable;
};

/**************************************************************************
* An ObjImg, or Object Image, is a serialization of a Savable object or of
* a primitive type. Once a Savable object or primitive is converted to this
* form, it can automatically be converted to other formats or unserialized.
*
* ObjImg is essentially a tree structure. There are two types of ObjImg.
* (1) The first is a serialization of a primitive or built in C type (int,
* float, double) or an array of primitives (use to/frmPrim below). These
* serve as the leaves of the tree. (2) The second type of ObjImg is a
* serialization of all user defined Savable objects. Such an ObjImg is
* basically a list of pointers to children ObjImgs.
*
* In addition, all ObjImg contain: (1) the class name of the serialized
* object and (2) the instance name of serialized object, eg. "x".
**************************************************************************/
class ObjImg
{
public:
	// constructor and destructor
	ObjImg() { _el=NULL; clear(); };
	~ObjImg() { clear(); };

	// free memory and reset variables to blank state
	void					clear();

	// initialize ObjImg with n children (used during toObjImg)
	void					init( const char *name, const char *cname, int n );

	// check that ObjImg has the expected properties (used during frmObjImg)
	void					check( const char *name, const char *cname, int minN, int maxN ) const;

	// class name of serialized object
	const char*				getCname() const { return _cname; };

public:
	// conversion to/from primitive (ONLY if encodes primitive type)
	template<class T> void	toPrim( char *name, T *tar ) const;
	template<class T> void	frmPrim( char *name, T *src, int n=1 );

	// conversion to/from Savable (ONLY if encodes Savable object)
	Savable*				toSavable( const char *name ) const;
	void					frmSavable( const char *name, const Savable *s );

	// conversion to/from mxArray
	mxArray*				toMxArray() const;
	void					frmMxArray( const mxArray *M );

	// converstion to/from binary file or human editable text file
	bool					toFile( const char *fName, bool binary=false );
	bool					frmFile( const char *fName, bool binary=false );

private:
	// converstion to/from stream (helpers for to/frmFile)
	void					toStrm( ofstream &os, bool binary, int indent=0 );
	void					frmStrm( ifstream &is, bool binary );
	void					primToTxt( ofstream &os );
	bool					primFrmTxt( ifstream &is );

private:	
	// the class and instance name of serialized object
	char					_cname[32]; 	
	char					_name[32];

	// used to store primitive types only
	char					*_el;
	int						_elNum;
	size_t					_elBytes;

public:
	// children ObjImgs (used for storing non-primitive objects)
	vector< ObjImg > 		_children;
};

template<class T> void		ObjImg::toPrim( char *name, T *tar ) const
{
	check(name,typeid(T).name(),0,0);
	memcpy(tar,_el,_elBytes*_elNum);
}

template<class T> void		ObjImg::frmPrim( char *name, T *src, int n )
{
	init(name,typeid(T).name(),0);
	_elBytes=sizeof(T); _elNum=n; int nBytes=_elBytes*n;
	_el=new char[nBytes]; memcpy(_el,src,nBytes);
}

/////////////////////////////////////////////////////////////////////////////////
class VecSavable : public Savable
{
public:
	virtual const char*		getCname() const {return "VecSavable"; };
	virtual void			toObjImg( ObjImg &oi, const char *name ) const;
	virtual void			frmObjImg( const ObjImg &oi, const char *name );

	virtual bool			customMxArray() const { return 1; }
	virtual mxArray*		toMxArray() const;
	virtual void			frmMxArray( const mxArray *M );

public:
	vector< Savable* >		_v;
};

#endif
