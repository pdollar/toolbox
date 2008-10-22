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
	testToStrm();
	_CrtDumpMemoryLeaks();
	system("pause");
	return 0;	
}

void testToStrm()
{
	#ifndef  NDEBUG
	cout << "DEBUGGING" << endl;
	#endif

	// X
	//int x=87519651; Primitive<int> X(&x); 
	//double x=1.15415987557150715098721501515; Primitive<double> X(&x);
	//float x[2]={59.5,7500}; Primitive<float> X(x,2);
	//char *x="whatev yo"; Primitive<char> X(x,strlen(x)+1);
	Matrixd X(5,5,0); for(int i=0; i<5; i++) X(i,i)=i;

	//// save/load
	ObjImg ox, oy; X.save( ox, "x" ); bool binary=1;
	char *fName="D:/code/toolbox/boosting/temp.txt";
	ox.saveToFile( fName, binary );	

	// Y
	////int y; Primitive<int> Y(&y);
	////double y; Primitive<double> Y(&y);
	////float y[2]; Primitive<float> Y(y);
	////char y[128]; Primitive<char> Y(y);
	Matrixd Y;
	ObjImg::loadFrmFile( fName, oy, binary );
	Y.load(oy);
	cout << X << endl << Y << endl;
}