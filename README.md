# HVTP_Experimental_Task
Preprint: https://www.medrxiv.org/content/10.1101/2024.02.09.24302276v1

#
# Folder content
1. Main Experimental Script that calls on helper functions

2. Five Helper Functions: 
     - Counterbalancing
     - Define Parameters
     - Key 5/FscvV pulses
     - Training phase
     - Experimental phase

3. Images Called by Script

4. Detailed Instructions (.docx file)


# Overview

The programme runs a visual variant of the temporal bisection task. Circles
appear on the screen, one at the time, for specified time intervals.
Participants learn two intervals (short and long) in the TRAINING PHASE.
They then judge if various different intervals 0in the TESTING PHASE
are closer to the learnt short or long interval. 

The programme uses a pre-defined folder structre.
Please change the rootFolder path to the main script location.

1. Please ensure the timing offset of the circle stimuli is <2 ms. Check
this in the data - please run the study and compare the 'programmed'
intervals with the 'real' intervals on your machine. Open the output
data file and subtract column 4 (real) from column 1 (programmed):
plot(day2.outputTest(:,1) - day2.outputTest(:,4))
if large offset - type in the command window 'help BeampositionQueries'

2. Please ensure that the stimulus size is 2-4 degrees of the visual field
(keep the constant screen distance from a participant).

3. The '0' and '.' keyboard keys correspond with the left and right
joystick shoulder buttons. The spacebar = red joystick button.


Written and tested by Renata Sadibolova, January 2019.
The programme was tested on Windows 2007 and 2010 machines,
using the latest Psychtoolbox version (http://psychtoolbox.org/download).
Monitor refresher rate 60 Hz.
