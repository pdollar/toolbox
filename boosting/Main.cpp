#include "Public.h"
#include "Matrix.h"
#include "IntegralImage.h"
#include "Haar.h"

int main(int argc, const char* argv[])
{
	#ifndef  NDEBUG
	cout << "DEBUGGING" << endl;
	#endif

	// CREATE
	Matrixd A(10,10,0); Matrixd B;
	for(int i=0; i<10; i++) A(i,i)=i;
	char *fName="D:/code/toolbox/boosting/temp";
	SavObj*	s1 = A.save("A");
	s1->saveToFile( fName );
	SavObj *s2 = (SavObj*) Savable::loadFrmFile( fName );
	B.load(*s2);
	cout << A << endl << B << endl;

	// INT TEST
	//int A=12321, B;
	//char *fName="D:/code/toolbox/boosting/temp";
	//SavLeaf *s1 = new SavLeaf( "A", &A );
	//s1->saveToFile( fName );
	//SavLeaf *s2 = (SavLeaf*) Savable::loadFrmFile( fName );
	//s2->load(NULL,&B);
	//cout << A << endl << B << endl;

	system("pause");
	return 0;
}