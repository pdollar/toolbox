#define _CRTDBG_MAP_ALLOC
#include <crtdbg.h>

#include "Public.h"
#include "Savable.h"
#include "Matrix.h"
#include "IntegralImage.h"
#include "Haar.h"

void testToStrm();

int main(int argc, const char* argv[])
{
	#ifndef  NDEBUG
	cout << "DEBUGGING" << endl;
	#endif

	testToStrm();

	_CrtDumpMemoryLeaks();

	system("pause");
	return 0;
}

void testToStrm()
{
	//// data (primitives) - uncomment one of the following
	const int n=1; int x[n]={87519651};
	//const int n=5; int x[n]={1,2,3,4,5};
	//const int n=4; bool x[n]={true,false,true,false};
	//const int n=1; uchar x[n]={13};
	//const int n=7; uchar x[n]={-1,1,2,3,4,5,256};
	//const int n=1; double x[n]={1.15415987557};
	//const int n=2; float x[n]={59.5,7500};
	//char *x="whatev yo"; const int n=strlen(x)+1;
	ObjImg X; X.frmPrim( "x", x, n );

	//// data (complex) - uncomment one of the following
	//Matrixd x(5,5,0); for(int i=0; i<5; i++) x(i,i)=i;
	//Rect x(0,0,10,10); x._wt=.3f;
	//VecSavable x;
	//Haar x; x.createSyst(1,25,25,10,10,0,0); x.finalize();
	//ObjImg X; X.frmSavable("x",&x);
	//// fun time
	//Savable *y = X.toSavable("x");
	//X.clear(); X.frmSavable("y",y); delete y;

	// save, then load, then save again
	bool binary=1; char *fName="C:/code/toolbox/boosting/temp.txt";
	X.toFile( fName, binary );
	ObjImg Y; Y.frmFile( fName, binary );
	Y.toFile( "C:/code/toolbox/boosting/temp2.txt", 0 );
}
