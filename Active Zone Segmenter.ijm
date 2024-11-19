// Prompt user to select a directory and load the list of files
dir=getDirectory("Choose a Directory");
files=getFileList(dir);

// Set default file extension and allow user to specify a different one
extention=".tif";
extention=getString("Enter identifier (e.g. .tif .png)", extention);

// Print the number of files in the directory
print(files.length);
close("*"); // Close all open windows
counts=0;

// Loop through all files in the directory
for (i=0;i<files.length;i++)
	{
	print(files[i]);
	if ((indexOf(files[i], extention)) >= 0) 

		{
		counts+=1;
		
       // Free memory by forcing garbage collection	
		run("Collect Garbage");
		call("java.lang.System.gc");
		
	
		
		// Open file using Bio-Formats plugin in Hyperstack view mode
		run("Bio-Formats", "  open="+dir+files[i]+" color_mode=Default view=Hyperstack stack_order=XYCZT");	
	
			// Wait until the current file is loaded
			while(getTitle!=files[i])
				{wait(100);
				print("wait");
				}



if(counts==1)// Prepare for the first file only
	{
	// Create necessary subdirectories for analysis
	subfolder=dir+"\\analysis\\";
	File.makeDirectory(subfolder);
	File.makeDirectory(subfolder+"ROIs\\");
	File.makeDirectory(subfolder+"ROIs\\_\\");
	File.makeDirectory(subfolder+"CSVs\\");
	File.makeDirectory(subfolder+"Binary\\");
	File.makeDirectory(subfolder+"Objects\\");
	title=getTitle();

	
	// Set analysis parameters
	channels=2;
	getDimensions(width, height, channels, slices, frames);
	run("Select All");
	
	 // ROI enlargement factors (in pixels)
	enlargeBig=1.5;
	enlargeSmall=0.5;
	
	// Bandpass filter size thresholds for structures
	bpBiglow=5;//mature AZs
	bpBigup=100;//mature AZs
	bpSmalllow=0;//immature AZs
	bpSmallup=3;//immature AZs
	referenceChannel=1;
	
	// Filters for object detection
	minCirc=0.0;
	minArea=0.02;
	
	// Parameters for radial profile analysis
	radius=40;
	shift=4;
	
	// Flag for drawing ROIs
	drawROIs=true;
	
	// Create user dialog to adjust parameters
	Dialog.create("Active Zone Segmenter   *****niclas.gimber@charite.de******");

		Dialog.addCheckbox("search only in selected area", drawROIs);
	  	
	  	Dialog.addMessage("***  Reference Channel (first channel: 1)  ***");
	  	Dialog.addNumber("", referenceChannel);
	  	Dialog.addMessage("\n");
	  	Dialog.addMessage("\n");	
	  	
	  	Dialog.addMessage("***  FFT Bandpass Filter (image based size exclusion)  ***");
	  	Dialog.addMessage("\n");
	  	Dialog.addNumber("Active Zone min size (pixels): ", bpBiglow);
	  	Dialog.addNumber("Active Zone max size (pixels): ", bpBigup);
	  	Dialog.addMessage("\n");
	  	Dialog.addNumber("Intermediates min size (pixels): ", bpSmalllow);
	  	Dialog.addNumber("Intermediates max size (pixels): ", bpSmallup);  	
	  	Dialog.addMessage("\n");
	  	Dialog.addMessage("\n");
	
	  	Dialog.addMessage("***  Enlarge ROIs  ***");
	  	Dialog.addMessage("\n");
	  	Dialog.addNumber("Enlarge Active Zone ROIs (pixels)", enlargeBig);
	  	Dialog.addNumber("Enlarge Intermediates ROIs (pixels)", enlargeSmall);
	  	Dialog.addMessage("\n");
	  	Dialog.addMessage("\n");
	  	
	  	Dialog.addMessage("***  Object Parameter Filters  ***");
	  	Dialog.addMessage("\n");
	  	Dialog.addNumber("Min Circularity", minCirc);
	  	Dialog.addNumber("min Area", minArea,7,10,"units");
	  	Dialog.addMessage("\n");
	  	Dialog.addMessage("\n");
	  	
	  	
	  	Dialog.addMessage("***  Radial Profile  Parameters  ***");
	  	Dialog.addMessage("\n");
	  	Dialog.addNumber("Radial Profile Radius (units)", radius);
	  	Dialog.addNumber("Randomization Shift (pixels)", shift);
	  	Dialog.addMessage("\n");
	  	Dialog.addMessage("\n"); 	
	
		Dialog.show();
	  	
	  	
	  	// Retrieve user inputs from dialog
	  	drawROIs = Dialog.getCheckbox();
		referenceChannel = Dialog.getNumber();  	
		bpBiglow = Dialog.getNumber();
		bpBigup = Dialog.getNumber();
		bpSmalllow = Dialog.getNumber();
		bpSmallup = Dialog.getNumber();
		enlargeBig = Dialog.getNumber();
		enlargeSmall = Dialog.getNumber();
		minCirc = Dialog.getNumber();
		minArea = Dialog.getNumber();		
		radius = Dialog.getNumber();
		shift = Dialog.getNumber();

	
	    // Print parameters to log file	
		print("\\Clear");
		print("reference channel (start with 0): "+referenceChannel);
		print("parameters_"+title+":");
		print("FFT Big in pixels= "+bpBiglow+":"+bpBigup);
		print("FFT Small in pixels= "+bpSmalllow+":"+bpSmallup);
		print("enlarge big in pixels= "+enlargeBig);
		print("enlarge small in pixels= "+enlargeSmall);
		print("radius= "+radius);
		print("shift= "+shift);
	
	
		selectWindow("Log");
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		saveAs("txt", subfolder+"log_"+title+"_"+year+""+month+""+dayOfMonth+""+"_"+hour+""+minute+".txt");
	
	}
// Set measurement parameters for analysis
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=5");
	
// ********** Batch Macro Start **********
title=getTitle();

run("Collect Garbage");
setSlice(referenceChannel);

//filter large structures
run("Duplicate...", " ");
rename("raw");
run("Duplicate...", " ");
run("Bandpass Filter...", "filter_large="+bpBigup+" filter_small="+bpBiglow+" suppress=None tolerance=0 autoscale saturate");
setAutoThreshold("MaxEntropy dark no-reset");
//setAutoThreshold("Otsu dark no-reset");
rename("rings");
//run("Threshold...");
run("Convert to Mask");



// Find small and large structures
selectWindow("raw");
run("Duplicate...", " ");
run("Bandpass Filter...", "filter_large=3"+bpSmallup+" filter_small="+bpSmalllow+" suppress=None tolerance=0 autoscale saturate");
setAutoThreshold("Moments dark no-reset");


rename("dotsNrings");
//run("Threshold...");
run("Convert to Mask");


roiManager("reset");
selectWindow("raw");
if(drawROIs==true){waitForUser("slectROI", "select ROI and press ok");}
else{run("Select All");}
roiManager("Add");
roiManager("Save", subfolder+"ROIs\\UserROI_"+title+".zip");





//clear outside and save masks
selectWindow("rings");
run("Duplicate...", "white");
rename("white");
roiManager("Select", 0);
run("Clear Outside");
setForegroundColor(225, 225, 225);
run("Fill", "slice");

saveAs("Tiff", subfolder+"Binary\\UserROI_"+title+".tif");
close();

selectWindow("rings");
roiManager("Select", 0);
run("Clear Outside");
wait(300);
run("Watershed");
saveAs("Tiff", subfolder+"Binary\\binaryMask_BigObjects_"+title+".tif");
rename("rings");



selectWindow("dotsNrings");
roiManager("Select", 0);
run("Clear Outside");
saveAs("Tiff", subfolder+"Binary\\binaryMask_allObjects_"+title+".tif");
rename("dotsNrings");


//analyze particles for all conditions
selectWindow("rings");
run("Analyze Particles...", "size="+minArea+"-Infinity display clear add");
roiManager("Save", subfolder+"ROIs\\onlyBig"+title+".zip");

nROIs=roiManager("count");
for(t=0;t<nROIs;t++)
	{
	roiManager("select", 0);
	run("Enlarge...", "enlarge="+enlargeBig+" pixel");
	roiManager("Add");
	roiManager("select", 0);
	roiManager("Delete");
	}
roiManager("Save", subfolder+"ROIs\\onlyBig_enlarge"+enlargeBig+"_"+title+".zip");

//close("ROI Manager");

selectWindow("dotsNrings");
run("Analyze Particles...", "size=0-Infinity display clear add");
roiManager("Save", subfolder+"ROIs\\_\\BigAndSmall"+title+".zip");

roiManager("Save", subfolder+"ROIs\\_\\BigAndSmall_"+title+".zip");


close("Results");



for (r=1;r<=channels;r++)
	{

	//measure enlaged big
	selectWindow(title);
	setSlice(r);	
	roiManager("reset");
	roiManager("Open", subfolder+"ROIs\\onlyBig_enlarge"+enlargeBig+"_"+title+".zip");
	nROIs=roiManager("count");
	close("Results");
	for (t=0;t<nROIs;t++) 
		{roiManager("Select", t);
		run("Measure");	
		}
	appendResults();
	saveAs("Results",  subfolder+"CSVs\\onlyBig_enl"+enlargeBig+"_"+title+"_ch"+r+".csv");


	//measure all big 
	selectWindow(title);
	setSlice(r);
	roiManager("reset");
	roiManager("Open", subfolder+"ROIs\\onlyBig"+title+".zip");
	nROIs=roiManager("count");
	close("Results");
	for (t=0;t<nROIs;t++) 
		{roiManager("Select", t);
		run("Measure");	
		}
	appendResults();
	saveAs("Results",  subfolder+"CSVs\\onlyBig_"+title+"_ch"+r+".csv");	
	}
	
	//export objects as tif
	selectImage(title);
	for (t=0;t<nROIs;t++) 
		{roiManager("Select", t);
		run("Duplicate...", "duplicate");
		saveAs("Tif", subfolder+"Objects\\"+title+"_"+t+".tif");		
		close();
		}

	
		//make radial profiles raw 
		selectWindow(title);
		run("Select All");
			
		getDimensions(width, height, channels, slices, frames);
		getPixelSize(unit, pixelWidth, pixelHeight);			
		xcoord=readArray("XM");					//read coordinates from result table
		ycoord=readArray("YM");					//read coordinates from result table	
		
		for (t=0; t<ycoord.length; t++)//calculate into units
			{								
	        ycoord[t]/=pixelWidth;
	        xcoord[t]/=pixelWidth;
			}					
		for (s=1;s<=channels;s++)
		{
		selectWindow(title);
		setSlice(s);
		rad2d(xcoord,ycoord,radius);						
		saveAs("Results", subfolder+"CSVs\\Rad_ch"+s+"_"+title+".csv");
		}

		//shift and do rad again
		selectWindow(title);
		doAllChannelShift(shift,2);
		for (s=1;s<=channels;s++)
		{
		selectWindow("shifted");
		setSlice(s);
		rad2d(xcoord,ycoord,radius);						
		saveAs("Results", subfolder+"CSVs\\Rad_shift_ch"+s+"_"+title+".csv");
		}	
		

	
	//measure all distances
	newImage("tmp", "8-bit black", width, height, 1);
	makeSelection("point", xcoord, ycoord);
	run("Convex Hull");
	setForegroundColor(255, 255, 255);
	run("Fill", "slice");
	run("Morphological Filters", "operation=Dilation element=Square radius=2");
	run("Distance Map");
	rename("Distance Map");
	close("tmp");
	run("Set Measurements...", "min  display redirect=None decimal=5");
	selectWindow("Distance Map");
	roiManager("reset");
	roiManager("Open", subfolder+"ROIs\\onlyBig"+title+".zip");
	nROIs=roiManager("count");
	close("Results");
	for (u=0;u<nROIs;u++) 
		{roiManager("Select", u);
		run("Measure");	
		}
	appendResults();
	saveAs("Results",  subfolder+"CSVs\\Distances_"+title+"_ch"+r+".csv");	


	
// print logfile

	print("\\Clear");
	print("parameters_"+title+":");
	print("FFT Big in pixels= "+bpBiglow+":"+bpBigup);
	print("FFT Small in pixels= "+bpSmalllow+":"+bpSmallup);
	print("enlarge big in pixels= "+enlargeBig);
	print("enlarge small in pixels= "+enlargeSmall);
	print("Filter: minimal Area in units= "+minArea);
	print("Filter: minimal Circularity in units= "+minCirc);
	selectWindow("Log");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	saveAs("txt", subfolder+"log_"+title+"_"+year+""+month+""+dayOfMonth+""+"_"+hour+""+minute+".txt");

close("rings");
close("dotsNrings");
close("raw");
close("Results");

roiManager("reset");


function appendResults() 
	{
		for(row=0;row<nResults;row++)
		{
	diameter=pow((getResult("Area", row)/PI),0.5)*2;
	setResult("Diameter", row, diameter);
	
	
	feretRatio=getResult("MinFeret", row)/getResult("Feret", row);
	setResult("FeretRatio", row, feretRatio);
		}
	}


	
function rad2d(xcoord,ycoord,radius)//rad profile along coordinates in pixels
	{ 
	run("Clear Results");
	for (j=0;j<lengthOf(xcoord);j++)	
		{
		xc=xcoord[j];
		yc=ycoord[j];
		print(xc,yc);
		
		
		makePoint(xc, yc, "small yellow hybrid");
		wait(20);
		run("Radial Profile", "x="+xc+" y="+yc+" radius="+radius+"");
		//run("Radial Profile", "x="+255.6+" y="+178.8+" radius="+10+"");
		selectWindow("Radial Profile Plot");
		
		Plot.getValues(x, y);
		for (i=0; i<x.length; i++)	
		      {
		      print(x[i], y[i]);
		      setResult("x (pixels)", i, x[i]);
		      setResult(j, i, y[i]); 
		      }
		close("Radial Profile Plot");	
		}
	updateResults; 
	}


function readArray(columnname)
	{
	storageArray=newArray(nResults);
	for(row=0;row<nResults;row++)
		{
		storageArray[row]=getResult(columnname, row);
		}
		return storageArray;
	}



function doAllChannelShift(shift,shiftchannel)	
	{	
	title=getTitle();
	Stack.getDimensions(width, height, channels, slices, frames);

	selectWindow(title);
	makeRectangle(0, 0, shift, height);
	run("Duplicate...", "title=left duplicate");


	selectWindow(title);
	makeRectangle(shift, 0, width, height);
	run("Duplicate...", "title=right duplicate");


	run("Combine...", "stack1=right stack2=left");
	rename("shifted");



	}


//**************end batch macro

}
close("*");
close("Results");}