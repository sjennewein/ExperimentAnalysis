/* PVCAMICL - acquire image sequence using ICL script
  
      [DATA, ROI] = PVCAMICL(HCAM, SCRIPT) acquires an image sequence from
      ICL code in the character string SCRIPT.  If successful, DATA will be a
      vector of unsigned integers containing the image data acquired by the
      ICL script, and ROI will be a structure array that contains the fields
      X, Y and OFFSET to provide the size and offset of each PIXEL_DISPLAY( )
      command issued within the ICL script.  If no images are acquired, such
      as a script to open or close the shutter, DATA = [] and ROI = "no
      image".  If an error occurs, DATA = [] and ROI = "error".
  
      Use the syntax [DATA, ROI] = PVCAMICL(HCAM, [SCRIPT{:}]) if SCRIPT is a
      cell array of ICL code lines.
  
      [DATA, ROI] = PVCAMICL(HCAM, SCRIPT, 'load') initializes and loads the
      script only.  Although no acquisition is performed, DATA will be
      returned as zeros(IMAGE_SIZE), which is required for image storage for
      subsequent 'run' commands.
  
      DATA = PVCAMICL(HCAM, DATA, 'run') runs the loaded script and
      stores any acquired images to DATA.  Note that DATA is initially
      allocated by the 'load' option and must be provided as an input for
      any image acquisition.
  
      STATUS = PVCAMICL(HCAM, [], 'uninit') uninitializes the loaded ICL
      script so another script can be loaded.  STATUS = 1 if there are no
      errors.
  
      The 'load', 'run' and 'uninit' options are provided for repetitive
      script execution.  An example of this repetitive execution would be: 
  
      [DATA, ROI] = PVCAMICL(HCAM, SCRIPT, 'load');
      for i = 1 : NIMAGE
          DATA = PVCAMICL(HCAM, DATA, 'run');
      end
      STATUS = PVCAMICL(HCAM, [], 'uninit'); */

/* 1/8/04 SCM */


// inclusions
#include "pvcamutil.h"
#include "pv_icl.h"


// definitions
#define FIELD_SIZE		8		// max length for structure field names
#define ROI_FIELD		3		// number of fields in ROI output structure


// function prototypes

// acquire image(s) from camera using ICL script
//bool pvcam_script(int16 hcam, const char *script, const char *option, uns32 ssize, mxArray *plhs[]);

// load ICL script onto camera
bool pvcam_load_script(int16 hcam, const char *script, mxArray *plhs[]);

// acquire image(s) from camera using loaded script
bool pvcam_run_script(int16 hcam, mxArray *plhs[]);

// unload ICL script from camera
bool pvcam_uninit_script(int16 hcam);

// gateway routine
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	// declarations
	bool	success_flag;	// indicates success on ICL routines
	char	*option;		// option for load and run script
	char	*script;	// storage for script
	int		i;				// loop counter
	int		stringlen;		// input string length
	int16	hcam;			// camera handle

	// validate arguments
	if ((nrhs < 2) || (nrhs > 3)) {
        mexErrMsgTxt("type 'help pvcamicl' for syntax");
    }

	// obtain camera handle
	if (!mxIsNumeric(prhs[0])) {
		mexErrMsgTxt("HCAM must be numeric");
	}
	else if (mxGetNumberOfElements(prhs[0]) != 1) {
		mexErrMsgTxt("HCAM must be a scalar");
	}
	else {
		hcam = (int16) mxGetScalar(prhs[0]);
	}

	// obtain flag for scripting option
	if (nrhs < 3) {
		stringlen = 5;
		option = (char *) mxCalloc(stringlen, sizeof(char));
		strcpy(option, "full");
	}
	else if (!mxIsChar(prhs[2])) {
		mexErrMsgTxt("OPTION must be a character string");
	}
	else if ((stringlen = mxGetNumberOfElements(prhs[2])) < 1) {
		mexErrMsgTxt("OPTION cannot be empty");
	}
	else {
		stringlen++;
		option = (char *) mxCalloc(stringlen, sizeof(char));
		if (mxGetString(prhs[2], option, stringlen)) {
			mexErrMsgTxt("Cannot read OPTION string");
		}
	}

	// obtain required inputs for various options
	// OPTION = 'full' or 'load'
	// obtain SCRIPT from character array
	// DATA and ROI are outputs
	if ((strcmp(option, "full") == 0) || (strcmp(option, "load") == 0)) {
		if (!mxIsChar(prhs[1])) {
			mexErrMsgTxt("SCRIPT must be a character string");
		}
		else if ((stringlen = mxGetNumberOfElements(prhs[1])) < 1) {
			mexErrMsgTxt("SCRIPT cannot be empty");
		}
		else {
			stringlen++;
			script = (char *) mxCalloc(stringlen, sizeof(char));
			if (mxGetString(prhs[1], script, stringlen)) {
				mexErrMsgTxt("Cannot read SCRIPT string");
			}
		}
		if (nlhs > 2) {
	        mexErrMsgTxt("DATA and ROI are only outputs");
		}
	}

	// OPTION = 'run'
	// obtain DATA from numeric array
	// DATA is only output
	else if (strcmp(option, "run") == 0) {
		if (!mxIsNumeric(prhs[1])) {
			mexErrMsgTxt("DATA must be numeric");
		}
		else {
			plhs[0] = mxDuplicateArray(prhs[1]);
		}
		if (nlhs > 1) {
	        mexErrMsgTxt("DATA is only output of run OPTION");
		}
	}

	// OPTION = 'uninit'
	// second argument should be empty
	// STATUS is only output
	else if (strcmp(option, "uninit") == 0) {
		if (!mxIsEmpty(prhs[1])) {
			mexErrMsgTxt("Placeholder for [] input must be empty");
		}
		if (nlhs > 1) {
	        mexErrMsgTxt("STATUS is only output of run OPTION");
		}
	}

	// invalid OPTION
	else {
		mexErrMsgTxt("Invalid OPTION string");
	}

	// check for open camera
	// execute routines based on OPTION
	// assign empty matrix if failure
	if (success_flag = (bool) pl_cam_check(hcam)) {

		// load script with OPTION = "full" or "load"
		// free allocated script storage
		if (success_flag && ((strcmp(option, "full") == 0) || (strcmp(option, "load") == 0))) {
			success_flag = pvcam_load_script(hcam, script, plhs);
			mxFree((void *) script);
		}

		// run script with OPTION = "full" or "run"
		if (success_flag && ((strcmp(option, "full") == 0) || (strcmp(option, "run") == 0))) {
			success_flag = pvcam_run_script(hcam, plhs);
		}

		// uninitialize with OPTION = "full" or "uninit"
		if (success_flag && ((strcmp(option, "full") == 0) || (strcmp(option, "uninit") == 0))) {
			success_flag = pvcam_uninit_script(hcam);
		}
	}
	else {
		pvcam_error(hcam, "HCAM is not a handle to an open camera");
	}

	// create STATUS output for OPTION = 'uninit'
	// otherwise return DATA = [] and ROI = 'error' if error occurs
	// free contents of previous outputs to prevent memory leak
	if (strcmp(option, "uninit") == 0) {
		plhs[0] = mxCreateDoubleScalar((double) success_flag);
	}
	else if (!success_flag) {
		for (i = 0; i < nlhs; i++) {
			if (plhs[i] != NULL) {
				mxFree((void *) plhs[i]);
			}
			if (i == 1) {
				plhs[i] = mxCreateString("error");
			}
			else {
				plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT16_CLASS, mxREAL);
			}
		}
	}

	// free remaining allocated arrays
	mxFree((void *) option);
}


// load ICL script onto camera
bool pvcam_load_script(int16 hcam, const char *script, mxArray *plhs[]) {
	
	// declarations
	char	**field_list;	// field names for ROI output structure
	char	err_char;		// character in script where error found
	char	*err_msg;		// string for ICL error location
	icl_disp_type	*roi_info;	// image size and offset from PIXEL_DISPLAY( ) commands
	int		i;				// generic loop counter
	int		npixel;			// number of pixels to be read
	uns16	*data_ptr;		// pointer to output data
	uns32	num_rects;		// number of images & ROIs acquired
	uns32	stream_size;	// image size in bytes
	uns32	err_char_num;	// index of character in script where error found
	uns32	err_ch_in_line;	// index of character within line where error found
	uns32	err_line;		// line number in script where error found

	// initialize exposure sequence
	if (!pl_exp_init_seq()) {
		pvcam_error(hcam, "Cannot initialize exposure sequence");
		return(false);
	}

	// initialize ICL scripting
	if (!pl_exp_init_script()) {
		pvcam_error(hcam, "Cannot initialize ICL scripting");
		return(false);
	}
	
	// load exposure sequence
	// obtain number of bytes needed to store images
	// display location of error in script
	if (!pl_exp_setup_script(hcam, script, &stream_size, &num_rects)) {
		pvcam_error(hcam, "ICL script error");
		if (!pl_exp_listerr_script(hcam, &err_char, &err_char_num, &err_line, &err_ch_in_line)) {
			pvcam_error(hcam, "Cannot obtain ICL error info");
		}
		else if ((err_line > 0) && (err_ch_in_line > 0)) {
			err_msg = (char *) mxCalloc(ERROR_MSG, sizeof(char));
			sprintf(err_msg, "Error at line %d char %d (%c)", err_line, err_ch_in_line, err_char);
			mexWarnMsgTxt(err_msg);
			mxFree((void *) err_msg);
		}
		return(false);
	}

	// create output structure
	// set pointer to capture camera data
	npixel = (int) (stream_size / sizeof(uns16));
	if (npixel > 0) {
		plhs[0] = mxCreateNumericMatrix(1, npixel, mxUINT16_CLASS, mxREAL);
	}
	else {
		plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT16_CLASS, mxREAL);
	}
	data_ptr = (uns16 *) mxGetData(plhs[0]);

	// create display structure
	// obtain coordinates from PIXEL_DISPLAY( ) commands
	if (num_rects > 0) {
		roi_info = (icl_disp_type *) mxCalloc((size_t) num_rects, sizeof(icl_disp_type));
		if (!pl_exp_display_script(hcam, roi_info, data_ptr)) {
			pvcam_error(hcam, "Cannot obtain ICL display info");
			return(false);
		}
		
		// assign field names to ROI output structure
		field_list = pvcam_create_array(ROI_FIELD, FIELD_SIZE);
		strcpy(field_list[0], "x");
		strcpy(field_list[1], "y");
		strcpy(field_list[2], "offset");

		// store field values to ROI output structure
		plhs[1] = mxCreateStructMatrix(1, (int) num_rects, ROI_FIELD, field_list);
		for (i = 0; i < (int) num_rects; i++) {
			mxSetField(plhs[1], i, field_list[0], mxCreateDoubleScalar((double) roi_info[i].x));
			mxSetField(plhs[1], i, field_list[1], mxCreateDoubleScalar((double) roi_info[i].y));
			mxSetField(plhs[1], i, field_list[2], mxCreateDoubleScalar((double) (((uns16 *) roi_info[i].disp_addr - data_ptr) / sizeof(uns16))));
		}
		pvcam_destroy_array(field_list,	ROI_FIELD);
		mxFree((void *) roi_info);
	}
	else {
		plhs[1] = mxCreateString("no image");
	}
	return(true);
}


// acquire image(s) from camera using loaded script
bool pvcam_run_script(int16 hcam, mxArray *plhs[]) {

	// declarations
	bool	data_flag;		// flag to indicate whether data was read
	int16	status;			// camera read status
	uns16	*data_ptr;		// pointer to output data
	uns32	bytes_read;		// bytes read by camera

	// start ICL script
	// PV_ICL.H has macro for PL_EXP_START_SCRIPT -> PL_EXP_START_SEQ??
	// MSVC compiler kept giving me an error with PL_EXP_START_SCRIPT
	data_ptr = (uns16 *) mxGetData(plhs[0]);
	if (!pl_exp_start_seq(hcam, data_ptr)) {
		pvcam_error(hcam, "Cannot start ICL script");
		return(false);
	}
	
	// loop until exposure sequence is complete
	status = -1;
	while ((status != READOUT_COMPLETE) && (status != READOUT_NOT_ACTIVE) && (status != READOUT_FAILED)) {
		if (!pl_exp_check_status(hcam, &status, &bytes_read)) {
			pvcam_error(hcam, "Cannot check camera status during exposure");
			return(false);
		}
	}
	
	// determine how exposure sequence terminated
	data_flag = false;
	switch (status) {
	case READOUT_COMPLETE:
		data_flag = true;
		break;
	case READOUT_NOT_ACTIVE:
		pvcam_error(hcam, "Camera readout never started");
		break;
	case READOUT_FAILED:
		pvcam_error(hcam, "Camera readout failed");
		break;
	default:
		pvcam_error(hcam, "Unknown camera readout termination");
		break;
	}
	return(data_flag);
}


// unload ICL script from camera
bool pvcam_uninit_script(int16 hcam) {

	// uninitialize ICL scripting
	if (!pl_exp_uninit_script()) {
		pvcam_error(hcam, "Cannot uninitialize ICL scripting");
		return(false);
	}
	
	// uninitialize exposure sequence
	if (!pl_exp_uninit_seq()) {
		pvcam_error(hcam, "Cannot uninitialize exposure sequence");
		return(false);
	}
	return(true);
}
