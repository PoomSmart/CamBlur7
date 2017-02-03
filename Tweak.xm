#import "../PS.h"
#import <dlfcn.h>

%ctor
{
	if (isiOS10Up)
		dlopen("/Library/Application Support/CamBlur7/CamBlur7iOS10.dylib", RTLD_LAZY);
	else if (isiOS9)
		dlopen("/Library/Application Support/CamBlur7/CamBlur7iOS9.dylib", RTLD_LAZY);
	else if (isiOS8)
		dlopen("/Library/Application Support/CamBlur7/CamBlur7iOS8.dylib", RTLD_LAZY);
	else if (isiOS7)
		dlopen("/Library/Application Support/CamBlur7/CamBlur7iOS7.dylib", RTLD_LAZY);
}
