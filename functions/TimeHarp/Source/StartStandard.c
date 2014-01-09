#include "thdefin.h"
#include "thlib.h"
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{	
    int retCode;
    
	TH_ClearHistMem(0);
	
	retCode = TH_StartMeas();
	if(retCode < 0)
		mexErrMsgTxt("\nError in StartMeas. Aborted.\n ");		
}