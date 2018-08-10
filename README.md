# TBV 

[![DOI](https://zenodo.org/badge/70529141.svg)](https://zenodo.org/badge/latestdoi/70529141)

Temporal binding in vision experiment

### Background

Coming soon

### To run experiment
From MATLAB, make sure you are in the TBV folder

``` cd ~/path/to/TBV/ ```

Run using the following command (the number is the participant id

``` tbv(001, 't1') ``` 

the ``` 't1' ``` indicates that the program will start off with the shortened version, for initial training on the task.

replace ``` 't1' ``` with ``` 'fmri1' ``` or ``` 'fmri2' ``` to run the fmri portions of the experiment. The fmri portions of the experiment will use the ending stimulus levels from the previous trials as their starting points. So fmri1 will use the information from the t1 phase, and fmri2 will use the information from the fmri1 phase. 

### Experiment Procedure

1) Participants are shown a flicker screen alternating between greed and red. Use the 2 and 3 keys on the keyboard to adjust the luminances to match. Once they are close to matching the flicker will become less noticeable. Try to get the screen to the point where it flickers the least. This may vary among participants. Press the 4 key on the keyboard to save the value once the flicker has been minimized. Next, repeat these steps on the gray and red flicker screen. Press the 4 key to save these settings as well.

2) An instruction screen will appear which expains the task to participants. Press the 2 key to move on from the first screen, and the 3 key to move on from the second screen. Finally, to start the experiment you must clikc the mouse on the final screen.  





