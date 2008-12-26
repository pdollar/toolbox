#include "ChImage.h"
#include "FreeImage.h"

///////////////////////////////////////////////////////////////////////////////
void				ChImage::clear()
{
	_images.clear();
}

ChImage&			ChImage::operator= ( const ChImage &x )
{
	if( this != &x ) {
		_images.resize( x.nCh() );
		for( int ch=0; ch<nCh(); ch++ )
			_images[ch]=x._images[ch];
	}
	return *this;
}

///////////////////////////////////////////////////////////////////////////////
FIBITMAP* GenericLoader(const char* fName, int flag)
{
	// Generic image loader
	//   @param fName Pointer to the full file name
	//   @param flag Optional load flag constant
	//   @return Returns the loaded dib if successful, returns NULL otherwise

	// check file signature and deduce its format
	// (second argument is currently not used by FreeImage)
	FREE_IMAGE_FORMAT fif = FIF_UNKNOWN;
	//fif = FreeImage_GetFileType(fName, 0);
	if(fif == FIF_UNKNOWN) {
		// no signature?  // try to guess the file format from the file extension
		fif = FreeImage_GetFIFFromFilename(fName);
	}
	// check that the plugin has reading capabilities ...
	if((fif != FIF_UNKNOWN) && FreeImage_FIFSupportsReading(fif)) 	{
		// ok, let's load the file, unless a bad file format, we are done!
		FIBITMAP *dib = FreeImage_Load(fif, fName, flag);
		return dib;
	}
	return NULL;
}

bool GenericWriter(FIBITMAP* dib, const char* fName, int flag)
{
	// Generic image writer
	//   @param dib Pointer to the dib to be saved
	//   @param fName Pointer to the full file name
	//   @param flag Optional save flag constant
	//   @return Returns true if successful, returns false otherwise

	FREE_IMAGE_FORMAT fif = FIF_UNKNOWN;
	BOOL bSuccess = FALSE;
	if(dib) {
		// try to guess the file format from the file extension
		fif = FreeImage_GetFIFFromFilename(fName);
		if(fif != FIF_UNKNOWN ) {
			// check that the plugin has sufficient writing and export capabilities ...
			WORD bpp = FreeImage_GetBPP(dib);
			if(FreeImage_FIFSupportsWriting(fif) && FreeImage_FIFSupportsExportBPP(fif, bpp)) {
				// ok, we can save the file, unless an abnormal bug, we are done
				bSuccess = FreeImage_Save(fif, dib, fName, flag);
			}
		}
	}
	return (bSuccess == TRUE) ? true : false;
}

void				ChImage::save( const char *fName )
{
	//Matrixf image;
	//toVisible( image );
	//return image.Save( fName );
}

void				ChImage::load( int nCh, const char *fName )
{
	//int success;
	//if( nCh==1 ) {
	//	init( 1 );
	//	success = _images[0].Load( fName );
	//} else {
	//	Matrixu image;
	//	success = image.Load( fName );
	//	if( success==0 ) return 0;
	//	int nCol = image.cols();
	//	if( nCol%nCh > 0 ) return 0;

	//	// allocate memory, copy from flat array to _images
	//	init( nCh );
	//	int wd = nCol/nCh, ht = image.rows(), wSt = 0;
	//	for( int ch=0; ch<nCh(); ch++ ) {
	//		image.Crop( _images[ch], wSt, wSt+wd-1, 0, ht-1 ); wSt += wd;
	//	}
	//}
}

void				ChImage::toVisible( Matrixf &image )
{
	//if( !initialized() ) abortError( "No image data.", __LINE__, __FILE__ );
	//Matrixu imageu = _images[0];
	//for( int ch=1; ch<nCh(); ch++ )
	//	_images[ch].AppendRight( Matrixu(imageu), imageu );
	//Copy( image, imageu );
}

///////////////////////////////////////////////////////////////////////////////
void				ChImage::set( VecMatrixu &images )
{
	// use images directly without copying
	clear(); _images=images; validateSizes();
}

void				ChImage::validateSizes()
{
	if(nCh()<=1) return; int wd=cols(), ht=rows();
	for( int ch=1; ch<nCh(); ch++ ) {
		int wd1=_images[ch].cols(), ht1=_images[ch].rows();
		if( wd!=wd1 || ht!=ht1 ) {
			string err = "[wd0="+int2str(wd,3) + " ht0="+int2str(ht,3);
			err += " wd1="+int2str(wd1,3) + " ht1"+int2str(ht1,3) +"]";
			error( "Inconsistent sizes", err.c_str() );
		}
	}
}
