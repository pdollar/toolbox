#ifndef _MULTIIMAGE_H_
#define _MULTIIMAGE_H_

#include "Matrix.h"
#include "ColorImage.h"
#include "IntegralImage.h"

class MultiImage;
class MultiImagePrms;
typedef vector<MultiImage> vectorMi;

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// DIRECTORY NAMING/LOCATION:
//		_dataDir		= "c:/pos";		// data subdirs [each ends in an index]
//		_dirFirst		= 0;			// first dir index
//		_dirLast		= 0;			// last dir index
//		_nDirDigits		= 2;			// number of digits in directory index
// FILE NAMING:
//		_baseName		= "I";			// each image starts with "I"
//		_indFirst		= 0;			// first image index [assumed same for EACH subdir]
//		_indLast		= 99;			// last image index [assumed same for EACH subdir]
//		_nDigits		= 5;			// is followed by a 5 digit number
//		_extn			= ".png";		// and ends with ".png"
// EXPECTED FILE NAMES:
//		"c:/pos00/I00000.png", "c:/pos00/I00001.png", ..., "c:/pos00/I00099.png"
class ImageDataLoc
{
public:
							ImageDataLoc() { clear(); }
	
	ImageDataLoc&			operator=(const ImageDataLoc &a);

	string					getDescr( char *dataType );

	char*					getDirName( ushort dirInd );

	char*					getFileName( ushort dirInd, ushort fileInd );

	ushort					nDirs() { return (_dirLast-_dirFirst+1); }

	ushort					nImages() { return (_indLast-_indFirst+1); }

	void					clear();

public:
	string					_dataDir;
	ushort					_dirFirst;
	ushort					_dirLast;
	ushort					_nDirDigits;

	string					_baseName;
	ushort					_indFirst;
	ushort					_indLast;
	ushort					_nDigits;
	string					_extn;

private:
	char					_formatStr[512];
	char					_fName[512];
};

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// A MultiImage is an image that consists of multiple channels, where each ch is an image and 
// all chs have the same dimensions. Also, each ch optionally has an associated IntegralImage. 
// Example chs can include the original image (1 ch), RGB color chs (3 chs), Canny edges at a 
// given scale (1 ch), and so on. To convert a set of regular images into a MultiImage use 
// merge (which merges a set of MultiImages into a single MultiImage, in this case the original 
// images are essentially MultiImages w 1 ch). To generate standard channels automatically from
// a regular image use makeChs(MultiImagePrms). Finally, many of the functions F that can be 
// applied to the Matrix class can also be applied to MultiImages. Note however that F(MI(X)) 
// may not be the same as MI(F(X)), where X is some Matrix, and MI(X) the MultiImage created 
// from X. Consider for example F=rotation and MI(X) includes oriented filter responses such as 
// dX, then F(dX(X))!=dX(F(X)).
class MultiImage 
{
public:
							MultiImage();

							MultiImage( const MultiImage &x );

							~MultiImage();

	MultiImage&				operator= ( const MultiImage &x );

	void					freeMemory();

	void					allocateMemory( int nCh );

	bool					save( const char *fName );

	int						load( int nCh, const char *fName );

	void					toVisible( Matrixf &image );

public:
	void					initialize();

	int						initialized() const { return _init; };

	int						cols() const { return _images[0].cols(); }

	int						rows() const { return _images[0].rows(); }

	int						size() const { return _images[0].size(); };

	int						nCh() const { return _nCh; };

	void					setRoi( int lf, int tp, int rt, int bt );

	void					getRoi( int &lf, int &tp, int &rt, int &bt ) const;

	Matrixu&				getImage( int c ) const { return _images[c]; }

	IntegralImage&			getII( int c ) const { return _IIs[c]; }

	IntegralImage*			getIIp( int c ) const { return &_IIs[c]; }

	void					prepareIIs();

	void					clearIIs();

	void					set( Matrixu *images, int nCh );

public: 
	void					makeChs( const ColorImage &src, MultiImagePrms prms );

	static void				makeChs( ImageDataLoc src, ImageDataLoc dest, MultiImagePrms prms );

	static void				merge( const MultiImage *src, int nSrc, MultiImage &T );

	static void				merge( ImageDataLoc *src, int *nCh, int nSrc, ImageDataLoc &tar );

public:
	vectori					samplePatches( Matrixd &prob, MultiImage *patches, 
								int wd, int ht, int &nSample, bool pad=true ) const;

	void					appendRight( const MultiImage &A, MultiImage &B ) const;

	// with macro define MultiImage::FUNC that applies Matrix::FUNC to each channel of MultiImage.
	#define MI_HEADER( FUNC, ... ); \
		void FUNC( MultiImage &B, __VA_ARGS__ ) const
		MI_HEADER( PadReplicate, int amount );
		MI_HEADER( PadReplicate, int lf, int rt, int tp, int bt );
		MI_HEADER( Crop, int lf, int rt, int tp, int bt );
		MI_HEADER( CropCenter, int mrows, int ncols );
		MI_HEADER( Resize, int mrows, int ncols, int flag=1 );
		MI_HEADER( Resize, float rowRatio, float colRatio, int flag=1 );
		MI_HEADER( Rotate, double angle, int flag = 1 );
		MI_HEADER( RotateCrop, double angle, int flag = 1 );
	#undef MI_HEADER

private:
	void					validateSizes( int line, char *file );

private:
	int						_nCh;

	int						_init;

	Matrixu					*_images;

	IntegralImage			*_IIs;
};

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// USAGE: 
// _useChs[i] = depth;
//	if depth==0, channel [i] will not be used
//	if depth>1, channel [i] will be split up into (depth) histogram bin channels
//
// CHANNELS:
//	[0]		grayscale
//	[1-3]	LUV color channels
//	[4-6]	HSV color channels
//	[7]		gradient magnitude
//	[8]		gradient angle (if depth > 1, will build a HOG)
//	[9-10]	cos/sin( gradient angle )
//	[11]	harris response map
//
// OTHER PARAMS:
//	_resRatio	- [1.0f] ratio by which to resize original image 
//	_sigma		- [0.0f] amount to smooth original image
//	_crop		- [0] total amount to crop from both sides (to avoid boundary affects)
class MultiImagePrms
{
public:
							MultiImagePrms();

	int						nCh();

	int						nChUsed();

	void					getUseChs(int *useChs);

	string					getDescr();

	void					writeToStrm(ofstream &strm);

	void					readFrmStrm(ifstream &strm);

public:
	int						_useChs[1024];

	float					_resRatio;

	float					_sigma;

	int						_crop;
};

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

class ImageCache
{
public:
	// cacheFlag 0:[no cache] 1:[cache images] 2:[cache all]
							ImageCache( int cacheFlag, int nChannels );

	// creates deep copy
	ImageCache&				operator=(const ImageCache &a);

	// resets cache (removes pointers to all data)
	void					reset();

	// create placeholder in cache for images (returns dirI of first dir added)
	ushort					addData( ImageDataLoc &data );

	// create placeholder for given directory
	ushort					addData( string dirName, string formatStr, ushort indFirst, ushort indLast );

	// get dirI for given dirName (USHRT_MAX if dirName not in cache)
	ushort					getDirInd( string dirName );

	// gets image from cache, loading from disk if necessary
	MultiImage*				getImage( ushort dirI, ushort fileI );

	// gets image file name
	const char*				getImageFname( ushort dirI, ushort fileI );

	// clears current MultiImage from memory according to cacheFlag (see above)
	void					clearCurrent( int cacheFlag );

	// clears all MultiImages from memory according to cacheFlag (see above)
	void					clearAll( int cacheFlag );

private:
	vectorString			_dirNames;
	vectorString			_formatStrs;
	vectorus				_indFirst;

	int						_nCh;
	int						_cacheFlag;
	ushort					_curFileI;
	ushort					_curDirI;
	vector<vectorMi>		_images;
	char					_fName[1024];
};

#endif