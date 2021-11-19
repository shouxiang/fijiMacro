	// select the source folder 
	inDir = getDirectory("Please select the source folder");
	
	if (inDir=="")
		exit("No input directory available");

/*	// select .czi only from source folder
	rawFileList = getFileList(inDir);
	listTmp= newArray(rawFileList.length);
	picCount = 0;
	
	for(i = 0; i < rawFileList.length ; i++)
		if(endsWith(rawFileList[i], ".czi") || endsWith(rawFileList[i], ".tif")){
			listTmp[picCount] = rawFileList[i];
			picCount++;
		}

	cziList = Array.trim(listTmp,picCount); */

 	// Order new pics as requested by user
 	orderedList = newArray(getNumber("How many pics do you want to do montage??? >1", 2));
 	picNameOnly = newArray(orderedList.length);
 	
	for(i = 0; i < orderedList.length; i++){
		
		orderedList[i] = File.openDialog("Please select files by the order you want them to be shown. #" +i+1);
		picNameOnly[i] = File.nameWithoutExtension;
	}

	// Batch processing in orderedList
	setBatchMode(true);
	
 	for(i = 0; i < orderedList.length; i++){
 		
 		run("Bio-Formats Macro Extensions");
 		Ext.openImagePlus(orderedList[i]);
		
 		// Get channel numbers and examine whether all images have the same dimensions
 		if(i==0){
			getDimensions(width, height, channels, slices, frames);
			channelCount = channels;
		}else{
			getDimensions(width, height, channels, slices, frames);
			if(channelCount != channels)
				exit("Pics not matching format");
		};
		rename(File.getName(orderedList[i]));
		
		// Different channels of each images are Split. Images of the same channel is concatenated and named "Ci-Stack"
 		run("Split Channels");
 	}

 	for(i = 0; i < channelCount; i++){
 		
 		for(j = 0; j < orderedList.length - 1; j++){
 			if(j == 0){
 				run("Concatenate...", "  title=C"+i+1+" open image1=[C"+i+1+"-"+File.getName(orderedList[j])+"] image2=[C"+i+1+"-"+File.getName(orderedList[j+1])+"] image3=[-- None --]");
 			}else{
 				run("Concatenate...", "  title=C"+i+1+" open image1=[C"+i+1+"] image2=[C"+i+1+"-"+File.getName(orderedList[j+1])+"] image3=[-- None --]");
 			}	
 		}
 	}

 	// Merge channels and adjust the Brightness/Contrast manually
 	setBatchMode("exit and display");
 	waitForUser("Attention","Please merge channels and adjust the Brightness/Contrast manually, then press OK to proceed");

 	getDimensions(width, height, channels, slices, frames);
 	channelDisplayedCount = channels;

 	// Merged image stack is split to single channels 
 	rename("MergedStack");
 	run("Duplicate...", "title=MergedStack-copy duplicate");
 	selectWindow("MergedStack");
	run("Split Channels");
 	
 	// create a destination folder containing single, merged, montage images with adjusted intensity
	fs = File.separator;
	
	adjustedIntensityDir = inDir + "adjustedIntensity" + fs;
/*
	if (File.exists(adjustedIntensityDir))
		exit("Unable to create output directory");
		else 
		File.makeDirectory(adjustedIntensityDir);
*/
	File.makeDirectory(adjustedIntensityDir);
	
	byChannelsDir = adjustedIntensityDir + "byChannels" + fs;
	File.makeDirectory(byChannelsDir);
	
	for(i = 0; i < orderedList.length; i++){
		
		outDir = adjustedIntensityDir + picNameOnly[i] + fs;
		File.makeDirectory(outDir);
	}

	// save single images
	channelName = newArray(channelDisplayedCount);
	for(i = 0; i < channelDisplayedCount; i++){
		
		selectWindow("C" + i+1 + "-MergedStack");
		run("RGB Color");
		run("Make Montage...", "columns="+orderedList.length+" rows=1 scale=1 border=5");
		channelName[i] = getString("Please enter the name of the channel", "TPE");
		outDir = byChannelsDir + channelName[i] + "-montage";
		saveAs("tiff", outDir);
		
		selectWindow("C" + i+1 + "-MergedStack");
		run("Stack to Images");
		for(j = 0; j < orderedList.length; j++){
				
			selectWindow("C" + i+1 + "-MergedStack-000" + j+1);
			rename(channelName[i] + "-" + picNameOnly[j]);
			outDir = adjustedIntensityDir + picNameOnly[j] + fs + channelName[i] + "-" + picNameOnly[j];
			saveAs("tiff", outDir);
		}	
	}

	// save merged images
	selectWindow("MergedStack-copy");
 	run("RGB Color", "frames");
 	run("Make Montage...", "columns="+orderedList.length+" rows=1 scale=1 border=5");
 	rename("Merged-montage");
	outDir = byChannelsDir + "Merged-montage";
	saveAs("tiff", outDir);

	selectWindow("MergedStack-copy");
	run("Stack to Images");
	for(j = 0; j < orderedList.length; j++){
		
		selectWindow("MergedStack-copy-000" + j+1);
		rename("Merged-" + picNameOnly[j]);
		outDir = adjustedIntensityDir + picNameOnly[j] + fs + "Merged-" + picNameOnly[j];
		saveAs("tiff", outDir);
	}

	// Order channels to be displayed
	
 	orderedChannel = newArray(channelDisplayedCount + 1);
 	orderedChannelNameOnly = newArray(channelDisplayedCount + 1);
 	
 	for(i = 0; i < orderedChannel.length; i++){
 		orderedChannel[i] = File.openDialog("Please select channels by the order you want them to be shown. #" +i+1);
 		orderedChannelNameOnly[i] = File.nameWithoutExtension;
 	}
 		

 	for(j = 0; j < orderedChannel.length - 1; j++){
 			if(j == 0){
 				run("Concatenate...", "  title=finalStack open image1=["+File.getName(orderedChannel[j])+"] image2=["+File.getName(orderedChannel[j+1])+"] image3=[-- None --]");
 			}else{
 				run("Concatenate...", "  title=finalStack open image1=[finalStack] image2=["+File.getName(orderedChannel[j+1])+"] image3=[-- None --]");
 			}	
 	}
 	selectWindow("finalStack");
 	run("Make Montage...", "columns=1 rows="+orderedChannel.length+" scale=1 border=5");
	outDir = byChannelsDir + "result";
	saveAs("tiff", outDir);

	print("Columns (different treatments): ");
	for(i = 0; i < orderedList.length; i++)
		print(File.getName(orderedList[i]));

	print("\nRows (different channels): ");
	for(i = 0; i < orderedChannelNameOnly.length; i++)
		print(orderedChannelNameOnly[i]);
	
	run("Close All");
	run("Collect Garbage");

