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
	// data - uncomment one of the following
	//int x=87519651; Primitive<int> X(&x);
	//uchar x=13; Primitive<uchar> X(&x);
	//double x=1.15415987557; Primitive<double> X(&x);
	//float x[2]={59.5,7500}; Primitive<float> X(x,2);
	//char *x="whatev yo"; Primitive<char> X(x,strlen(x)+1);
	//Matrixd X(5,5,0); for(int i=0; i<5; i++) X(i,i)=i;
	//Rect X(0,0,10,10); X._wt=.3f;
	Haar X; X.createSyst(1,25,25,10,10,0,0); X.finalize();

	// save (inspect w debugger)
	ObjImg ox, oy; X.save( ox, "x" ); bool binary=0;
	char *fName="D:/code/toolbox/boosting/temp.txt";
	ox.saveToFile( fName, binary );

	// load (inspect w debugger)
	ObjImg::loadFrmFile( fName, oy, binary );
	Savable *Y = Savable::create(oy);
	delete Y;
}