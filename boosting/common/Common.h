/**************************************************************************
* Basic utility functions and common includes.
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
**************************************************************************/
#ifndef COMMON_H
#define COMMON_H

// standard include
#include <iostream>
#include <fstream>
#include <vector>
#include <cmath>
#include <algorithm>
#include <string>
using namespace std;

// typedefs
typedef unsigned char		uchar;
typedef unsigned short		ushort;
typedef vector<int>			vectori;
typedef vector<float>		vectorf;
typedef vector<double>		vectord;
typedef vector<uchar>		vectoru;
typedef vector<ushort>		vectorus;
typedef vector<string>		vectorString;
static const double PI		= 3.1415926535897931;

// basic utility functions
template<class T> int	sign( T s ) { return (s > 0 ) ? 1 : ((s<0) ? -1 : 0); }
template<class T> T		squeeze( T v, T vMin, T vMax ) { return v<vMin ? vMin : v>vMax ? vMax : v; }
inline double			degToRad(double dDeg) { return dDeg * PI / 180; }
inline double			radToDeg(double dRad) { return dRad * 180 / PI; }
inline double			factorial(const int i) { double d=1.0; for(int k=2; k<=i; k++) d*=k; return d; }
inline int				roundInt(double v) {return (int)(v+0.5);}
inline string			int2str( int i, int nDigit )
{
	char f[32], t[64]; sprintf(f,"%%0%ii",nDigit); sprintf(t,f,i); return string(t);
}

// vector arithmetic operations and display
template<class T> T         vecSum( const vector<T> &v )
{
	T sum = (T) 0.0; for( size_t i=0; i<v.size(); i++ ) sum+=v[i]; return sum;
}

template<class T> vector<T> vecAdd( const vector<T> &v1, const vector<T> &v2 )
{
	vector<T> r(v1); for( size_t i=0; i<v1.size(); i++ ) r[i]+=v2[i]; return r;
}

template<class T> vector<T> vecSub( const vector<T> &v1, const vector<T> &v2 )
{
	vector<T> r(v1); for( size_t i=0; i<v1.size(); i++ ) r[i]-=v2[i]; return r;
}

template<class T> vector<T> vecMul( const vector<T> &v1, const vector<T> &v2 )
{
	vector<T> r(v1); for( size_t i=0; i<v1.size(); i++ ) r[i]*=v2[i]; return r;
}

template<class T> vector<T> vecDiv( const vector<T> &v1, const vector<T> &v2 )
{
	vector<T> r(v1); for( size_t i=0; i<v1.size(); i++ ) r[i]/=v2[i]; return r;
}

template<class T> vector<T> vecAdd( const vector<T> &v, T val )
{
	vector<T> r(v); for( size_t i=0; i<v.size(); i++ )  r[i]+=val; return r;
}

template<class T> vector<T> vecSub( const vector<T> &v, T val )
{
	vector<T> r(v); for( size_t i=0; i<v.size(); i++ )  r[i]-=val; return r;
}

template<class T> vector<T> vecMul( const vector<T> &v, T val )
{
	vector<T> r(v); for( size_t i=0; i<v.size(); i++ ) r[i]*=val; return r;
}

template<class T> vector<T> vecDiv( const vector<T> &v, T val )
{
	vector<T> r(v); for( size_t i=0; i<v.size(); i++ ) r[i]/=val; return r;
}

template<class T> vector<T> vecSub( T val, const vector<T> &v )
{
	vector<T> r(v.size(),val); for( size_t i=0; i<v.size(); i++ ) r[i]-=v[i]; return r;
}

template<class T> ostream& operator<<(ostream& os, const vector<T>& v)
{
	os << "[ " ; for (size_t i=0; i<v.size(); i++) os << v[i] << " "; os << "]"; return os;
}

// sort method that also gives order of elements after sorting
template<class T> class				SortableElement
{
public:
	T _val; int _ind;
	SortableElement() {};
	SortableElement( T val, int ind ) { _val=val; _ind=ind; }
	bool operator< ( SortableElement &b ) { return (_val < b._val ); };
};

template<class T> void				sortOrder( vector<T> &v, vectori &order )
{
	int n=v.size();
	vector< SortableElement<T> > v2;
	v2.resize(n);
	order.clear(); order.resize(n);
	for( int i=0; i<n; i++ ) {
		v2[i]._ind = i;
		v2[i]._val = v[i];
	}
	std::sort( v2.begin(), v2.end() );
	for( int i=0; i<n; i++ ) {
		order[i] = v2[i]._ind;
		v[i] = v2[i]._val;
	}
}

template<class T> void				reorder( vector<T> &v, vectori &order )
{
	assert( v.size()==order.size() );
	vector<T> copy( v.size() );
	for( int i=0; i<(int)v.size(); i++ )
		copy[i] = v[order[i]];
	v = copy;
}

template<class Ta, class Tb> void	sortVia_b( vector<Ta> &a, vector<Tb> &b )
{
	assert( a.size()==b.size() );
	vectori order;
	sortOrder<Tb>( b, order );
	reorder<Ta>( a, order );
}

// use assert(C)/error(msg1,...) to throw an InformativeException
class	InformativeException: public exception
{
public:
	InformativeException( int line, char *file, const char* m1=NULL, const char* m2=NULL, const char* m3=NULL ) {
		sprintf(_msg, "ERROR: %s (%d)", file, line ); const char *msgs[3]={m1,m2,m3};
		for(int i=0; i<3; i++) if(msgs[i]!=NULL) sprintf(_msg,"%s %s",_msg,msgs[i]);
	}
	virtual const char* what() const throw() { return _msg; }
	char _msg[2048];
};
#define assert(C) if(!(C)) throw InformativeException(__LINE__,__FILE__,"assertion failed:",#C);
#define error(...) throw InformativeException(__LINE__,__FILE__,__VA_ARGS__);
// use to define blocks of code only during debugging
#ifndef NDEBUG
#define ifdebug(C) C
#else
#define ifdebug(C) ((void) 0)
#endif

#endif
