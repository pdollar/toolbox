#ifndef _MATRIX_H
#define _MATRIX_H

#include "Public.h"
template< class T > class Matrix;
typedef Matrix< float >	Matrixf;
typedef Matrix< double > Matrixd;
typedef Matrix< int > Matrixi;
typedef Matrix< uchar >	Matrixu;

template<class T> class Matrix
{
public:

	// constructors, destructor and assignment
	Matrix();
	Matrix( int rows, int cols );
	Matrix( int rows, int cols, T value );
	Matrix( const Matrix& x );
	~Matrix();
	virtual void	Free(); 
	Matrix<T>&		operator= (const Matrix<T> &x );
	Matrix<T>&		operator= (const vector<T> &x );

	// write/read to/from stream/text
	void			writeToStrm(ofstream &strm);
	void			readFrmStrm(ifstream &strm);
	virtual bool	writeToTxt( const char* file, char* delim="," );
	virtual bool	readFromTxt( const char* file, char* delim="," ); 

	// dimensions / access (note: [1xn] vectors more eff than [nx1])
	bool			setDims( const int rows, const int cols );
	bool			setDims( const int rows, const int cols, const T value );
	void			getDims( int& rows, int& cols )	const { rows=_mrows; cols=_ncols; };
	bool			resizeTo( const int rows1, const int cols1 );
	bool			valid( const int row, const int col ) const;
	bool			valid( const int index ) const;
	int				rows() const { return _mrows; };
	int				cols() const { return _ncols; };
	int				size() const { return _mrows*_ncols; };
	T&				operator() (const int index ) const; 
	T&				operator() (const int index ); 
	T&				operator() (const int row, const int col ) const;
	T&				operator() (const int row, const int col );
		
	// basic matrix operations
	Matrix&			zero();									// set this matrix to be zero matrix
	Matrix&			setVal( T value );						// sets every element in matrix to have value
	Matrix&			identity();								// set this matrix to be identity matrix
	Matrix&			transpose();							// matrix transpose
	Matrix&			absolute();								// absolute value of matrix
	void			rotate90( Matrix &B, int K=1) const;	// rotate matrix by 90,180, or 270 degrees
	void			flipHoriz( Matrix<T> &B) const;			// flip matrix horizontally
	void			flipVert( Matrix<T> &B) const;			// flip matrix vertically
	void			reshape( Matrix &B, int mrows, int ncols ) const;	// reshape to B, product of rows*cols can't change
	T				product() const;						// product of elements
	T				sum() const;							// sum of elements
	T				trace() const;							// trace
	virtual T		min() const;							// matrix min
	virtual T		max() const;							// matrix max
	int				maxi() const;							// max index
	int				mini() const;							// min index

	// pointwise operators (mostly defined with a precompiler script "DOP")
	// For example division is pointwise: C=A/B means C(i)=A(i)/B(i)
	// "*" - ONLY multiplcation of two matricies is NOT pointwise - it is standard matrix multiplication
	// "&" - for pointwise multiplication between matricies use C=A&B; (careful has low precedence)
	// "^" - means power, uses "pow" call (careful has low precedence)
	#define DOP(OP) \
		Matrix operator OP ( const Matrix &b ) const; \
		Matrix operator OP ( const T &b ) const; \
		template<class T1> friend Matrix<T1> operator OP ( const T1 &a, const Matrix<T1> &b ); 
		DOP(+); DOP(-); DOP(/); DOP(*); DOP(^); DOP(<); DOP(>); DOP(<=); DOP(>=); DOP(&&); DOP(||); DOP(==); DOP(!=); 
	#undef DOP
	Matrix operator& (const Matrix &b ) const;

	// computed assignment (all pointwise)
	#define DOP(OP) \
		Matrix& operator OP (const T b); \
		Matrix& operator OP (const Matrix &b);
		DOP(+=); DOP(-=); DOP(*=); DOP(/=);
	#undef DOP

protected:
	T		*_data ;
	T		**_dataindex;
	int		_mrows, _ncols;
};

///////////////////////////////////////////////////////////////////////////////
template<class T>				Matrix<T>::Matrix()
{
	_mrows = 0;
	_ncols = 0;
	_data = NULL ;
	_dataindex = NULL;
}

template<class T>				Matrix<T>::Matrix(int rows, int cols) 
{
	_mrows = 0;
	_ncols = 0;
	_data = NULL ;
	_dataindex = NULL;
	setDims(rows, cols);
}

template<class T>				Matrix<T>::Matrix(int rows, int cols, T value ) 
{
	_mrows = 0;
	_ncols = 0;
	_data = NULL ;
	_dataindex = NULL;
	setDims(rows, cols, value);
}

template<class T>				Matrix<T>::Matrix(const Matrix& x)
{
	_data = NULL ;
	_dataindex = NULL;
	_mrows = 0;
	_ncols = 0;
	setDims(x._mrows, x._ncols);
	for (int i = 0; i < size(); i++)
		(*this)(i) = x(i);
}

template<class T>				Matrix<T>::~Matrix()
{
	Free();
}

template<class T> void			Matrix<T>::Free()
{
	if (_data != NULL)
		delete[] _data;
	_data = NULL;
	if (_dataindex != NULL)
		delete []_dataindex;
	_dataindex = NULL;
	_mrows = _ncols = 0;
}

template<class T> Matrix<T>&	Matrix<T>::operator= (const Matrix<T> &x )
{
	if ( this != &x ) {
		setDims( x.rows(), x.cols() );
		for (int i = 0; i < size(); i++)
			(*this)(i) = x(i);
	}
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::operator= (const vector<T> &x)
{
	setDims( x.size(), 1 );
	for(int i=0; i<rows(); i++)
		(*this)(i) = x[i];
	return *this;
}

///////////////////////////////////////////////////////////////////////////////
template<class T> void			Matrix<T>::writeToStrm(ofstream &strm)
{
	strm.write((char*)&_mrows, sizeof(_mrows));
	strm.write((char*)&_ncols, sizeof(_ncols));
	strm.write((char*)_data, sizeof(T)*size());
}

template<class T> void			Matrix<T>::readFrmStrm(ifstream &strm)
{
	int row_read, col_read;  Free();
	strm.read((char*)&row_read, sizeof(row_read));
	strm.read((char*)&col_read, sizeof(col_read));
	if (row_read>0 && col_read>0)
		setDims(row_read, col_read);
	strm.read((char*)_data, sizeof(T)*size());
}

template<class T> bool			Matrix<T>::writeToTxt( const char *fname, char *delim )
{
	remove( fname ); 
	ofstream strm; strm.open(fname, std::ios::out);
	if (strm.fail()) { abortError( "unable to write:", fname, __LINE__, __FILE__ ); return false; }
	
	for( int r=0; r<rows(); r++ ) {
		for( int c=0; c<cols(); c++ ) {
			strm << (*this)(r,c);
			if( c<(cols()-1)) strm << delim;
		}
		strm << endl;
	}

	strm.close();
	return true;
}

template<class T> bool			Matrix<T>::readFromTxt( const char *fname, char *delim )
{
	ifstream strm; strm.open(fname, std::ios::in);
	if( strm.fail() ) return false;
	char * tline = new char[40000000];

	// get number of cols
	strm.getline( tline, 40000000 );
	int ncols = ( strtok(tline," ,")==NULL ) ? 0 : 1;
	while( strtok(NULL," ,")!=NULL ) ncols++;
	
	// read in each row
	strm.seekg( 0, ios::beg ); 
	Matrix<T> *rowVec; vector<Matrix<T>*> allRowVecs;
	while(!strm.eof() && strm.peek()>=0) {
		strm.getline( tline, 40000000 );
		rowVec = new Matrix<T>(1,ncols);
		(*rowVec)(0,0) = (T) atof( strtok(tline,delim) );
		for( int col=1; col<ncols; col++ )
			(*rowVec)(0,col) = (T) atof( strtok(NULL,delim) );
		allRowVecs.push_back( rowVec );
	}
	int mrows = allRowVecs.size();

	// finally create matrix
	setDims(mrows,ncols);
	for( int row=0; row<mrows; row++ ) {
		rowVec = allRowVecs[row];
		for( int col=0; col<ncols; col++ )
			(*this)(row,col) = (*rowVec)(0,col);
		delete rowVec;
	}
	allRowVecs.clear();
	delete [] tline;
	strm.close();
	return true;
}


///////////////////////////////////////////////////////////////////////////////
template<class T> bool			Matrix<T>::setDims(const int rows, const int cols)
{
	assert(rows>=0 && cols>=0 );
	if (rows==_mrows && cols==_ncols) return true;
	Free();  _mrows = rows;  _ncols = cols;
	if (_mrows==0 || _ncols==0) return true;

	int lSize = ((int)_mrows) * _ncols;
	try {
		_data = new T[lSize];
		_dataindex = new T*[_mrows];
	} catch( bad_alloc& ) {
		cout << "Matrix::setDims(..)  OUT OF MEMORY" << endl;
		return false;
	}

	for (int i=0; i<_mrows; i++)
		_dataindex[i] = &(_data[_ncols*i]);
	return true;
}

template<class T> bool			Matrix<T>::setDims(const int rows, const int cols, const T value )
{
	if( !setDims(rows,cols) ) 
		return false;
	setVal( value );
	return true;
}

template<class T> bool			Matrix<T>::resizeTo(const int rows1, const int cols1)
{
	if( rows1==rows() && cols1==cols() )
		return true;

	int lsize = (int)rows1*cols1;
	T *data1, **pdata1;
	try{
		data1 = new T[lsize];
		pdata1 = new T*[rows1];
	} catch( bad_alloc& ) {
		cout << "Matrix::resizeTo(..)  OUT OF MEMORY" << endl;
		return false;
	}

	for (int j=0; j<rows1; j++)
		pdata1[j] = &(data1[cols1*j]);
	for (int j=0; j<min((int)rows(),rows1); j++)
		for (int i=0; i<min((int)cols(),cols1); i++)
			pdata1[j][i] = (*this)(j, i);
	Free();
	_mrows = rows1;
	_ncols = cols1;
	_data = data1;
	_dataindex = pdata1;
	return true;
}

template<class T> inline bool	Matrix<T>::valid(const int row, const int col) const
{
	return (row>=0 && row<_mrows && col>=0 && col<_ncols);
}

template<class T> inline bool	Matrix<T>::valid(const int index) const
{
	return (index>=0 && index<size());
}

template<class T> inline T&		Matrix<T>::operator() ( const int row, const int col)
{
	return _dataindex[row][col];
}

template<class T> inline T&		Matrix<T>::operator() ( const int row, const int col) const
{
	return _dataindex[row][col];
}

template<class T> inline T&		Matrix<T>::operator() ( const int index)
{
	return _data[index];
}

template<class T> inline T&		Matrix<T>::operator() ( const int index) const
{
	return _data[index];
}

///////////////////////////////////////////////////////////////////////////////
template<class T> Matrix<T>&	Matrix<T>::zero()
{
	if (_data != NULL)
		memset(_data, 0, sizeof(T)*_mrows*_ncols);
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::setVal(T value)
{
	if (_data != NULL) {
		if( value==0 ) zero(); else
			for (int i = 0; i < size(); i++)
				(*this)(i) = value;
	}
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::identity()
{
	 for (int i = 0; i < rows();  i++)
		for (int j = 0; j < cols();  j++)
			(*this)(i,j) = (i==j) ? 1 : 0;
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::transpose()
{
	Matrix temp;
	temp.setDims(_ncols, _mrows);
	for (int i = 0; i < _ncols; i++)
		for (int j = 0; j < _mrows; j++)
			temp(i, j) = (*this)(j, i);
	(*this) = temp;
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::absolute() 
{
	T z; z = 0;
	for (int i=0; i<size(); i++) {
		if ((*this)(i)<z)	
			(*this)(i) = z-(*this)(i);
		else			
			(*this)(i) = (*this)(i);
	}
	return (*this);
}

template<class T> void			Matrix<T>::rotate90( Matrix<T> &B, int K) const
{
	// rotate90  Rotate Matrix 90 degrees.
	// rotate90() is the 90 degree counterclockwise rotation of Matrix A.
	// rotate90(K) is the K*90 degree rotation of A, K = +-1,+-2,...
	int i,j;
    int k = K%4; if (k < 0) k += 4;
	if (k==1) {
		B.setDims(_ncols,_mrows);
		for( i=0; i < _ncols; i++) for( j=0; j < _mrows; j++)
			B(i, j) = (*this)(j, _ncols-i-1);
	} else if (k==2) {
		B.setDims(_mrows,_ncols);
		for( i=0; i < _ncols; i++) for( j=0; j < _mrows; j++)
			B(j, i) = (*this)(_mrows-j-1, _ncols-i-1);
	} else if (k==3) {
		B.setDims(_ncols,_mrows);
		for( i=0; i < _ncols; i++) for( j=0; j < _mrows; j++)
			B(i, j) = (*this)( _mrows-j-1, i);
	} else {
		B = *this;		
	}
}

template<class T> void			Matrix<T>::flipHoriz( Matrix<T> &B) const
{
	int i,j;
	B.setDims(_ncols,_mrows);
    for( i=0; i<_mrows; i++ )
		for( j=0; j<_ncols; j++ )
			B(i,j) = (*this)(_mrows-i-1,j);
}

template<class T> void			Matrix<T>::flipVert( Matrix<T> &B) const
{
	int i,j;
	B.setDims(_ncols,_mrows);
    for( i=0; i<_mrows; i++ )
		for( j=0; j<_ncols; j++ )
			B(i,j) = (*this)(i,_ncols-j-1);
}

template<class T> void			Matrix<T>::reshape( Matrix<T> &B, int mrows, int ncols ) const
{
	if( mrows*ncols != rows()*cols() ) {
		abortError( "cannot reshape, product of rows & cols has changed", __LINE__, __FILE__ );
		return;
	}
	B.setDims( mrows, ncols );
	for( int i=0; i<size(); i++ )
		B(i) = (*this)(i);
}

template<class T> T				Matrix<T>::product() const
{
	T value; value = 1;
	for (int i=0; i<size(); i++)
		value *= (*this)(i);
	return value;
}

template<class T> T				Matrix<T>::sum() const
{
	T	value;
	value = 0;
	for (int i=0; i<size(); i++)
		value += (*this)(i);
	return value;
}

template<class T> T				Matrix<T>::trace() const
{
	assert(_mrows==_ncols);
	T d; d=0;
	for( int j=0; j<_mrows; j++) 
		d += (*this)(j,j);
	return d;
}

template<class T> T				Matrix<T>::min() const
{
	T value=0;
	if (size()>0) {
		int i;
		value = (*this)(0);
		for (i=1; i<size(); i++)
			if ((*this)(i)<value)
				value = (*this)(i);
	}
	return value;
}

template<class T> int			Matrix<T>::mini() const
{
	int ind=0;
	if (size()>0) {
		T value = (*this)(0);
		for( int i=1; i<size(); i++)
			if ((*this)(i)<value ){
				ind=i;
				value = (*this)(i);
			}
	}
	return ind;
}

template<class T> T				Matrix<T>::max() const
{
	T value=0;
	if (size()>0) {
		int i;
		value = (*this)(0);
		for (i=1; i<size(); i++)
			if ((*this)(i)>value)
				value = (*this)(i);
	}
	return value;
}

template<class T> int			Matrix<T>::maxi() const
{
	int ind=0;
	if (size()>0) {
		int i;
		T value = (*this)(0);
		for (i=1; i<size(); i++)
			if ((*this)(i)>value){
				ind=i;
				value = (*this)(i);
			}
	}
	return ind;
}

///////////////////////////////////////////////////////////////////////////////
template<class T1, class T2> void Copy(Matrix<T1>& Mdest,const Matrix<T2>& Msrc)
{
	Mdest.setDims(Msrc.rows(), Msrc.cols());
	for(int i = 0; i < Msrc.rows(); i++)
		for(int j = 0; j < Msrc.cols(); j++)
			Mdest(i, j) = (T1)(Msrc(i, j));
}

template<class T> ostream&	operator<<(ostream& os, const Matrix<T>& x)
{ //display matrix
	os << "[";
	for (int j=0; j<x.rows(); j++) {
		for (int i=0; i<x.cols(); i++) {
			os << x(j,i) << " ";
		}
		if( j!=x.rows()-1 )
			os << "\n";
	}
	os << "]";
	return os;
}

///////////////////////////////////////////////////////////////////////////////
template<class T> Matrix<T>		Matrix<T>::operator* ( const Matrix<T> &b ) const 
{  //multiply two matrices
	T			sum;
	Matrix<T>	temp;
	int nrow=rows(),ncol=b.cols(),xncol=cols();
	temp.setDims(nrow,ncol);
	for (int i = 0; i < nrow; i++)
		for (int j = 0; j < ncol; j++) {
			sum = 0;
			for(int k = 0; k < xncol; k++)
				sum = sum+(*this)(i, k)*b(k, j); //multiply
			temp(i, j) = sum;
		}
	  return temp;
}

template<class T> Matrix<T>		Matrix<T>::operator& ( const Matrix<T> &b ) const 
{ // matrix pointwise multiplication
	assert(rows()==b.rows() && cols()==b.cols());
	Matrix<T> temp;
	temp.setDims(rows(),cols());
	for (int i=0; i<size(); i++)
		temp(i) = (*this)(i)*b(i);
	return temp;
}

template<class T> Matrix<T>		Matrix<T>::operator^ ( const Matrix<T> &b ) const 
{
	Matrix<T>	temp(rows(),cols());
	int i, n=size();
	for (i=0; i<n; i++)
		temp(i) = pow((*this)(i),b(i));
	return temp;
}

template<class T> Matrix<T>		Matrix<T>::operator^ ( const T &b ) const
{
	Matrix<T> temp(rows(),cols());
	int i, n=size();
	for (i=0; i<n; i++)
		temp(i) = pow((*this)(i),b);
	return temp;
}

template<class T> Matrix<T>		operator^ ( const T a, const Matrix<T> &b )
{
	Matrix<T> temp(b.rows(),b.cols());
	int i, n=b.size();
	for (i=0; i<n; i++)
		temp(i) = pow(a,b(i));
	return temp;
}

// Pointwise (Matrix OP Matrix) operations - except *,&,^
#define DOP(OP) \ 
	template<class T> Matrix<T> Matrix<T>::operator OP ( const Matrix<T> &b ) const { \
        Matrix<T> c (rows(), cols()); \
        for (int i = 0; i < size(); i++) { \
            c(i) = (*this)(i) OP b(i); \
        } \
        return c; \
    } 
	DOP(+); DOP(-); DOP(/); DOP(<); DOP(>); DOP(<=); DOP(>=); DOP(&&); DOP(||); DOP(==); DOP(!=); 
#undef DOP
// Pointwise (Matrix<T> OP T) and (T OP Matrix<T>) operations - except ^
#define DOP(OP) \
	template<class T> Matrix<T> Matrix<T>::operator OP (const T &b ) const { \
        Matrix<T> c (rows(), cols()); \
        for (int i = 0; i < size(); i++) { \
            c(i) = (*this)(i) OP b; \
        } \
        return c; \
    } \
	template<class T> Matrix<T> operator OP (const T &a, const Matrix<T> &b ) { \
        Matrix<T> c (b.rows(), b.cols()); \
        for (int i = 0; i < b.size(); i++) { \
            c(i) = a OP b(i); \
        } \
        return c; \
    } 
	DOP(+); DOP(-); DOP(/); DOP(*); DOP(<); DOP(>); DOP(<=); DOP(>=); DOP(&&); DOP(||); DOP(==); DOP(!=); 
#undef DOP
// assignment operators
#define DOP(OP) \
	template<class T> Matrix<T>& Matrix<T>::operator OP (const T b ) { \
        for (int i = 0; i < size(); i++) \
            (*this)(i) OP b; \
        return *this; \
    } \
	template<class T> Matrix<T>& Matrix<T>::operator OP (const Matrix<T> &b ) { \
        for (int i = 0; i < size(); i++) \
            (*this)(i) OP b(i); \
        return *this; \
    } 
	DOP(+=); DOP(-=); DOP(*=); DOP(/=);
#undef DOP
#endif