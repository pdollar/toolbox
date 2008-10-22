#include "vld.h"

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
	//char *fName="D:/code/toolbox/boosting/temp.txt";
	//Matrixd A(5,5,0); for(int i=0; i<5; i++) A(i,i)=i;	
	//ObjImg o1; A.save(o1,"A");
	//o1.saveToFile( fName, true );
	//cout<<A<<endl;
	//ObjImg o2; ObjImg::loadFrmFile( fName, o2, true );
	//Matrixd B; B.load(o2);
	//cout<<B<<endl;

	// PRIMITIVE TEST
	//int x=12313, y; ObjImg o1, o2; bool binary=0;
	//Primitive<int> X(&x); Primitive<int> Y(&y);
	//X.save( o1, "x" );
	//char *fName="D:/code/toolbox/boosting/temp.txt";
	//o1.saveToFile( fName, binary );
	//ObjImg::loadFrmFile( fName, o2, binary );
	//Y.load(o2);
	//cout << x << endl << y << endl;

	//TEMP
	//double x=1.15415987557150715098721501515; Primitive<double> X(&x);
	//float x[2]={59.5,7500}; Primitive<float> X(x,2);
	//char *x="whatev yo"; Primitive<char> X(x,strlen(x)+1);
	//Matrixd X(5,5,0); for(int i=0; i<5; i++) X(i,i)=i;	
	//ObjImg o1, o2; X.save( o1, "x" );
	//char *fName="D:/code/toolbox/boosting/temp.txt";
	//o1.saveToFile( fName, 0 );
	//ObjImg::loadFrmFile( fName, o2, 0 );


	// PRIMITIVE TEST
	int x=87519651; ObjImg ox, oy; bool binary=1;
	Primitive<int> X(&x); X.save( ox, "x" );
	char *fName="D:/code/toolbox/boosting/temp.txt";
	ox.saveToFile( fName, binary );
	ObjImg::loadFrmFile( fName, oy, binary );
	Primitive<int> *Y = (Primitive<int>*) oy.create();
	cout << X << endl << *Y << endl;
	delete Y;

	system("pause");
	return 0;
}