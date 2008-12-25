#include "MultiImage.h"
#include "Rand.h"

ImageDataLoc&		ImageDataLoc::operator=(const ImageDataLoc &a)
{
	if (this != &a) {
		_dataDir		= a._dataDir;
		_dirFirst		= a._dirFirst;
		_dirLast		= a._dirLast;
		_nDirDigits		= a._nDirDigits;

		_baseName		= a._baseName;
		_indFirst		= a._indFirst;
		_indLast		= a._indLast;
		_nDigits		= a._nDigits;
		_extn			= a._extn;

		strcpy(_fName,a._fName);
	}
	return *this;
}

string				ImageDataLoc::getDescr( char *dataType )
{
	if( _dataDir.empty() )
		return makeDescr( dataType, "none" );
	else {		
		sprintf( _formatStr, "%s%%0%ii/%s%%0%ii%s", _dataDir.c_str(), _nDirDigits, 
			_baseName.c_str(), _nDigits, _extn.c_str() );
		char descr[1024];
		sprintf( descr, " %-16s= d:%i-%i, n:%i-%i, %s\n", 
			dataType, _dirFirst, _dirLast, _indFirst, _indLast, _formatStr );
		return descr;
	}
}

char*				ImageDataLoc::getDirName( ushort dirInd )
{
	sprintf( _fName, "%s%s", _dataDir.c_str(), int2str(dirInd,_nDirDigits).c_str() );
	return _fName;
}

char*				ImageDataLoc::getFileName( ushort dirInd, ushort fileInd )
{
	sprintf( _formatStr, "%s%%0%ii/%s%%0%ii%s", _dataDir.c_str(), _nDirDigits, 
		_baseName.c_str(), _nDigits, _extn.c_str() );
	sprintf( _fName, _formatStr, dirInd, fileInd );
	return _fName;
}

void				ImageDataLoc::clear()
{
	_dataDir		= "";
	_dirFirst		= 0;
	_dirLast		= 0;
	_nDirDigits		= 2;

	_baseName		= "I";
	_indFirst		= 0;
	_indLast		= 0;
	_nDigits		= 5;
	_extn			= ".png";

	_formatStr[0]	= '\0';
	_fName[0]	= '\0';
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

					MultiImage::MultiImage()
{
	_nCh	= 0;
	_init	= 0;
	_images	= NULL;
	_IIs	= NULL;
}

					MultiImage::MultiImage( const MultiImage &x )
{
	_images	= NULL;
	_IIs	= NULL;
	*this = x;
}

					MultiImage::~MultiImage()
{
	freeMemory();
}

MultiImage&			MultiImage::operator= ( const MultiImage &x )
{
	if( this != &x ) {
		// doesn't copy _IIs
		allocateMemory( x._nCh );
		for( int ch=0; ch<_nCh; ch++ )
			_images[ch] = x._images[ch];
		_init = min(1,x._init);
	}
	return *this;
}

void				MultiImage::freeMemory()
{
	if( _images!=NULL ) delete [] _images; _images = NULL;
	if( _IIs!=NULL ) delete [] _IIs; _IIs = NULL;
	_nCh	= 0;
	_init	= 0;
}

void				MultiImage::allocateMemory( int nCh )
{
	freeMemory();
	_nCh	= nCh;
	_images	= new Matrixu[ _nCh ];
	_IIs	= new IntegralImage[ _nCh ];
}

bool				MultiImage::save( const char *fName )
{
	Matrixf image;
	toVisible( image );
	return image.Save( fName );
}

int					MultiImage::load( int nCh, const char *fName )
{
	int success;
	if( nCh==1 ) {
		allocateMemory( 1 );
		success = _images[0].Load( fName );
	} else {
		Matrixu image;
		success = image.Load( fName );
		if( success==0 ) return 0;
		int nCol = image.cols();
		if( nCol%nCh > 0 ) return 0;

		// allocate memory, copy from flat array to _images
		allocateMemory( nCh );
		int wd = nCol/nCh, ht = image.rows(), wSt = 0;
		for( int ch=0; ch<_nCh; ch++ ) {
			image.Crop( _images[ch], wSt, wSt+wd-1, 0, ht-1 ); wSt += wd;
		}
	}
	_init=1; return success;
}

void				MultiImage::toVisible( Matrixf &image )
{
	if( !initialized() ) abortError( "No image data.", __LINE__, __FILE__ );
	Matrixu imageu = _images[0];
	for( int ch=1; ch<_nCh; ch++ )
		_images[ch].AppendRight( Matrixu(imageu), imageu );
	Copy( image, imageu );
}

void				MultiImage::validateSizes( int line, char *file )
{
	if( _nCh<=1 ) return;
	int wd = cols(); int ht = rows();
	for( int ch=1; ch<_nCh; ch++ )
		if( wd!=_images[ch].cols() || ht!=_images[ch].rows() ) {
			string err = "[wd0=" + int2str(wd,3) + " ht0=" + int2str(ht,3);
			err += " wd1=" + int2str(_images[ch].cols(),3) + " ht1" + int2str(_images[ch].rows(),3) +"]";
			abortError( "Inconsistent sizes", err.c_str(), line, file );
		}
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

void				MultiImage::initialize()
{
	_init = 2;
	for( int k=0; k<_nCh; k++ ) 
		_init = min(_init,(int)(_images[k].size()>0) + (int)(_IIs[k].prepared()));
}

void				MultiImage::setRoi( int lf, int tp, int rt, int bt )
{
	assert( initialized()==2 );
	for( int ch=0; ch<_nCh; ch++ )
		_IIs[ch].setRoi( lf, tp, rt, bt );
}

void				MultiImage::getRoi( int &lf, int &tp, int &rt, int &bt ) const
{
	assert( initialized()==2 );
	_IIs[0].getRoi(lf,tp,rt,bt);
}

void				MultiImage::prepareIIs()
{
	if( initialized()==0 )
		abortError( "MultiImage not initialized", __LINE__, __FILE__ );
	for( int ch=0; ch<_nCh; ch++ )
		_IIs[ch].prepare( _images[ch] );
	_init = 2;
}

void				MultiImage::clearIIs()
{
	if(_init<2) return;
	for( int ch=0; ch<_nCh; ch++ )
		_IIs[ch].clear();
	_init = 1;
}

void				MultiImage::set( Matrixu *images, int nCh )
{
	// use images directly
	freeMemory();
	_nCh	= nCh;
	_images	= images;
	_IIs	= new IntegralImage[ _nCh ];
	_init	= 1;
	validateSizes( __LINE__, __FILE__ );
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

void				MultiImage::makeChs( const ColorImage &src1, MultiImagePrms prms )
{
	int *useChs	= prms._useChs;
	int nCh				= prms.nCh();
	float resRatio		= prms._resRatio;
	float sigma			= prms._sigma;
	int crop			= prms._crop;

	// optional smooth / resize
	ColorImage src, tempc;
	src1.Resize( src, resRatio, resRatio );
	if( prms._sigma!=0.0f ) { src.GaussSmooth( tempc, prms._sigma ); src=tempc; tempc.Free(); }

	Matrixf gray, gradX, gradY, gradAng, gradMag, tempf, colChs[3];
	int c=0; src.ToGray(gray); gray/=255.0f; 
	Matrixf *quantize=new Matrixf[nCh], *nullp=NULL;

	// grayscale [0]
	if( useChs[0]>0 ) {
		if( useChs[0]==1 ) quantize[c]=gray; else
			gray.Quantize( quantize+c, nullp, useChs[0], 0.0, 1.0 );
		c += useChs[0];
	}	

	// get LUV color channels [1-3]
	if( useChs[1]>0 || useChs[2]>0 || useChs[3]>0 ) {
		src.ConvertRgb2Luv(tempc); tempc.GetColorChannels(colChs[0], colChs[1], colChs[2]);
		for( int i=0; i<3; i++ ) if( useChs[i+1]>0 ) {
			if( useChs[i+1]==1 ) quantize[c]=colChs[i]/255; else
				colChs[i].Quantize( quantize+c, nullp, useChs[i+1], 0.0, 255.0 );
			c += useChs[i+1];
		}
	}

	// get HSV color channels [4-6]
	if( useChs[4]>0 || useChs[5]>0 || useChs[6]>0 ) {
		src.ConvertRgb2Hsv(tempc); tempc.GetColorChannels(colChs[0], colChs[1], colChs[2]);
		for( int i=0; i<3; i++ ) if( useChs[i+4]>0 ) {
			if( useChs[i+4]==1 ) quantize[c]=colChs[i]/255; else
				colChs[i].Quantize( quantize+c, nullp, useChs[i+4], 0.0, 255.0 );
			c += useChs[i+4];
		}
	}

	// gradient stuff
	if( useChs[7]>0 || useChs[8]>0 || useChs[9]>0 || useChs[10]>0 ) {
		gray.Gradient( gradX, gradY, gradAng );
		gradMag = ((gradX&gradX)+(gradY&gradY))^(.5f);
		gradX.Free(); gradY.Free();

		// gradient mag 
		if( useChs[7]>0 ) {
			if( useChs[7]==1 ) quantize[c]=gradMag; else
				gradMag.Quantize( quantize+c, nullp, useChs[7], 0.0, 1.0f );
			c += useChs[7];
		}

		// gradient gradAng (or HOG)
		if( useChs[8]>0 ) {
			if( useChs[8]==1 ) quantize[c]=(gradAng+float(PI)/2.0f)/float(PI); else
				gradAng.Quantize( quantize+c, &gradMag, useChs[8], float(-PI)/2.0f, float(PI)/2.0f, true );
			c += useChs[8];
		}

		// cos/sin of gradient gradAng
		for( int i=9; i<=10; i++ ) if( useChs[i]>0 ) {
			tempf.SetDimension(src.rows(),src.cols());
			for( int j=0; j<tempf.size(); j++ ) 
				tempf(j) = (float) ((i==9) ? cos(gradAng(j)) : (sin(gradAng(j))/2.0f+.5f));
			if( useChs[i]==1 ) quantize[c]=tempf; else
				tempf.Quantize( quantize+c, nullp, useChs[i], 0.0, 1.0f );
			c += useChs[i];
		}
	}

	// harris response map
	if( useChs[11]>0 ) {
		gray.Harris(tempf,1.0); tempf*=50; tempf.Threshold(1.0f);
		if( useChs[11]==1 ) quantize[c]=tempf; else
			tempf.Quantize( quantize+c, nullp, useChs[11], 0.0, 1.0f );
		c += useChs[11];
	}

	// create copy of images, free quantize
	allocateMemory( nCh ); _init = 1;
	for( int c=0; c<nCh; c++ ) { Copy(_images[c], quantize[c]*255.0f ); quantize[c].Free(); }
	validateSizes( __LINE__, __FILE__ );
	delete [] quantize;

	// crop bounding regions to avoid boundary effects
	if( crop>0 ) {
		MultiImage temp; temp = *this;
		temp.CropCenter( *this, temp.rows()-crop, temp.cols()-crop );
	}
}

void				MultiImage::makeChs( ImageDataLoc src, ImageDataLoc dest, MultiImagePrms prms )
{
	dest._dirFirst	= src._dirFirst;
	dest._dirLast	= src._dirLast;
	dest._indFirst	= src._indFirst;
	dest._indLast	= src._indLast;
	MultiImage res; ColorImage im, im1; char *fName;
	StopWatch sw, swt(true); bool success;
	for( ushort k=src._dirFirst; k<=src._dirLast; k++ ){
		sw.Reset(true);
		_mkdir( dest.getDirName(k) );
		for( ushort j=src._indFirst; j<=src._indLast; j++ ) {			
			fName = src.getFileName(k,j); success = im.Load( fName )>0;
			if( !success ) abortError("Could not load:", fName, __LINE__, __FILE__ );
			if( 0 ) { im1=im; im1.Resize( im, .5f, .5f ); }
			res.makeChs( im, prms );
			fName = dest.getFileName(k,j); success = res.save(fName);
			if( !success ) abortError("Could not save:", fName, __LINE__, __FILE__ );
		}
		cout << sw.ElapsedStr() << endl;
	}
	cout << "Total time: " << swt.ElapsedStr() <<
		" Total # images processed: " << src.nImages()*src.nDirs() << endl;
	return;
}

void				MultiImage::merge( const MultiImage *src, int nSrc, MultiImage &T )
{
	int s, c; int nCh=0;
	for( s=0; s<nSrc; s++ ) { 
		if( src[s].initialized()==0 ) 
			abortError( "MultiImage not initialized", __LINE__, __FILE__ );
		nCh += src[s].nCh();
	}
	T.allocateMemory( nCh ); nCh=0;
	for( s=0; s<nSrc; s++ ) { 
		for( c=0; c<src[s].nCh(); c++ )
			T._images[c+nCh] = src[s]._images[c];
		nCh += src[s].nCh();
	}
	T._init=1; T.validateSizes( __LINE__, __FILE__ );
}

void				MultiImage::merge( ImageDataLoc *src, int *nCh, int nSrc, ImageDataLoc &tar )
{
	for( int s=0; s<nSrc; s++ )
		if( tar.nImages()!=src[s].nImages() || tar.nDirs()!=src[s].nDirs()) 
			abortError("All src and tar should have same size", __LINE__, __FILE__ );

	MultiImage *Isrc = new MultiImage[nSrc], Itar; char *fName; bool success;
	for( ushort d=0; d<=tar.nDirs(); d++ ) {
		_mkdir(tar.getDirName(d));
		for( ushort f=0; f<tar.nImages(); f++ ) {
			for( int s=0; s<nSrc; s++ ) {
				fName = src[s].getFileName( d+src[s]._dirFirst, f+src[s]._indFirst );
				success = Isrc[s].load( nCh[s], fName )>0;
				if( !success ) abortError("Could not load:", fName, __LINE__, __FILE__ );
			}
			merge( Isrc, nSrc, Itar );
			fName = tar.getFileName( d+tar._dirFirst, f+tar._indFirst );
			success = Itar.save( fName );
			if( !success ) abortError("Could not save:", fName, __LINE__, __FILE__ );
		}
	}
	delete [] Isrc;
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

vectori				MultiImage::samplePatches( Matrixd &prob, MultiImage *patches, int wd, int ht, int &nSample, bool pad ) const
{
	vectori samples;
	if( nSample==0 ) return samples;
	if( prob.size()==0 ) {
		prob.SetDimension( rows(), cols() ); 
		prob.SetValue( 1.0 );
	} else {
		assert( rows() == prob.rows() );
		assert( cols() == prob.cols() );
	}
	assert( rows()>=ht && cols()>=wd );
	if( prob.Sum()==0 ) abortError( "cannot sample prob matrix == 0", __LINE__, __FILE__ );
	int width2 = (int)(wd/2.0+.6);
	int height2 = (int)(ht/2.0+.6);

	// optionally pad matricies and sample near borders
	MultiImage imagePad; Matrixd probPad;
	if( pad ) {
		prob.Pad( probPad, 0.0, width2, width2, height2, height2 );
		PadReplicate( imagePad, width2, width2, height2, height2 );
	} else {
		imagePad = *this; probPad = prob;
		probPad.MaskBorder( width2, width2, height2, height2, 0.0 );
	}
	
	// sample locations (without replace)
	RF rf; rf.set( probPad ); rf.setCdf();
	rf.sampleNoReplace( samples, nSample ); 
	if( patches==NULL ) return samples;

	// crop patches
	int rows=probPad.rows(), cols=probPad.cols();
	int r, c, lf, rt, tp, bt;
	for( int i=0; i<nSample; i++ ) {		
		r = samples[i]/cols;
		c = samples[i]-r*cols;
		lf = c-width2; rt = lf+wd-1; 
		tp = r-height2; bt = tp+ht-1;
		imagePad.Crop( patches[i], lf, rt, tp, bt );
	}
	return samples;
}

void				MultiImage::appendRight( const MultiImage &A, MultiImage &B ) const
{
	if( A.initialized()==0 || initialized()==0 )
		abortError( "MultiImage not initialized", __LINE__, __FILE__ );
	if( A.nCh()!=nCh() )
		abortError( "MultiImages must have same number of channels", __LINE__, __FILE__ );
	B.allocateMemory( _nCh );
	for( int ch=0; ch<_nCh; ch++ )
		_images[ch].AppendRight( A._images[ch], B._images[ch] );
	B._init = 1;
	B.validateSizes( __LINE__, __FILE__ );
}

#define MI_HEADER(FUNC,...) \
	void MultiImage::FUNC( MultiImage &B, __VA_ARGS__ ) const
#define MI_BODY(FUNC,...) \
{\
	B.allocateMemory( _nCh ); \
	for( int ch=0; ch<_nCh; ch++ ) \
		_images[ ch ].FUNC( B._images[ ch ], __VA_ARGS__ ); \
	B._init = 1; \
	B.validateSizes( __LINE__, __FILE__ ); \
}
MI_HEADER( PadReplicate, int amount ) 					MI_BODY( PadReplicate, amount );
MI_HEADER( CropCenter, int mrows,int nCol )				MI_BODY( CropCenter, mrows, nCol );
MI_HEADER( Resize, int mrows, int nCol, int flag )		MI_BODY( Resize, mrows, nCol, flag );
MI_HEADER( Resize, float rowR, float colR, int flag )	MI_BODY( Resize, rowR, colR, flag );
MI_HEADER( Rotate, double angle, int flag )				MI_BODY( Rotate, angle, flag );
MI_HEADER( RotateCrop, double angle, int flag )			MI_BODY( RotateCrop, angle, flag );
MI_HEADER( PadReplicate, int lf,int rt,int tp,int bt )	MI_BODY( PadReplicate, lf, rt, tp, bt );
MI_HEADER( Crop, int lf,int rt,int tp,int bt )			MI_BODY( Crop, lf, rt, tp, bt );
#undef MI_HEADER
#undef MI_BODY

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

					MultiImagePrms::MultiImagePrms()
{
	for( int k=0; k<1024; k++ ) _useChs[k] = 0;
	_resRatio	= 1.0f;
	_sigma		= 0.0f;
	_crop		= 0;
}

string				MultiImagePrms::getDescr()
{
	vectorString chs; 
	chs.push_back("Grayscale");
	chs.push_back("L - LUV"); chs.push_back("U - LUV"); chs.push_back("V - LUV");
	chs.push_back("H - HSV"); chs.push_back("S - HSV"); chs.push_back("V - HSV");
	chs.push_back("Grad Mag"); chs.push_back("Grad Angle"); 
	chs.push_back("COS(Grad Angle)"); chs.push_back("SIN(Grad Angle)");
	chs.push_back("Harris Corners");

	string descr = "MultiImagePrms:\n";
	descr += makeDescr( "resRatio", _resRatio );
	descr += makeDescr( "sigma", _sigma );
	descr += makeDescr( "crop", _crop );
	for( int i=0; i<12; i++ ) 
		if( _useChs[i]>0 ) descr += makeDescr( ("depth "+chs[i]).c_str(), _useChs[i] );
	return descr;
}

int					MultiImagePrms::nCh()
{
	int nCh=0; 
	for(int k=0; k<1024; k++) 
		nCh += _useChs[k]; 
	return nCh;
}

int					MultiImagePrms::nChUsed()
{
	int nChUsed1 = 0; 
	for( int k=0; k<1024; k++ ) if( _useChs[k]>0 ) 
		nChUsed1++;
	return nChUsed1;
}

void				MultiImagePrms::getUseChs(int *useChs)
{
	int cnt = 0;
	for( int k=0; k<1024; k++ )
		if( _useChs[k] > 0 ){
			useChs[cnt] = _useChs[k];
			cnt += _useChs[k];
		}
}

void				MultiImagePrms::writeToStrm(ofstream &strm)
{
	int nChUsed1 = nChUsed();
	strm.write((char*)&nChUsed1,		sizeof(nChUsed1));
	for( int k=0; k<1024; k++ ) if( _useChs[k]>0 ) {
		strm.write((char*)&k,			sizeof(k));
		strm.write((char*)&_useChs[k],	sizeof(_useChs[k]));
	}
	strm.write((char*)&_resRatio,		sizeof(_resRatio));
	strm.write((char*)&_sigma,			sizeof(_sigma));
	strm.write((char*)&_crop,			sizeof(_crop));
}

void				MultiImagePrms::readFrmStrm(ifstream &strm)
{
	int nChUsed1, k, depth;
	strm.read((char*)&nChUsed1,		sizeof(nChUsed1));
	for( int c=0; c<nChUsed1; c++ ) {
		strm.read((char*)&k,		sizeof(k));
		strm.read((char*)&depth,	sizeof(depth));
		_useChs[k] = depth;
	}
	strm.read((char*)&_resRatio,	sizeof(_resRatio));
	strm.read((char*)&_sigma,		sizeof(_sigma));
	strm.read((char*)&_crop,		sizeof(_crop));
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

					ImageCache::ImageCache( int cacheFlag, int nChannels )
{
	_nCh			= nChannels;
	_cacheFlag		= cacheFlag;
	_curFileI		= USHRT_MAX;
	_curDirI		= USHRT_MAX;
}

ImageCache&			ImageCache::operator=(const ImageCache &a)
{
	if (this != &a) {
		_dirNames		= a._dirNames;
		_formatStrs		= a._formatStrs;
		_indFirst		= a._indFirst;

		_nCh			= a._nCh;
		_cacheFlag		= a._cacheFlag;
		_curFileI		= USHRT_MAX;
		_curDirI		= USHRT_MAX;
		_images			= a._images;
	}
	return *this;
}

void				ImageCache::reset()
{
	_dirNames.clear();
	_formatStrs.clear();
	_indFirst.clear();

	_nCh			= 0;
	_cacheFlag		= 0;
	_curFileI		= USHRT_MAX;
	_curDirI		= USHRT_MAX;
	_images.clear();
}

ushort				ImageCache::addData( ImageDataLoc &data )
{
	ushort indD0 = (ushort)_dirNames.size();
	char formatStr[1024], formatStrD[1024];
	sprintf( formatStr, "%s%%0%iu/%s%%%%0%iu%s", data._dataDir.c_str(),
		data._nDirDigits, data._baseName.c_str(), data._nDigits, data._extn.c_str() );
	for( ushort indD=data._dirFirst; indD<=data._dirLast; indD++ ) {
		string dirName = data.getDirName(indD);
		sprintf( formatStrD, formatStr, indD );
		addData( dirName, string(formatStrD), data._indFirst, data._indLast );
	}
	return indD0;
}

ushort				ImageCache::addData( string dirName, string formatStr, ushort indFirst, ushort indLast )
{
	if( getDirInd(dirName)!=USHRT_MAX )
		abortError( "directory already in cache:", dirName.c_str(), __LINE__, __FILE__ );
	_dirNames.push_back(dirName);
	_indFirst.push_back(indFirst);		
	_formatStrs.push_back(formatStr);
	_images.resize( _dirNames.size() );
	_images[_dirNames.size()-1].resize( indLast-indFirst+1 );
	return _dirNames.size()-1;
}

ushort				ImageCache::getDirInd( string dirName )
{
	const char *dirName1 = dirName.c_str();
	for( ushort indD=0; indD<_dirNames.size(); indD++ )
		if( !strcmp(_dirNames[indD].c_str(),dirName1) )
			return indD;
	return USHRT_MAX;
}

MultiImage*			ImageCache::getImage( ushort dirI, ushort fileI )
{
	if( fileI==_curFileI && dirI==_curDirI ) 
		return &(_images[_curDirI][_curFileI]);
	clearCurrent( _cacheFlag );
	_curFileI=fileI; _curDirI=dirI;
	MultiImage *curImage = &(_images[_curDirI][_curFileI]);
	if( curImage->initialized()==0 ) {
		getImageFname( _curDirI, _curFileI );
		int success = curImage->load( _nCh, _fName );
		if( success==0 ) abortError( "failed to load image:", _fName, __LINE__, __FILE__ );
	}
	return curImage;
}

const char*			ImageCache::getImageFname( ushort dirI, ushort fileI )
{
	sprintf( _fName, _formatStrs[dirI].c_str(), fileI+_indFirst[dirI] );
	return _fName;
}

void				ImageCache::clearCurrent( int cacheFlag )
{
	if( _curFileI==USHRT_MAX || _curDirI==USHRT_MAX ) return;
	if( cacheFlag==0 )
		_images[_curDirI][_curFileI].freeMemory();
	else if( cacheFlag==1 )
		_images[_curDirI][_curFileI].clearIIs();
}

void				ImageCache::clearAll( int cacheFlag )
{
	_curFileI	= USHRT_MAX;
	_curDirI	= USHRT_MAX;
	for( ushort dirI=0; dirI<_images.size(); dirI++ )
		for( ushort fileI=0; fileI<_images[dirI].size(); fileI++ )
			if( cacheFlag==0 )
				_images[dirI][fileI].freeMemory();
			else if( cacheFlag==1 )
				_images[dirI][fileI].clearIIs();
}
