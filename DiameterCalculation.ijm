requires("1.45s");
setOption("ExpandableArrays", true);

function getIntersection(centerX, centerY, radius, slope, yInt) {
	a = pow(slope, 2) + 1;
	b = 2 * ((slope * yInt) - (slope * centerY) - centerX);
	c = pow(centerY, 2) - pow(radius, 2) + pow(centerX, 2) - (2 * yInt * centerY) + pow(yInt, 2);
	x1 = (-1 * b + sqrt(pow(b, 2) - 4 * a * c)) / (2 * a);
	x2 = (-1 * b - sqrt(pow(b, 2) - 4 * a * c)) / (2 * a);
	return newArray(x1, x2);
}

function index(a, value) { 
	for (i=0; i<a.length; i++) if (a[i]==value) return i; 
	return -1; 
} 

function getProfilesForSlice(sliceNum) {
	profiles = newArray;
	for (i = 0; i < roiManager("count"); i++) {
		roiManager("select", i);
		// Obtain the intensity profile and normalize it
		getDimensions(width, height, channels, slices, frames);
		
		if (slices > 1) {
			setSlice(sliceNum);
		} else if (frames > 1) {
			Stack.setFrame(sliceNum);
		}

		profile = getProfile();
		Array.getStatistics(profile, min, max, mean, stdDev);
		for (c=0; c<profile.length; c++) profile[c] = (profile[c] - min) / (max - min);
		profiles = Array.concat(profiles, profile);
	}
	return profiles;
}

function getFWHMFromProfiles(profiles, profileLength, pixelScale) {
	fwhms = newArray;
	for (i = 0; i < (profiles.length / profileLength); i++) {
		profile = Array.slice(profiles, i * profileLength, (i+1) * profileLength - 1);
		// Obtain the FWHM value for this profile
		Array.getStatistics(profile, min, max, mean, stdDev);
		halfMax = max / 2;
		intersects = newArray;
		for (c=0; c < (profile.length - 1); c++) {
			profileSlope = (profile[c+1] - profile[c]);
			profileYInt = profile[c] + (-1 * profileSlope * c);
			xInt = (halfMax - profileYInt) / profileSlope;
			if (xInt >= c && xInt <= (c+1)) {
				intersects[intersects.length] = xInt;
			}
		}

		Array.getStatistics(intersects, min, max, mean, stdDev);
		fwhms[fwhms.length] = (max - min) * pixelScale;
	}
	return fwhms;
}

function findApproximateLength(x, y, imgHeight) {
	run("Z Project...", "projection=[Max Intensity] all");
	run("Median...", "radius=10 stack");
	run("Find Edges", "stack");
	maxPeakDist = 0;
	for (i = 0; i < x.length - 1; i++) {
		invM = -1 / ((y[i+1] - y[i]) / (x[i+1] - x[i]));
		invB = ((y[i+1] + y[i])/2) + (-1 * invM * ((x[i+1] + x[i]) / 2));

		if (invM > 0) {
			makeLine(0, invB, (imgHeight - invB) / invM, imgHeight);
		} else {
			makeLine(0, invB, (0 - invB) / invM, 0);	
		}
		
		profile = getProfile();

		// Determine the peak ranges of this profile
		Array.getStatistics(profile, min, max, mean, stdDev);
		maxima = Array.findMaxima(profile, mean);
		dist = sqrt(pow(((x[i+1] + x[i]) / 2) - 0, 2) + pow(((y[i+1] + y[i])/2) - invB, 2));

		peakLeft = 0;
		peakRight = 99999;
		for (peakNum = 0; peakNum < maxima.length; peakNum++) {
			if (maxima[peakNum] < dist && (dist - maxima[peakNum] < dist - peakLeft)) {
				peakLeft = maxima[peakNum];
			} else if (maxima[peakNum] > dist && (maxima[peakNum] - dist < peakRight - dist)) {
				peakRight = maxima[peakNum];
			}
		}
		
		// Determine the peak distance and set the approximate length to that distance but include a tolerance
		peakDist = peakRight - peakLeft;
		peakDist += 40;
		if (peakDist > maxPeakDist) maxPeakDist = peakDist;
	}
	close();
	return maxPeakDist / 2;
}

originalFileName = getInfo("image.filename");
setTool("polyline");
do {
	waitForUser("Please draw through line.\n\nClick OK when finished.");
} while (selectionType() != 6)

getSelectionCoordinates(x, y);

// Prepare for operation by getting information about the image
getDimensions(width, height, channels, slices, frames);
getPixelSize(pixelUnit, pixelWidth, pixelHeight);
frameRate = getInfo("framerate");

if (slices > 1) run("Z Project...", "projection=[Max Intensity] all");

startingSlice = getSliceNumber();
meanFwhms = newArray;
meanFwhmSTDEVs = newArray;
roiManager("reset");
maxFWHM = 0;

// Determine the settings for the cross-lines
cLength = findApproximateLength(x, y, height);
cSpace = 5;

// Calculate any excess distance on the through-line so that the cross-lines can be centered
totalLength = 0;
for (i = 0; i < x.length - 1; i++) totalLength += sqrt(pow(x[i+1]-x[i],2) + pow(y[i+1]-y[i],2));
excessLength = totalLength % cSpace;

slices = frames;
for (slice = 1; slice <= slices; slice++) {
	showProgress(slice, slices);
	fwhms = newArray;

	// Parse through the line segments and create the cross-lines
	if (slice == 1) {
		lastX = 0;
		lastY = 0;
		for (i = 0; i < x.length - 1; i++) {
			slope = (y[i+1] - y[i]) / (x[i+1] - x[i]);
			inverseSlope = -1 / slope;
			yInt = y[i] + (-1 * slope * x[i]);

			// Move the starting point based on the excess so that the cross-lines are centered
			if (i == 0) {
				val = getIntersection(x[i], y[i], excessLength / 2, slope, yInt);
				if (x[i+1] > x[i]) {
					movingX = maxOf(val[0], val[1]);
				} else {
					movingX = minOf(val[0], val[1]);
				}
			}

			// Move the starting points on line-segments following the first so that equal cross-line distance is maintained
			if (i > 0) {
				val = getIntersection(lastX, lastY, cSpace, slope, yInt);
				if (x[i+1] > x[i]) {
					movingX = maxOf(val[0], val[1]);
				} else {
					movingX = minOf(val[0], val[1]);
				}
			}
	
			while (movingX <= maxOf(x[i], x[i+1]) && movingX >= minOf(x[i], x[i+1])) {
				movingY = slope * movingX + yInt;
				invYInt = movingY + (-1 * inverseSlope * movingX);
				val = getIntersection(movingX, movingY, cLength, inverseSlope, invYInt);
		
				// The Cross Line:
				makeLine(maxOf(val[0], val[1]), inverseSlope * maxOf(val[0], val[1]) + invYInt, minOf(val[0], val[1]), inverseSlope * minOf(val[0], val[1]) + invYInt);
				Roi.setStrokeColor("red");
				roiManager("add");

				// Move the current x value
				lastX = movingX;
				lastY = movingY;
				val = getIntersection(movingX, movingY, cSpace, slope, yInt);
				if (x[i+1] > x[i]) {
					movingX = maxOf(val[0], val[1]);
				} else {
					movingX = minOf(val[0], val[1]);
				}
			}
			roiManager("show all with labels");
		}
	}

	// Parse through the cross-lines and obtain the FWHM values
	profiles = getProfilesForSlice(slice);
	fwhms = getFWHMFromProfiles(profiles, (cLength * 2) + 1, pixelWidth);

	Array.getStatistics(fwhms, min, max, mean, stdDev);
	setResult("Frame", slice-1, slice);
	if (frameRate != "") setResult("Time (sec)", slice-1, slice * frameRate);
	setResult("Mean (" + pixelUnit + ")", slice-1, mean);
	setResult("Sigma", slice-1, stdDev);
	for (i = 0; i < fwhms.length; i++) setResult("Line " + (i+1), slice-1, fwhms[i]);

	// Set the maximum FWHM measurement to be used in the heatmap
	if (max > maxFWHM) maxFWHM = max;

	if (mean == NaN || mean == (1/0) || mean == -(1/0)) {
		mean = 0;
		stdDev = 0;
	}
	meanFwhms[meanFwhms.length] = mean;
	meanFwhmSTDEVs[meanFwhmSTDEVs.length] = stdDev;
}
setSlice(startingSlice);
updateResults();

if (slices > 1) {
	xValues = Array.slice(Array.getSequence(slices + 1), 1);
	
	xLabel = "Time (seconds)";
	if (frameRate == "") {
		frameRate = 1;
		xLabel = "Frame Number";
	}
	
	for (i = 0; i < xValues.length; i++) xValues[i] = xValues[i] * frameRate;
	Plot.create("FWHM Diameter vs Slice Number for " + originalFileName, xLabel, "FWHM Diameter (" + pixelUnit + ")", xValues, meanFwhms);
	Array.getStatistics(meanFwhms, min, maxY, mean, stdDev);
	Array.getStatistics(xValues, minX, maxX, mean, stdDev);
	Plot.setLimits(minX, maxX, 0, maxY);
	Plot.show();
}
