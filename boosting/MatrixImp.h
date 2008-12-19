/**************************************************************************
* Matrix implementation (split from Matrix.h for clarity).
*
* Piotr's Image&Video Toolbox      Version NEW
* Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
* Please email me if you find bugs, or have suggestions or questions!
* Licensed under the Lesser GPL [see external/lgpl.txt]
**************************************************************************/
#ifndef _MATRIXIMPL_H
#define _MATRIXIMPL_H

template<class T1, class T2> void copy(Matrix<T1>& Mdest,const Matrix<T2>& Msrc)
{
	Mdest.setDims(Msrc.rows(), Msrc.cols());
	for(int i=0; i<Msrc.rows(); i++)
		for(int j=0; j<Msrc.cols(); j++)
			Mdest(i,j) = (T1) (Msrc(i,j));
}

template<class T> ostream& operator<<(ostream& os, const Matrix<T>& x)
{
	os << "[";
	for(int i=0; i<x.rows(); i++) {
		for(int j=0; j<x.cols(); j++) os << x(i,j) << " ";
		if( i!=x.rows()-1 ) os << "\n";
	}
	os << "]";
	return os;
}

///////////////////////////////////////////////////////////////////////////////
template<class T>				Matrix<T>::Matrix(int mRows, int nCols)
{
	init(); setDims(mRows, nCols);
}

template<class T>				Matrix<T>::Matrix(int mRows, int nCols, T val )
{
	init(); setDims(mRows, nCols, val);
}

template<class T>				Matrix<T>::Matrix(const Matrix& x)
{
	init(); setDims(x._mRows, x._nCols);
	for(int i=0; i<numel(); i++) (*this)(i) = x(i);
}

template<class T> void			Matrix<T>::init()
{
	_mRows=_nCols=0; _data=NULL; _dataInd=NULL;
}

template<class T> void			Matrix<T>::clear()
{
	if(_data != NULL) delete[] _data;
	if(_dataInd != NULL) delete [] _dataInd;
	_mRows=_nCols=0; _data=NULL; _dataInd=NULL;
}

template<class T> Matrix<T>&	Matrix<T>::operator= (const Matrix<T> &x )
{
	if( this != &x ) {
		setDims( x.rows(), x.cols() );
		for(int i=0; i<numel(); i++) (*this)(i)=x(i);
	}
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::operator= (const vector<T> &x)
{
	setDims( x.numel(), 1 );
	for(int i=0; i<rows(); i++) (*this)(i)=x[i];
	return *this;
}

///////////////////////////////////////////////////////////////////////////////
template<class T> bool			Matrix<T>::setDims(const int mRows, const int nCols)
{
	assert(mRows>=0 && nCols>=0);
	if(mRows==_mRows && nCols==_nCols) return true;
	clear(); _mRows=mRows; _nCols=nCols;
	if(_mRows==0 || _nCols==0) return true;

	try {
		_data = new T[numel()];
		_dataInd = new T*[_mRows];
	} catch( bad_alloc& ) {
		cout << "Matrix::setDims(..) OUT OF MEMORY" << endl;
		clear(); return false;
	}

	for(int i=0; i<_mRows; i++) _dataInd[i]=&(_data[_nCols*i]);
	return true;
}

template<class T> bool			Matrix<T>::setDims(const int mRows, const int nCols, const T val )
{
	if(!setDims(mRows,nCols)) return false;
	setVal(val); return true;
}

template<class T> bool			Matrix<T>::changeDims(const int mRows, const int nCols)
{
	if(mRows==rows() && nCols==cols()) return true;

	T *data=NULL, **dataInd=NULL;
	try{
		data = new T[mRows*nCols];
		dataInd = new T*[mRows];
	} catch( bad_alloc& ) {
		cout << "Matrix::changeDims(..) OUT OF MEMORY" << endl;
		clear(); return false;
	}

	for(int i=0; i<mRows; i++) dataInd[i] = &(data[nCols*i]);
	for(int i=0; i<std::min(rows(),mRows); i++)
		for(int j=0; j<std::min(cols(),nCols); j++)
			dataInd[i][j] = (*this)(i,j);

	clear();
	_mRows=mRows; _nCols=nCols;
	_data=data; _dataInd=dataInd;
	return true;
}

///////////////////////////////////////////////////////////////////////////////
template<class T> inline T&		Matrix<T>::operator() ( const int row, const int col )
{
	return _dataInd[row][col];
}

template<class T> inline T&		Matrix<T>::operator() ( const int row, const int col ) const
{
	return _dataInd[row][col];
}

template<class T> inline T&		Matrix<T>::operator() ( const int ind )
{
	return _data[ind];
}

template<class T> inline T&		Matrix<T>::operator() ( const int ind ) const
{
	return _data[ind];
}

///////////////////////////////////////////////////////////////////////////////
template<class T> const char*	Matrix<T>::getCname() const
{
	static char cname[32];
	sprintf(cname,"Matrix<%s>",PRIMNAME(T));
	return cname;
}

template<class T> void			Matrix<T>::toObjImg( ObjImg &oi, const char *name ) const
{
	oi.init(name,getCname(),3);
	oi._children[0].frmPrim("mRows",&_mRows);
	oi._children[1].frmPrim("nCols",&_nCols);
	oi._children[2].frmPrim("data",_data,numel());
}

template<class T> void			Matrix<T>::frmObjImg( const ObjImg &oi, const char *name )
{
	clear(); oi.check(name,getCname(),3,3);
	int mRows; oi._children[0].toPrim("mRows",&mRows);
	int nCols; oi._children[1].toPrim("nCols",&nCols);
	if(mRows && nCols) setDims(mRows,nCols); else return;
	oi._children[2].toPrim("data",_data);
}

template<class T> mxArray*		Matrix<T>::toMxArray() const
{
#ifdef MATLAB_MEX_FILE
	mxClassID id = ObjImg::getClassId( PRIMNAME(T) );
	mxArray *M = mxCreateNumericMatrix(_mRows,_nCols,id,mxREAL);
	memcpy(mxGetData(M),_data,sizeof(T)*numel()); return M;
#else
	return NULL;
#endif
}

template<class T> void			Matrix<T>::frmMxArray( const mxArray *M )
{
#ifdef MATLAB_MEX_FILE
	setDims( mxGetM(M), mxGetN(M) );
	memcpy(_data,mxGetData(M),sizeof(T)*numel());
#endif
}

template<class T> bool			Matrix<T>::toTxtFile( const char *fName, char *delim )
{
	remove( fName );
	ofstream strm; strm.open(fName, std::ios::out);
	if(strm.fail()) { abortError( "unable to write:", fName, __LINE__, __FILE__ ); return false; }
	for(int r=0; r<rows(); r++ ) {
		for(int c=0; c<cols(); c++ ) {
			strm << (*this)(r,c);
			if( c<(cols()-1)) strm << delim;
		}
		strm << endl;
	}
	strm.close(); return true;
}

template<class T> bool			Matrix<T>::frmTxtFile( const char *fName, char *delim )
{
	ifstream strm; strm.open(fName, std::ios::in);
	if( strm.fail() ) return false;
	char * tline = new char[40000000];

	// get number of cols
	strm.getline( tline, 40000000 );
	int nCols = ( strtok(tline," ,")==NULL ) ? 0 : 1;
	while( strtok(NULL," ,")!=NULL ) nCols++;

	// read in each row
	strm.seekg( 0, ios::beg );
	Matrix<T> *rowVec; vector<Matrix<T>*> allRowVecs;
	while(!strm.eof() && strm.peek()>=0) {
		strm.getline( tline, 40000000 );
		rowVec = new Matrix<T>(1,nCols);
		(*rowVec)(0,0) = (T) atof( strtok(tline,delim) );
		for(int col=1; col<nCols; col++ )
			(*rowVec)(0,col) = (T) atof( strtok(NULL,delim) );
		allRowVecs.push_back( rowVec );
	}
	int mRows = allRowVecs.size();

	// finally create matrix
	setDims(mRows,nCols);
	for(int row=0; row<mRows; row++ ) {
		rowVec = allRowVecs[row];
		for(int col=0; col<nCols; col++ )
			(*this)(row,col) = (*rowVec)(0,col);
		delete rowVec;
	}
	allRowVecs.clear(); delete [] tline;
	strm.close(); return true;
}

///////////////////////////////////////////////////////////////////////////////
template<class T> Matrix<T>&	Matrix<T>::zero()
{
	if(_data!=NULL) memset(_data,0,sizeof(T)*numel());
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::setVal(T val)
{
	if(val==0) return zero();
	if(_data!=NULL) for(int i=0; i<numel(); i++) (*this)(i)=val;
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::identity()
{
	zero();
	for(int i=0; i<std::min(rows(),cols()); i++) (*this)(i,i)=1;
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::transpose()
{
	Matrix tmp(_nCols, _mRows);
	for(int i=0; i<_nCols; i++)
		for(int j=0; j<_mRows; j++)
			tmp(i,j) = (*this)(j,i);
	(*this) = tmp;
	return *this;
}

template<class T> Matrix<T>&	Matrix<T>::absolute()
{
	T z; z=0;
	for(int i=0; i<numel(); i++)
		if((*this)(i)<z) (*this)(i)=z-(*this)(i);
	return (*this);
}

template<class T> void			Matrix<T>::rot90( Matrix<T> &B, int k) const
{
	int i,j;
	k=k%4; if(k<0) k+=4;
	if(k==1) {
		B.setDims(_nCols,_mRows);
		for(i=0; i<_nCols; i++) for(j=0; j<_mRows; j++)
			B(i,j) = (*this)(j, _nCols-i-1);
	} else if(k==2) {
		B.setDims(_mRows,_nCols);
		for(i=0; i<_nCols; i++) for(j=0; j<_mRows; j++)
			B(j,i) = (*this)(_mRows-j-1, _nCols-i-1);
	} else if(k==3) {
		B.setDims(_nCols,_mRows);
		for(i=0; i<_nCols; i++) for(j=0; j<_mRows; j++)
			B(i,j) = (*this)( _mRows-j-1, i);
	} else {
		B = *this;
	}
}

template<class T> void			Matrix<T>::flipud( Matrix<T> &B) const
{
	B.setDims(_mRows,_nCols);
	for(int i=0; i<_mRows; i++)
		for(int j=0; j<_nCols; j++)
			B(i,j) = (*this)(_mRows-i-1,j);
}

template<class T> void			Matrix<T>::fliplr( Matrix<T> &B) const
{
	B.setDims(_mRows,_nCols);
	for(int i=0; i<_mRows; i++)
		for(int j=0; j<_nCols; j++)
			B(i,j) = (*this)(i,_nCols-j-1);
}

template<class T> void			Matrix<T>::reshape( Matrix<T> &B, int mRows, int nCols ) const
{
	if( mRows*nCols != rows()*cols() ) {
		abortError( "product of rows*cols cannot change", __LINE__, __FILE__ ); return;
	}
	B.setDims( mRows, nCols );
	for(int i=0; i<numel(); i++ )
		B(i) = (*this)(i);
}

template<class T> Matrix<T>		Matrix<T>::multiply( const Matrix<T> &B ) const
{
	assert( cols()==B.rows() );
	int mRow=rows(), nCol=B.cols(), kCol=cols();
	Matrix<T> C(mRow,nCol,0);
	for(int i=0; i<mRow; i++)
		for(int j=0; j<nCol; j++)
			for(int k=0; k<kCol; k++)
				C(i,j) += (*this)(i,k)*B(k,j);
	return C;
}

template<class T> T				Matrix<T>::prod() const
{
	T val; val=1;
	for(int i=0; i<numel(); i++) val*=(*this)(i);
	return val;
}

template<class T> T				Matrix<T>::sum() const
{
	T val; val=0;
	for(int i=0; i<numel(); i++) val+=(*this)(i);
	return val;
}

template<class T> T				Matrix<T>::trace() const
{
	T val; val=0;
	for(int i=0; i<std::min(rows(),cols()); i++) val+=(*this)(i,i);
	return val;
}

template<class T> T				Matrix<T>::min() const
{
	if(numel()==0) return (T) 0; T val=(*this)(0);
	for(int i=1; i<numel(); i++) if((*this)(i)<val)
		val=(*this)(i);
	return val;
}

template<class T> int			Matrix<T>::mini() const
{
	if(numel()==0) return 0; int ind=0; T val=(*this)(0);
	for(int i=1; i<numel(); i++) if((*this)(i)<val ) {
		ind=i; val=(*this)(i);
	}
	return ind;
}

template<class T> T				Matrix<T>::max() const
{
	if(numel()==0) return (T) 0; T val=(*this)(0);
	for(int i=1; i<numel(); i++) if((*this)(i)>val)
		val = (*this)(i);
	return val;
}

template<class T> int			Matrix<T>::maxi() const
{
	if(numel()==0) return 0; int ind=0; T val=(*this)(0);
	for(int i=1; i<numel(); i++) if((*this)(i)>val) {
		ind=i; val=(*this)(i);
	}
	return ind;
}

///////////////////////////////////////////////////////////////////////////////
template<class T> Matrix<T>		Matrix<T>::operator^ ( const Matrix<T> &b ) const
{
	Matrix<T> c(rows(),cols());
	for(int i=0; i<numel(); i++) c(i)=(T) pow((double)(*this)(i),(double)b(i)); return c;
}

template<class T> Matrix<T>		Matrix<T>::operator^ ( const T &b ) const
{
	Matrix<T> c(rows(),cols());
	for(int i=0; i<numel(); i++) c(i)=(T) pow((double)(*this)(i),(double)b); return c;
}

template<class T> Matrix<T>		operator^ (const T &a, const Matrix<T> &b )
{
	Matrix<T> c(b.rows(),b.cols());
	for(int i=0; i<b.numel(); i++) c(i)=(T) pow((double)a,(double)b(i)); return c;
}

#define DOP(OP) \
	template<class T> Matrix<T> Matrix<T>::operator OP ( const Matrix<T> &b ) const { \
	Matrix<T> c(rows(), cols()); for(int i=0; i<numel(); i++) c(i)=(*this)(i) OP b(i); return c; } \
	template<class T> Matrix<T> Matrix<T>::operator OP (const T &b ) const { \
	Matrix<T> c(rows(),cols()); for(int i=0; i<numel(); i++) c(i)=(*this)(i) OP b; return c; } \
	template<class T> Matrix<T> operator OP (const T &a, const Matrix<T> &b ) { \
	Matrix<T> c(b.rows(),b.cols()); for(int i=0; i<b.numel(); i++) c(i)=a OP b(i); return c; }
DOP(+); DOP(-); DOP(/); DOP(*); DOP(<); DOP(>); DOP(<=); DOP(>=); DOP(&&); DOP(||); DOP(==); DOP(!=);
#undef DOP

#define DOP(OP) \
	template<class T> Matrix<T>& Matrix<T>::operator OP (const T b ) { \
	for(int i=0; i<numel(); i++) (*this)(i) OP b; return *this; } \
	template<class T> Matrix<T>& Matrix<T>::operator OP (const Matrix<T> &b ) { \
	for(int i=0; i<numel(); i++) (*this)(i) OP b(i); return *this; }
DOP(+=); DOP(-=); DOP(*=); DOP(/=);
#undef DOP

#endif
