This GUI can be used to detect tap onset times (i.e. times where the finger contacted the tapping surface), based on continuous data measured with a tapping box (hardware setup explained in class - see the slides for more details). 

The GUI is intentionally made very simple, so that it can be **inspected and adapted** for a particular use case. Please feel inspired :) 

There are two versions of the GUI. 

### 2018 version

`onset_extraction_GUI_2018.m` was tested under MATLAB 2018a on Mac. Due to changes in the figure interaction framework that Matlab introduced between 2018 and 2020, this won't work on more recent versions, in which case, try the 2025 version (below). 

Quickstart: 
1. Run the `onset_extraction_GUI_2018.m` file in Matlab (first, change working directory to the folder where the file is located). 
2. This should already load the continuous signal recorded from the tapping box, and check if there are any tap onset times already detected. If not, it will automatically detect them. 
3. Play with value for Amplitude threshold and click "autodetect". The minimum ITI value is less useful, and autodetect generally works fine when it's set to ~0.100 s. 
4. Once you've achieved reasonable autodetection, you can manually correct the results. If you want to delete a detected tap, just click on the red point. If you want to add a tap, just click at a point on the continuous waveform where you want the tap to be. 

### 2025 version

`onset_extraction_GUI_2025.m` was tested under MATLAB 2025a on Mac, and it should work on the more recent figure interface. 

