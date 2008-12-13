#define _CRTDBG_MAP_ALLOC
#include <crtdbg.h>

#include "Public.h"
#include "Savable.h"
#include "Matrix.h"
//#include "IntegralImage.h"
//#include "Haar.h"

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
	// data (primitives) - uncomment one of the following
	//const int n=1; int x[n]={87519651};
	//const int n=5; int x[n]={1,2,3,4,5};
	//const int n=4; bool x[n]={true,false,true,false};
	//const int n=1; uchar x[n]={13};
	//const int n=7; uchar x[n]={-1,1,2,3,4,5,256};
	//const int n=1; double x[n]={1.15415987557};
	//const int n=2; float x[n]={59.5,7500};
	//char *x="whatev yo"; const int n=strlen(x)+1;
	//ObjImg X; X.frmPrim( "x", x, n );

	// data (complex) - uncomment one of the following
	Matrixd x(5,5,0); for(int i=0; i<5; i++) x(i,i)=i;
	//Rect X(0,0,10,10); X._wt=.3f;
	//Haar X; X.createSyst(1,25,25,10,10,0,0); X.finalize();
	ObjImg X; X.frmSavable(&x);
	// fun time
	//Savable *y = X.toSavable();
	//X.clear(); X.frmSavable(y); delete y;
	
	// save, then load (inspect results w debugger)
	bool binary=1; char *fName="C:/code/toolbox/boosting/temp.txt";
	X.toFile( fName, binary );
	ObjImg Y; Y.frmFile( fName, binary );
	Y.toFile( "C:/code/toolbox/boosting/temp2.txt", 0 );
}