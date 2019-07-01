requires("1.45s");
setOption("ExpandableArrays", true);

function getIntersects(yValue, profile) {
	intersects = newArray;
	for (c=0; c < (profile.length - 1); c++) {
		profileSlope = (profile[c+1] - profile[c]);
		profileYInt = profile[c] + (-1 * profileSlope * c);
		xInt = (yValue - profileYInt) / profileSlope;
		if (xInt >= c && xInt <= (c+1)) {
			intersects[intersects.length] = xInt;
		}
	}
	return intersects;
}

roiManager("reset");
run("Clear Results");
getPixelSize(unit, pixelWidth, pixelHeight);

getDimensions(width, height, channels, slices, frames);

objects = getNumber("Enter the number of objects", 6);

verticalLinesDrawn = 0;
lastX = 0;
while (verticalLinesDrawn != (objects - 1)) {
	setTool("point");
	waitForUser("Click a position between objects " + (verticalLinesDrawn + 1) + " and " + (verticalLinesDrawn + 2));
	getSelectionCoordinates(xpoint, ypoint);
	makeRectangle(lastX, 0, xpoint[0] - lastX, height);
	lastX = xpoint[0];
	roiManager("add");
	verticalLinesDrawn++;
}

// Add the last region
makeRectangle(lastX, 0, width - lastX, height);
roiManager("add");

scope = getNumber("Enter the y scope in " + unit, 200);
scopeOffset = getNumber("Enter the scope offset in " + unit, scope/4);
if (scopeOffset > scope) exit("Scope offset cannot be greater than the scope.");

rowOffset = 0;
offsetIncrementSet = false;
offsetIncrement = 0;
for (frameNum = 0; frameNum < frames; frameNum++) {	
	for (regNum = 0; regNum < objects; regNum++) {
		roiManager("select", regNum);
		Stack.setFrame(frameNum + 1);
		Roi.getBounds(x, y, width, height);
		
		rectY = 0;
		rowNum = rowOffset;
		while (rectY + scope < height) {
			makeRectangle(x, rectY, width, scope);
			profile = getProfile();
			Array.getStatistics(profile, min, max, mean, stdDev);
			intersects = getIntersects(max/2, profile);
	
			setResult("Scope - Start Y (" + unit + ")", rowNum, rectY);
			setResult("Scope - End Y (" + unit + ")", rowNum, rectY + scope);
			if (intersects.length >= 2) {
				setResult("Object " + (regNum + 1) + " Diameter (" + unit + ")", rowNum, (intersects[1] - intersects[0]) * pixelWidth);
			} else {
				setResult("Object " + (regNum + 1) + " Diameter (" + unit + ")", rowNum, NaN);
			}
	
			// Move the window
			rectY += scope;
			rectY -= scopeOffset;
			rowNum++;
		}
	}

	if (!offsetIncrementSet) {
		offsetIncrement = rowNum;
		offsetIncrementSet = true;
	}
	
	rowOffset += offsetIncrement;
}
