SPE TOOLBOX 2013-08-01

======== ABOUT ===========================================================

SPE TOOLBOX was created to allow researchers from NSU's Laboratory of 
Applied Electrodynamics to conveniently work with WinView/WinSpec (.spe) 
files in MatLab. Over time, support for additional formats similar to 
WinView was added, and methods for quickly adding support to SPE TOOLBOX 
for additional formats were implemented.

======== QUICK START GUIDE ===============================================

1. To quickly read a header from a WinView/WinSpec (.spe) file:

	header = speread_header();

You will be presented with a dialog to select a file supported by the 
toolbox. After you select one, 'header' variable will contain all of the 
header fields from WinView format 2.5 specification, provided you haven't 
changed format filter in the dialog. Refer to WinView/WinSpec 
documentation for more information about what information each field 
contains.

2. To read a frame from a WinView file, use:

	frame = speread_frame(header,frame_number);

3. To quickly read a pixel value across all frames in a file, use:

	point = speread_pointvals(header,row,column);

point will be a structure with fields:

	row - row index of pixel
	col - column index of pixel
	data - vector with pixel values across all frames

======== INSTALLATION ====================================================

You can simply copy functions that you require to your MatLab work 
directory, or you can use MatLab's 'File/Set Path...' menu to always have 
access to the toolbox functions from any directory while working in 
MatLab:

1. Create a directory somewhere (for example,'SPETOOLBOX') and extract 
   SPETOOLBOX_2013-08-01.zip archive to it.
2. Click 'File/Set Path...' menu item in MatLab main window
3. Click 'Add Folder...' and select the folder that you extracted the 
   archive to ('SPETOOLBOX').
4. Click 'Save' and 'Close'
5. Done

======== EXAMPLES ========================================================

Here are some of the important examples of what you can do using this 
toolbox. Note: some of these examples might require additional MatLab 
Toolboxes.

1. Simple SPE player

	header = speread_header();
        ax = axes;
        for frame = 1:header.NumFrames
            M = speread_frame(header,frame);
            imagesc(M,'Parent',ax);
            drawnow;
        end;

2. Read and plot pixel (10,10) values from all frame matrices

        header = speread_header();
        point = speread_pointvals(header,10,10);
        plot(1:header.NumFrames,point.data);

3. Convert supported file to animated GIF for use in presentations

	header = speread_header();
	CMAP = jet(64);
	for frame = 1:header.NumFrames
   	    M = speread_frame(header,frame);
    	    I = mat2gray(M);
    	    IND = gray2ind(I);
    	    if frame == 1
        	imwrite(IND,CMAP,'example.gif','gif','WriteMode',...
		'overwrite');
    	    else
        	imwrite(IND,CMAP,'example.gif','gif','WriteMode',...
		'append');
    	    end;
	end;

4. Convert supported file to AVI movie

	header = speread_header();
	CMAP = jet(64);
	mov = avifile('example.avi','colormap',CMAP);
	for frame = 1:header.NumFrames
   	    M = speread_frame(header,frame);
    	    I = mat2gray(M);
    	    IND = gray2ind(I);
    	    mov = addframe(mov,IND);
	end;
	mov = close(mov);

5. You can also use SPECONVERT program with GUI to play and convert 
supported files. This program is simply for demonstration purposes and 
will probably remain in alpha version, but it 'should' be able to do what 
it is supposed to do. Help for UI elements of this program is available 
in mouse over tooltips.

6. Use spefile functions for copying only required frames to new file

	[header,vardata,structdecl] = speread_header();
	speobj = spefile('example.spe',header,vardata,structdecl);
	for frame = 1:10
   	    M = speread_frame(header,frame);
    	    speobj = addframe(speobj,M);
	end;
	close(speobj);

======== FAQ =============================================================

1. Where can I get additional information about toolbox functions?

All toolbox functions contain detailed descriptions in their help 
sections. Use 'help function_name' or 'doc function_name' MatLab commands 
to access them.

2. What are VARDATA functions? Do I need them?

Probably not. They are used with legacy formats from old hardware by our 
researchers.

3. Any plans for future development?

Hard to say. Currently this toolbox covers all our needs, so unless any 
serious bugs are found, there won't be any future versions. Anyone is, 
of course, welcome to fork the source code, provided they follow simple 
BSD license of this toolbox.

4. Can support for my format be added?

You can use speread_vardata() function to quickly add support for your 
format, provided it is compatible with limitations described in 
speread_vardata() help. Basically, if it is similar to WinView format, 
this toolbox can support it. Then, you would be able to work with your 
files as you do with WinView using this toolbox.

5. Damn it, there was a bug in your functions and I analysed the wrong 
data!

Sorry, it happens. Remember, this software is provided 'as is' and for 
free. But, all of the important functions were tested for correctness, 
so there 'should' be no bugs present that would cause invalid data to be 
read. But again, happens to the best of us ;)

6. What MatLab version do I need?

This toolbox should run on MatLab 7.5.0 and higher. Maybe even some 
earlier versions.

======== END =============================================================

Copyright (c) 2008-2013 Alexander Nikitin