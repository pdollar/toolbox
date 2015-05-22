//
// MATLAB Compiler: 5.2 (R2014b)
// Date: Fri May 22 15:12:12 2015
// Arguments: "-B" "macro_default" "-v" "-W" "cpplib:libacf" "-T" "link:lib"
// "acfDetect.m" 
//

#include <stdio.h>
#define EXPORTING_libacf 1
#include "libacf.h"

static HMCRINSTANCE _mcr_inst = NULL;


#ifdef __cplusplus
extern "C" {
#endif

static int mclDefaultPrintHandler(const char *s)
{
  return mclWrite(1 /* stdout */, s, sizeof(char)*strlen(s));
}

#ifdef __cplusplus
} /* End extern "C" block */
#endif

#ifdef __cplusplus
extern "C" {
#endif

static int mclDefaultErrorHandler(const char *s)
{
  int written = 0;
  size_t len = 0;
  len = strlen(s);
  written = mclWrite(2 /* stderr */, s, sizeof(char)*len);
  if (len > 0 && s[ len-1 ] != '\n')
    written += mclWrite(2 /* stderr */, "\n", sizeof(char));
  return written;
}

#ifdef __cplusplus
} /* End extern "C" block */
#endif

/* This symbol is defined in shared libraries. Define it here
 * (to nothing) in case this isn't a shared library. 
 */
#ifndef LIB_libacf_C_API
#define LIB_libacf_C_API /* No special import/export declaration */
#endif

LIB_libacf_C_API 
bool MW_CALL_CONV libacfInitializeWithHandlers(
    mclOutputHandlerFcn error_handler,
    mclOutputHandlerFcn print_handler)
{
    int bResult = 0;
  if (_mcr_inst != NULL)
    return true;
  if (!mclmcrInitialize())
    return false;
    {
        mclCtfStream ctfStream = 
            mclGetEmbeddedCtfStream((void *)(libacfInitializeWithHandlers));
        if (ctfStream) {
            bResult = mclInitializeComponentInstanceEmbedded(   &_mcr_inst,
                                                                error_handler, 
                                                                print_handler,
                                                                ctfStream);
            mclDestroyStream(ctfStream);
        } else {
            bResult = 0;
        }
    }  
    if (!bResult)
    return false;
  return true;
}

LIB_libacf_C_API 
bool MW_CALL_CONV libacfInitialize(void)
{
  return libacfInitializeWithHandlers(mclDefaultErrorHandler, mclDefaultPrintHandler);
}

LIB_libacf_C_API 
void MW_CALL_CONV libacfTerminate(void)
{
  if (_mcr_inst != NULL)
    mclTerminateInstance(&_mcr_inst);
}

LIB_libacf_C_API 
void MW_CALL_CONV libacfPrintStackTrace(void) 
{
  char** stackTrace;
  int stackDepth = mclGetStackTrace(&stackTrace);
  int i;
  for(i=0; i<stackDepth; i++)
  {
    mclWrite(2 /* stderr */, stackTrace[i], sizeof(char)*strlen(stackTrace[i]));
    mclWrite(2 /* stderr */, "\n", sizeof(char)*strlen("\n"));
  }
  mclFreeStackTrace(&stackTrace, stackDepth);
}


LIB_libacf_C_API 
bool MW_CALL_CONV mlxAcfDetect(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{
  return mclFeval(_mcr_inst, "acfDetect", nlhs, plhs, nrhs, prhs);
}

LIB_libacf_CPP_API 
void MW_CALL_CONV acfDetect(int nargout, mwArray& bbs, const mwArray& I, const mwArray& 
                            detectorFileName, const mwArray& fileName)
{
  mclcppMlfFeval(_mcr_inst, "acfDetect", nargout, 1, 3, &bbs, &I, &detectorFileName, &fileName);
}

