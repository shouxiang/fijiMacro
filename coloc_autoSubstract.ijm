	// select the source folder 
	inDir = getDirectory("Please select the source folder");
	
	if (inDir=="")
		exit("No input directory available");
	
	redOrdinalNumber = getNumber("Channel number of Red", 1);
	greenOrdinalNumber = getNumber("Channel number of Green", 3);

 	// colocList for images to be analysed, bgList for background pics
 	colocList = newArray(getNumber("How many pics do you want to do coloc???", 2));
 	colocNameOnly = newArray(colocList.length);
 	
 	// Order new pics as requested by user
	
	for(i = 0; i < colocList.length; i++){
		
		colocList[i] = File.openDialog("Please select files by the order you want them to be analyzed. #" +i+1);
		colocNameOnly[i] = File.nameWithoutExtension;
	}

	// create a destination folder containing single, merged, montage images with adjusted intensity
	fs = File.separator;
	
	adjustedIntensityDir = inDir + "adjustedIntensity" + fs;
	File.makeDirectory(adjustedIntensityDir);
	
	rawIntensityDir = inDir + "rawIntensity" + fs;
	File.makeDirectory(rawIntensityDir);

	// Batch processing in orderedList
	setBatchMode(true);
	
 	for(i = 0; i < colocList.length; i++){
 		
 		run("Bio-Formats Macro Extensions");
 		Ext.openImagePlus(colocList[i]);
		
 		// Get channel numbers and examine whether all images have the same dimensions
 		if(i==0){
			getDimensions(width, height, channels, slices, frames);
			channelCount = channels;
		}else{
			getDimensions(width, height, channels, slices, frames);
			if(channelCount != channels)
				exit("Pics not matching format");
		};
		rename(colocNameOnly[i]);
		
		// Different channels of each images are Split. Red and green channels of raw pics are saved.
 		run("Split Channels");
 		
 		selectWindow("C" + redOrdinalNumber + "-" + colocNameOnly[i]);
 		rename("red-" + colocNameOnly[i]);
 		run("Duplicate...", " ");
 		outDir = rawIntensityDir + "red-raw-" + colocNameOnly[i];
 		saveAs("tiff", outDir);

 		selectWindow("C" + greenOrdinalNumber + "-" + colocNameOnly[i]);
 		rename("green-" + colocNameOnly[i]);
 		run("Duplicate...", " ");
 		outDir = rawIntensityDir + "green-raw-" + colocNameOnly[i];
 		saveAs("tiff", outDir);
 	}

	//Make stacks of adjusted red and green channels
 	for(j = 0; j < colocList.length - 1; j++){
 		if(j == 0){
 			run("Concatenate...", "  title=Red open image1=[red-"+colocNameOnly[j]+"] image2=[red-"+colocNameOnly[j+1]+"] image3=[-- None --]");
 		}else{
 			run("Concatenate...", "  title=Red open image1=[Red] image2=[red-"+colocNameOnly[j+1]+"] image3=[-- None --]");
 		}	
 	}

 	for(j = 0; j < colocList.length - 1; j++){
 		if(j == 0){
 			run("Concatenate...", "  title=Green open image1=[green-"+colocNameOnly[j]+"] image2=[green-"+colocNameOnly[j+1]+"] image3=[-- None --]");
 		}else{
 			run("Concatenate...", "  title=Green open image1=[Green] image2=[green-"+colocNameOnly[j+1]+"] image3=[-- None --]");
 		}	
 	}
 		

 	// Merge channels and adjust the Brightness/Contrast manually
 	setBatchMode("exit and display");
 	waitForUser("Attention","Please merge red and green channels and adjust the Brightness/Contrast manually, then press OK to proceed");
 	setBatchMode(true);
 	
 	// Merged image stack is split to single channels 
 	rename("MergedStack");
 	run("Duplicate...", "title=MergedStack-copy duplicate");
 	selectWindow("MergedStack");
	run("Split Channels");
 	
	// save red channels of single images and montage

	selectWindow("C1-MergedStack");
	run("RGB Color");
	run("Make Montage...", "columns="+colocList.length+" rows=1 scale=1 border=5");
	outDir = adjustedIntensityDir + "red-adjusted-montage";
	saveAs("tiff", outDir);

	selectWindow("C1-MergedStack");
	run("Stack to Images");
	for(j = 0; j < colocList.length; j++){
				
		selectWindow("C1-MergedStack-000" + j+1);
		outDir = adjustedIntensityDir + "red-adjusted-" + colocNameOnly[j];
		saveAs("tiff", outDir);
	}

	// save green channels of single images and montage

	selectWindow("C2-MergedStack");
	run("RGB Color");
	run("Make Montage...", "columns="+colocList.length+" rows=1 scale=1 border=5");
	outDir = adjustedIntensityDir + "green-adjusted-montage";
	saveAs("tiff", outDir);

	selectWindow("C2-MergedStack");
	run("Stack to Images");
	for(j = 0; j < colocList.length; j++){
				
		selectWindow("C2-MergedStack-000" + j+1);
		outDir = adjustedIntensityDir + "green-adjusted-" + colocNameOnly[j];
		saveAs("tiff", outDir);
	}

	// save merged images
	selectWindow("MergedStack-copy");
 	run("RGB Color", "frames");
 	run("Make Montage...", "columns="+colocList.length+" rows=1 scale=1 border=5");
	outDir = adjustedIntensityDir + "merged-adjusted-montage";
	saveAs("tiff", outDir);

	selectWindow("MergedStack-copy");
	run("Stack to Images");
	for(j = 0; j < colocList.length; j++){
		
		selectWindow("MergedStack-copy-000" + j+1);
		outDir = adjustedIntensityDir + "merged-" + colocNameOnly[j];
		saveAs("tiff", outDir);
	}

	// Set background as BLACK
	run("Options...", "iterations=1 count=1 black");

	// Make red, green and combined mask of background pics and each pics to be analyzed
	for(i = 0; i < colocList.length; i++){

		selectWindow("red-raw-" + colocNameOnly[i] + ".tif");
		run("Duplicate...", " ");
		setAutoThreshold("Default dark");
		run("Convert to Mask");
		outDir = adjustedIntensityDir + "red-mask-" + colocNameOnly[i];
		saveAs("tiff", outDir);

		selectWindow("green-raw-" + colocNameOnly[i] + ".tif");
		run("Duplicate...", " ");
		setAutoThreshold("Default dark");
		run("Convert to Mask");
		outDir = adjustedIntensityDir + "green-mask-" + colocNameOnly[i];
		saveAs("tiff", outDir);

		imageCalculator("OR create", "red-mask-"+colocNameOnly[i]+".tif","green-mask-"+colocNameOnly[i]+".tif");
		selectWindow("Result of red-mask-" + colocNameOnly[i] + ".tif");
		rename("combined-mask-" + colocNameOnly[i]);
		run("Duplicate...", " ");
		outDir = adjustedIntensityDir + "combined-mask-" + colocNameOnly[i];
		saveAs("tiff", outDir);
	}

	//Make stacks and montages of red, green and combined masks 
	 
 	for(j = 0; j < colocList.length - 1; j++){
 		if(j == 0){
 			run("Concatenate...", "  title=Red-Mask open image1=[red-mask-"+colocNameOnly[j]+".tif] image2=[red-mask-"+colocNameOnly[j+1]+".tif] image3=[-- None --]");
 		}else{
 			run("Concatenate...", "  title=Red-Mask open image1=[Red-Mask] image2=[red-mask-"+colocNameOnly[j+1]+".tif] image3=[-- None --]");
 		}	
 	}
 	run("RGB Color");
	run("Make Montage...", "columns="+colocList.length+" rows=1 scale=1 border=5");
	outDir = adjustedIntensityDir + "red-mask-montage";
	saveAs("tiff", outDir);
 	

 	for(j = 0; j < colocList.length - 1; j++){
 		if(j == 0){
 			run("Concatenate...", "  title=Green-Mask open image1=[green-mask-"+colocNameOnly[j]+".tif] image2=[green-mask-"+colocNameOnly[j+1]+".tif] image3=[-- None --]");
 		}else{
 			run("Concatenate...", "  title=Green-Mask open image1=[Green-Mask] image2=[green-mask-"+colocNameOnly[j+1]+".tif] image3=[-- None --]");
 		}	
 	}
 	run("RGB Color");
	run("Make Montage...", "columns="+colocList.length+" rows=1 scale=1 border=5");
	outDir = adjustedIntensityDir + "green-mask-montage";
	saveAs("tiff", outDir);

	for(j = 0; j < colocList.length - 1; j++){
 		if(j == 0){
 			run("Concatenate...", "  title=Combined-Mask open image1=[combined-mask-"+colocNameOnly[j]+"] image2=[combined-mask-"+colocNameOnly[j+1]+"] image3=[-- None --]");
 		}else{
 			run("Concatenate...", "  title=Combined-Mask open image1=[Combined-Mask] image2=[combined-mask-"+colocNameOnly[j+1]+"] image3=[-- None --]");
 		}	
 	}
 	run("RGB Color");
	run("Make Montage...", "columns="+colocList.length+" rows=1 scale=1 border=5");
	outDir = adjustedIntensityDir + "combined-mask-montage";
	saveAs("tiff", outDir);

/*	// Stack and output images and mask for check
	run("Concatenate...", "  title=final keep open "+
	"image1=[red-adjusted-montage.tif] "+
	"image2=[green-adjusted-montage.tif] "+
	"image3=[red-mask-montage.tif] "+
	"image4=[green-mask-montage.tif] "+
	"image5=[combined-mask-montage.tif] "+
	"image6=[merged-adjusted-montage.tif] "+
	"image7=[-- None --]");

	run("Make Montage...", "columns=1 rows=6 scale=1 border=5");
	outDir = adjustedIntensityDir + "finalCompare";
	saveAs("tiff", outDir);

*/

	// Stack and output images and mask for check
	run("Concatenate...", "  title=final keep open "+
	"image1=[red-adjusted-montage.tif] "+
	"image2=[green-adjusted-montage.tif] "+
	"image3=[merged-adjusted-montage.tif] "+
	"image4=[combined-mask-montage.tif] "+
	"image5=[-- None --] ");

	run("Make Montage...", "columns=1 rows=4 scale=1 border=5");
	outDir = adjustedIntensityDir + "finalCompare";
	saveAs("tiff", outDir);

	print("Columns (different treatments): ");
	for(i = 0; i < colocList.length; i++)
		print(colocNameOnly[i]);

	print("\nRows (different channels): ");
	print("red-adjusted");
	print("green-adjusted");
	print("red-mask");
	print("green-mask");
	print("combined mask");
	print("Merged adjusted \n");

	for(i = 0; i < colocList.length; i++){
		
		run("Coloc 2", 
	 	"channel_1=[red-raw-"+colocNameOnly[i]+".tif] "+
	 	"channel_2=[green-raw-"+colocNameOnly[i]+".tif] "+
	 	"roi_or_mask=[combined-mask-"+colocNameOnly[i]+".tif] "+
	 	"threshold_regression=Costes display_images_in_result display_shuffled_images "+
	 	"manders'_correlation 2d_intensity_histogram costes'_significance_test "+
	 	"psf=3 costes_randomisations=100");
	}
	
	run("Close All");
	run("Collect Garbage");