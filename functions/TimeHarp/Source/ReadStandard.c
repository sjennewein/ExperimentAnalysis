#include "thdefin.h"
#include "thlib.h"
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
	int waitloop = 0;
	//unsigned int counts[BLOCKSIZE];
	mxArray 	 *data_struct;
    mxArray      *resolution_struct;
    float        *resolution_ptr;
	unsigned int *data_ptr;
	int retCode;
	int flags;	
	
	//while(TH_CTCStatus()==0) waitloop++; //wait until card is ready
	
	retCode = TH_StopMeas();
    if(retCode<0)
		mexErrMsgTxt("\nError in StopMeas. Aborted.\n ");
	
	data_struct = mxCreateNumericMatrix(1, BLOCKSIZE, mxUINT32_CLASS,mxREAL);
	data_ptr = (unsigned int*) mxGetData(data_struct);
	
    resolution_struct = mxCreateNumericMatrix(1,1,mxSINGLE_CLASS,mxREAL);
    resolution_ptr = (float*) mxGetData(resolution_struct);
    *resolution_ptr = TH_GetResolution();
    
	retCode = TH_GetBlock(data_ptr,0);
	if(retCode<0)
	{
		mxDestroyArray(data_struct);
		mexErrMsgTxt("\nError in GetBlock. Aborted.\n ");		
	}
	
// 	flags = TH_GetFlags();
// 	if(flags&FLAG_OVERFLOW)
// 	{
// 		mxDestroyArray(data_struct);
// 		mexErrMsgTxt("\nOverflow\n ");
// 	}
	
	plhs[0] = data_struct;
    plhs[1] = resolution_struct;
}