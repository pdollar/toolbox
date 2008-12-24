/**************************************************************************
* Basic Matrix class.
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
**************************************************************************/
#ifndef _MATRIX_H
#define _MATRIX_H

#include "Common.h"
#include "Savable.h"

template< class T > class Matrix;
typedef Matrix< float >	Matrixf;
typedef Matrix< double > Matrixd;
typedef Matrix< int > Matrixi;
typedef Matrix< uchar >	Matrixu;

template<class T> class Matrix : public Savable
{
public:
	// constructors, destructor and assignment
	Matrix() { init(); };
	Matrix( int mRows, int nCols );
	Matrix( int mRows, int nCols, T val );
	Matrix( const Matrix& x );
	~Matrix() { clear(); };
	void			init();
	void			clear();
	Matrix<T>&		operator= (const Matrix<T> &x );
	Matrix<T>&		operator= (const vector<T> &x );

	// set/get dimensions (note: [1xn] vectors more efficient than [nx1])
	void			setDims( const int mRows, const int nCols );
	void			setDims( const int mRows, const int nCols, const T val );
	void			changeDims( const int mRows, const int nCols );
	void			getDims( int& mRows, int& nCols ) const { mRows=_mRows; nCols=_nCols; };
	int				rows() const { return _mRows; };
	int				cols() const { return _nCols; };
	int				numel() const { return _mRows*_nCols; };

	// indexing into matrix X via X(r,c) or X(ind)
	T&				operator() (const int index ) const;
	T&				operator() (const int index );
	T&				operator() (const int row, const int col ) const;
	T&				operator() (const int row, const int col );

	// implementation of Savable
	virtual const char*		getCname() const;
	virtual void			toObjImg( ObjImg &oi, const char *name ) const;
	virtual void			frmObjImg( const ObjImg &oi, const char *name=NULL );
	virtual bool			customMxArray() const { return 1; }
	virtual mxArray*		toMxArray() const;
	virtual void			frmMxArray( const mxArray *M );

	// write/read text (as array of numbers, different from Savable to/frmFile)
	void			toTxtFile( const char* file, char* delim="," );
	void			frmTxtFile( const char* file, char* delim="," );

	// basic matrix operations
	Matrix&			zero();									// set this matrix to be zero matrix
	Matrix&			setVal( T val );						// sets every element in matrix to have val
	Matrix&			identity();								// set this matrix to be identity matrix
	Matrix&			transpose();							// matrix transpose
	Matrix&			absolute();								// absolute val of matrix
	void			rot90( Matrix &B, int k=1 ) const;		// rotate matrix clockwise by k*90 degrees
	void			flipud( Matrix &B ) const;				// flip matrix vertically
	void			fliplr( Matrix &B ) const;				// flip matrix horizontally
	void			reshape( Matrix &B, int mRows, int nCols ) const; // reshape, numel can't change
	Matrix			multiply( const Matrix &B ) const;		// standard matrix multiplication
	T				prod() const;							// product of elements
	T				sum() const;							// sum of elements
	T				trace() const;							// trace
	T				min() const;							// matrix min
	T				max() const;							// matrix max
	int				maxi() const;							// max index
	int				mini() const;							// min index

	// Pointwise (Matrix OP Matrix), (Matrix<T> OP T) and (T OP Matrix<T>) operators
	// Example: C=A/B - C(i)=A(i)/B(i) for all i
	// Example: C=A*B - C(i)=A(i)*B(i) for all i (use C=A.multiply(B) for standard matrix mult)
	// Example: B=A+(A==0)*10 - set all 0 elements to 10
	// "^" - means power, uses "pow" call (careful has low precedence)
#define DOP(OP) \
	Matrix operator OP ( const Matrix &b ) const; \
	Matrix operator OP ( const T &b ) const; \
	template<class T1> friend Matrix<T1> operator OP ( const T1 &a, const Matrix<T1> &b );
	DOP(+); DOP(-); DOP(/); DOP(*); DOP(^); DOP(<); DOP(>); DOP(<=); DOP(>=); DOP(&&); DOP(||); DOP(==); DOP(!=);
#undef DOP

	// Pointwise assignment operators
#define DOP(OP) \
	Matrix& operator OP (const T b); \
	Matrix& operator OP (const Matrix &b);
	DOP(+=); DOP(-=); DOP(*=); DOP(/=);
#undef DOP

protected:
	T		*_data;
	T		**_dataInd;
	int		_mRows, _nCols;
};

// copy matricies of possibly varying type
template<class T1, class T2> void copy(Matrix<T1>& Mdest,const Matrix<T2>& Msrc);

// matrix display
template<class T> ostream& operator<<(ostream& os, const Matrix<T>& x);

// place actual implementation in separate file for readability
#include "MatrixImp.h"

#endif
