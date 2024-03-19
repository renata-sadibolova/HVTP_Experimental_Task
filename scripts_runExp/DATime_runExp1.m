function DATime_runExp1(stringID,whichTest)
%% INPUT: must be entered in apostrophes
% ID: enter string ID, e.g.    'subj9X1Y'
% whichTest: enter   'day1' or   'day2' or   'testScript'
% check string input variables
if isnumeric(stringID)
    stringID = num2str(stringID);
end

global rootFolder testmode dataFolder;
testmode=whichTest; clear whichTest

%% SELECT DIRECTORY
rootFolder = 'D:\OneDrive - King''s College London\_KCL_DRIVE_FOLDERS\DOPAMINE STUDIES\DOP_STUDY1\scripts_runExp\';
cd (rootFolder);


%% TIME PERCEPTION EXPERIMENT
% The programme runs a visual variant of the temporal bisection task. Circles
% appear on the screen, one at the time, for specified time intervals.
% Participants learn two intervals (short and long) in the TRAINING PHASE.
% They then judge if various different intervals 0in the TESTING PHASE
% are closer to the learnt short or long interval. The programme will record
% the key 5 presses.
%
% The programme uses a pre-defined folder structre.
% Please change the rootFolder to this function's path.
% Five helper functions are used to run the experiment.
% - They are saved in 'FUNCTIONS' folder.
%
% 1. Please ensure the timing offset of the circle stimuli is <2 ms. Check
%   this in the data - please run the study and compare the 'programmed'
%   intervals with the 'real' intervals on your machine. Open the output
%   data file and subtract column 4 (real) from column 1 (programmed):
%
%   plot(day2.outputTest(:,1) - day2.outputTest(:,4))%
%   If large offset - type in the command window 'help BeampositionQueries'
%
% 2. Please ensure that the stimulus size is 2-4 degrees of the visual field
%   (keep the constant screen distance from a participant).
%
% 3. The '0' and '.' keyboard keys correspond with the left and right
%   joystick shoulder buttons. The spacebar = red joystick button.
%
% 4. programme will stop and give warning if >1monitors are used. This is because
%   of the Psychtoolbox reduced stimulus timing accuracy for multiple monitors.

% Written and tested by Renata Sadibolova, January 2019.
% The programme was tested on Windows 2007 (desktop) and 2010 (laptop) machines,
% using the latest Psychtoolbox version (http://psychtoolbox.org/download).
% Monitor refresher rate 60 Hz.


%% TIME THE EXPERIMENT
expDuration = GetSecs();

%% ADD TO PATH
addpath([rootFolder '\FUNCTIONS\']);


%% STEP 1: COUNTERBALANCING - call function
[id] = step1_counterbalancing (stringID);


%% STEP 2: DEFINE PARAMETERS - call function
step2_defineParam;

%% OPEN WINDOW
Screen('Preference', 'VBLTimestampingMode', 4); %this helps on windows machines; cf. help BeampositionQueries
Screen('Preference', 'SkipSyncTests', 2555);
screens=Screen('Screens');
screenNumber=max(screens);
% unreliable stim presentation timing with >1 screen. Stop with warning if >1 screen.
% if screenNumber > 0
%     clc; disp ('Stimulus timing accuracy is unreliable with multiple monitors')
%     disp ('Use a single monitor for <2ms timing offset.')
%     disp ('Please unplug the extra monitor and restart Matlab.')
%     keyboard
% end
black=BlackIndex(screenNumber);
[w, ~]=Screen('OpenWindow',screenNumber, black);
[width, height]=Screen('WindowSize', w, []);
% Hide the mouse cursor:
HideCursor;
% inter-flip interval
ifi = Screen('GetFlipInterval', w);
% don't continue if ifi is too high
if ifi>.02
    disp(num2str(ifi))
    disp('timing error')
    sca
    keyboard % get to the debugger mode
end

%% circle stimulus parameters
% circle size should be 2-4 degrees of VF
stim.dim=[width/2-50 height/2-50 width/2+50 height/2+50];
stim.diam=stim.dim(3)-stim.dim(1);              


%% STEP 3: START KEY-5 RECORDING  - call function
if strcmp(testmode,'day2')
    step3_key5strokes('start') %starts the Kbqueue, records 5 presses throughout the training and testing phase
    recordKEY5 = step3_key5strokes('nEvents'); %variable containing times for all key 5 strokes (nothing else)
    
    WaitSecs(5)
    while 1
        if exist('recordKEY5','var')
           break
        end
    end
end

%% STEP 4: TRAINING - call function
outputTrain = step4_trainTrials(w,stim);

%% STEP 5:  EXPERIMENTAL TASK - call function
[outputTest,BlockDuration] = step5_expTrials(w,stim);

%% STOP KEY-5 RECORDING  - call function
if strcmp(testmode,'day2')
    recordKEY5 = step3_key5strokes('nEvents'); %variable containing times for all key 5 strokes (nothing else)
    step3_key5strokes('flush') %http://psychtoolbox.org/docs/KbQueueFlush
    step3_key5strokes('stop')
end

%% CLOSE WINDOW
sca

%% DATA SAVING
try
    if strcmp(testmode,'day2')
        finalData.key5s = recordKEY5;
    end
    finalData.outputTrain = outputTrain;
    finalData.outputTest = outputTest;
    finalData.id = id;
    finalData.blockDurations = BlockDuration;
    finalData.expDuration = (GetSecs() - expDuration)/60;
    disp(' '); disp(' '); disp(['Experiment lasted  ' num2str(finalData.expDuration) ' minutes']);
    
    % TIME & DATE STAMP (for output file)
    timeday_stamp=datestr(clock);
    clockStamp = regexprep(timeday_stamp,'[-:]','');
    clockStamp = regexprep(clockStamp,'[ ]','_');
    clockStamp = clockStamp(1:end-2);
    
    save ([dataFolder '\s' num2str(id) '_' clockStamp '.mat'],'finalData');
catch
    keyboard
    % OR:
    % this automatically saves the content of the workspace to the Current folder:
%     save data2sortout
end
end
