getDimensions(width, height, channels, slices, frames);

if (slices > 1) {
	run("Z Project...", "projection=[Max Intensity] all");
}

setTool("rectangle");

setAutoThreshold("Default dark");

run("Convert to Mask", "method=Default background=Dark calculate");

waitForUser("Make a selection around the penetrating vessel.\n\nClick OK when finished.");

run("Clear Outside", "stack");

run("Analyze Particles...", "size=5-Infinity show=Outlines display stack");

