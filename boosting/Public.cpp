#include "Public.h"

#include "Savable.h"

// object factory macros
#define OBJFAC_CREATE(TYPE,OBJ) \
	if (!strcmp(cname, TYPE)) return (Cloneable*) new OBJ();
#define OBJFAC_CLONE(TYPE,OBJ,SRC) \
	if (!strcmp(cname, TYPE)) return (Cloneable*)new OBJ(*((OBJ*) SRC));
#define OBJFAC_CLONECOPY(TYPE,OBJ,SRC) \
	if (!strcmp(cname, TYPE)) { OBJ *obj=new OBJ(); (*obj)=*((OBJ*) SRC); return (Cloneable*) obj; }

Cloneable* createObject( const char* cname ) 
{
	OBJFAC_CREATE( "SavObj", SavObj );
	OBJFAC_CREATE( "SavLeaf", SavLeaf );
	abortError( "unknown type", cname, __LINE__, __FILE__ );
	return NULL;
}

Cloneable* cloneObject( Cloneable *obj )
{
	const char *cname = obj->getCname();
	abortError( "unknown type", cname, __LINE__, __FILE__ );
	return NULL;
}
