/*	InitializeStandard - initializes the timeharp for aspherix
	
		DATA = StartStandard(EXPTIME, CFDZERO, CFDDISCR, SYNCLEVEL, OFFSET, RANGE) 
		This function needs to called first afterwards call StartStandard and 
        ReadStandard needs to be called to gather the result.
*/

#include "thdefin.h"
#include "thlib.h"
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
//inputs from Matlab
	int ExpTime; //in Milliseconds
	int CFDZeroCross;
	int CFDDiscrMin;
	int SyncLevel;
	int Offset;
	int Range;	
	
	//software internals
	int retCode;
	
	//validate arguments
	if((nrhs != 6) || (nlhs > 1))
	{
		mexErrMsgTxt("type 'help StartStandard' for syntax");
	}
	
	//check exposure time
	if (!mxIsNumeric(prhs[0])) {
		mexErrMsgTxt("EXPTIME must be numeric");
	}
	else if (mxGetNumberOfElements(prhs[0]) != 1) {
		mexErrMsgTxt("EXPTIME must be a scalar");
	}
	else {
		ExpTime = (int) mxGetScalar(prhs[0]);
	}	
	
	//check exposure CFDZeroCross
	if (!mxIsNumeric(prhs[1])) {
		mexErrMsgTxt("CFDZeroCross must be numeric");
	}
	else if (mxGetNumberOfElements(prhs[1]) != 1) {
		mexErrMsgTxt("CFDZeroCross must be a scalar");
	}
	else {
		CFDZeroCross = (int) mxGetScalar(prhs[1]);
	}	
	
	//check exposure CFDDiscrMin
	if (!mxIsNumeric(prhs[2])) {
		mexErrMsgTxt("CFDDiscrMin must be numeric");
	}
	else if (mxGetNumberOfElements(prhs[2]) != 1) {
		mexErrMsgTxt("CFDDiscrMin must be a scalar");
	}
	else {
		CFDDiscrMin = (int) mxGetScalar(prhs[2]);
	}
	
	//check exposure SyncLevel
	if (!mxIsNumeric(prhs[3])) {
		mexErrMsgTxt("SyncLevel must be numeric");
	}
	else if (mxGetNumberOfElements(prhs[3]) != 1) {
		mexErrMsgTxt("SyncLevel must be a scalar");
	}
	else {
		SyncLevel = (int) mxGetScalar(prhs[3]);
	}
	
	//check exposure Offset
	if (!mxIsNumeric(prhs[4])) {
		mexErrMsgTxt("Offset must be numeric");
	}
	else if (mxGetNumberOfElements(prhs[4]) != 1) {
		mexErrMsgTxt("Offset must be a scalar");
	}
	else {
		Offset = (int) mxGetScalar(prhs[4]);
	}
	
	//check exposure Range
	if (!mxIsNumeric(prhs[5])) {
		mexErrMsgTxt("Range must be numeric");
	}
	else if (mxGetNumberOfElements(prhs[5]) != 1) {
		mexErrMsgTxt("Range must be a scalar");
	}
	else {
		Range = (int) mxGetScalar(prhs[5]);
	}
	
	
	//initialize the timeharp
	
	retCode = TH_Initialize(0); //0=Standard, 1=TTTR
	if(retCode < 0)
		mexErrMsgTxt("\n TH init error. Aborted.\n ");
	
	retCode = TH_Calibrate();
	if(retCode < 0)
		mexErrMsgTxt("\n Calibration Error.  Aborted.\n ");
		
	retCode=TH_SetCFDDiscrMin(CFDDiscrMin);
	if(retCode < 0)
		mexErrMsgTxt("\nIllegal CFDDiscriminMin. Aborted.\n ");
	
	retCode = TH_SetCFDZeroCross(CFDZeroCross);
	if(retCode < 0)
		mexErrMsgTxt("\nIllegal CFDZeroCross. Aborted.\n ");
		
	retCode = TH_SetSyncLevel(SyncLevel);
	if(retCode < 0)
		mexErrMsgTxt("\nIllegal SYNCLevel. Aborted.\n ");
		
	retCode = TH_SetRange(Range);
	if(retCode < 0)
		mexErrMsgTxt("\nError in SetRange. Aborted.\n ");
		
	Offset = TH_SetOffset(Offset);
	
	TH_SetStopOverflow(1);
	TH_SetMMode(0,ExpTime);
   
}