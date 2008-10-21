#include "Public.h"
#include "Matrix.h"
#include "IntegralImage.h"
#include "Haar.h"

int main(int argc, const char* argv[])
{
	//// prep
	//Matrixd A(10,10,0);
	//IntegralImage II;
	//II.prepare(A);

	//// run
	//Haar h; h.createSyst( 0, 50, 50, 10, 10, 0, 0 );
	//Matrixf resp; h.convHaar( resp, II, 1, false );

	//// test
	////Rect a(0,0,4,4), b;
	////SavObj*	s = a.save("Rect");
	////b.load( *s );
	////mexPrintf((a==b) ? "YAY" : "NAY");
	//Haar b;
	//SavObj*	s = h.save("Haar");
	//b.load( *s );
	//cout << ((h==b) ? "YAY" : "NAY") << endl;

	float x = 3; float y;
	SavLeaf *leaf = new SavLeaf( "x", &x );
	leaf->load( "x", &y );
	cout << x << " " << y << endl;

	#ifdef  NDEBUG
	cout << "not debugging" << endl;
	#endif

	system("pause");
	return 0;
}