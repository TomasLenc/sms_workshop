# Tap Onset Extraction GUI

This GUI can be used to detect **tap onset times** (i.e., the moments when a finger makes contact with the tapping surface) from continuous recordings acquired with the tapping box. The hardware setup is explained in class; see the lecture slides for details.

The GUI is intentionally kept very simple so that it can be easily **inspected, understood, and adapted** to specific use cases. Feel free to modify it and build on it for your own projects.

Two versions of the GUI are provided.

## 2018 Version

`onset_extraction_GUI_2018.m` was tested under **MATLAB 2018a** on macOS.

Due to changes in MATLAB's figure interaction framework introduced in later releases, this version may not work correctly in more recent MATLAB versions. If you experience issues, use the 2025 version described below.

### Quick Start

1. Open MATLAB and change the working directory to the folder containing `onset_extraction_GUI_2018.m`.

2. Run `onset_extraction_GUI_2018.m`.

3. The GUI will load the continuous tapping signal and check whether tap onset times have already been detected. If no onset file is found, the GUI will automatically perform onset detection.

4. Adjust the **Amplitude threshold** and click **autodetect** to re-run the detection algorithm. The **Minimum ITI** parameter is usually less critical; a value around **0.080 s** generally works well.

5. Once the automatic detection looks reasonable, you can manually correct the results:
   - Select the **Data Cursor** tool in the figure toolbar.
   - To **delete** a detected tap, click on the corresponding red marker.
   - To **add** a tap, click on the waveform at the desired onset location.

## 2025 Version

`onset_extraction_GUI_2025.m` was tested under **MATLAB 2025a** on macOS and is compatible with MATLAB's newer figure interface.

The workflow is largely identical to the 2018 version. The main difference concerns manual editing:

- To **add** or **remove** tap onsets, make sure that **no interactive tool is active** in the figure toolbar (i.e. you should **not** be in **Zoom**, **Pan**, or **Data Tips** mode).  
- Once all tools are deselected, clicking on the waveform adds a tap onset and clicking on a red marker removes it.

In short, the figure must be in its default interaction mode before manual editing is possible.