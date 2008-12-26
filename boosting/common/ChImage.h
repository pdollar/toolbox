#ifndef _CHIMAGE_H
#define _CHIMAGE_H

#include "Common.h"
#include "Savable.h"
#include "Matrix.h"

typedef vector<Matrixu>		VecMatrixu;

class ChImage
{
public:
	// constructors, destructor and assignment
	ChImage() {};
	ChImage( const ChImage &x ) { *this=x; }
	~ChImage() { clear(); };
	void					clear();
	ChImage&				operator= ( const ChImage &x );

	// get basic properties
	int						cols()				const { return _images[0].cols(); }
	int						rows()				const { return _images[0].rows(); }
	int						numel()				const { return _images[0].numel(); };
	int						nCh()				const { return int(_images.size()); };
	const Matrixu&			getImage( int c )	const { return _images[c]; }

	// reading and writing to disk
	void					save( const char *fName );
	void					load( int nCh, const char *fName );
	void					toVisible( Matrixf &image );
	void					set( VecMatrixu &images );

private:
	void					validateSizes();

private:
	VecMatrixu				_images;
};

#endif
