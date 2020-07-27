# VasoMetrics
This repository contains the VasoMetrics macro, useful for quick spatiotemporal analysis of images containing vessels.

## Installation
The macro can be installed by accessing this Github repository. There are many different ways to access the data in a Github repository. The easiest way to download the macro is to click the green *Code* button, and then clicking *Download Zip*. The downloaded compressed file will need to be extracted. Other methods of obtaining the code can be found [here](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository).

Once the code has been downloaded, open ImageJ/Fiji. On the main menu, click *Plugins -> Macros -> Install...* A file selection window will open. Locate the extracted *VasoMetrics.ijm* file and select it. The macro will then have an action tool icon (indicated by the letter V) on your toolbar. Click this button to execute the macro. If you cannot locate the button, or would like to quickly run VasoMetrics, select *Run...* instead of *Install...* from the macros menu. 

Once VasoMetrics is executed for the first time, it will install itself into the Startup Macros list, and will appear on your toolbar whenever you close and reopen ImageJ/Fiji. 

## Usage
Everytime VasoMetrics launches, it will check for updates against this GitHub repository. Should an update be available, a prompt will appear which will allow for self-updating and viewing the updates. The updated code will be utilized upon the next launch of the macro. 

An image needs to be opened for VasoMetrics to function. VasoMetrics will automatically perform a maximum intensity projection if there are slices in the image (*Image -> Stacks -> Z Project...*). To check the slices/frames arrangement in your image, select *Image -> Properties...* 

Once the image is ready, VasoMetrics will prompt for the user to draw a through-line. The through-line is used to guide the placement of the lines that will be used to determine the diameter (cross-lines). The through-line placement is important, and needs to be parallel and centered within the target vessel. An improperly placed through-line could result in failures to measure correctly. The through-line can be segmented by left clicking, allowing you to trace a vessel's curves. To finish drawing the through-line, right click when placing the final point. 

![Example Paths](https://github.com/mcdowellkonnor/ResearchMacros/blob/master/PathsExample.jpg)

Next, you can either choose to automatically determine cross-line length or manually enter the length. Cross-lines are used to obtain intensity profiles, and need to be long enough to span the entire vessel and some of the background. The automatic length is calculated by taking a the intensity profile of a long line perpendicular to the first through-line segment, and is sufficient in most cases. 

Finally, enter the spacing between cross-lines.

![Example Spacing](https://github.com/mcdowellkonnor/ResearchMacros/blob/master/SpacingExample.jpg)

After confirming the spacing, VasoMetrics will measure FWHM for each cross-line, in each frame. It will then output a table and figure similar to the one below. Re-running the program will result in prompts confirming clearing the results table and the ROI manager.

![Example Results](https://github.com/mcdowellkonnor/ResearchMacros/blob/master/ResultsExample.png)

To manipulate the results further, you will need to export the data to a spreadsheet or to Matlab. The data can be copied and pasted into Matlab as a vector. Otherwise, you can click *File -> Save As...* on the results pop-up to save the data.

## Contributing and Error Reporting
For major changes/issues, please open an issue to discuss what you would like to change. You can open an issue [here](https://github.com/mcdowellkonnor/ResearchMacros/issues), although this will require having a Github account. 
