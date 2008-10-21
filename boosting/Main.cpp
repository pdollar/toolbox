#include "Public.h"
#include "Savable.h"
#include "Matrix.h"
//#include "IntegralImage.h"
//#include "Haar.h"

int main(int argc, const char* argv[])
{
	#ifndef  NDEBUG
	cout << "DEBUGGING" << endl;
	#endif

	// CREATE
	char *fName="D:/code/toolbox/boosting/temp";
	Matrixd A(10,10,0); 
	for(int i=0; i<10; i++) A(i,i)=i;	
	ObjImg o1; A.save(o1,"A");
	o1.saveToFile( fName );
	cout<<A<<endl;
	ObjImg o2; ObjImg::loadFrmFile( fName, o2 );
	Matrixd B; B.load(o2);
	cout<<B<<endl;

	// PRIMITIVE TEST
	//int x=12313, y; ObjImg o1, o2;
	//Primitive<int> X(&x); Primitive<int> Y(&y);
	//X.save( o1, "x" );
	//char *fName="D:/code/toolbox/boosting/temp";
	//o1.saveToFile( fName );
	//ObjImg::loadFrmFile( fName, o2 );
	//Y.load(o2);
	//cout << x << endl << y << endl;

	system("pause");
	return 0;
}