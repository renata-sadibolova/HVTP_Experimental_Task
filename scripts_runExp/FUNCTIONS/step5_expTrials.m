function [outputTest,BlockDuration] = step5_expTrials(w,stim,stringID,id)
% Runs the testing phase of the experiment

global rootFolder testmode rmsg par quitFlag; %!!! Added quitFlag
wakeUp = .02;

try
    %% load variables
    outputTest = zeros(size(par.expstimuli,1),15); %empty holder for the output data
    format short
    
    %% EXPERIMENTAL TRIALS
    %time the duration of each block (minus the break and instruction reading)
    BlockDuration = zeros(1,4);
    
    
    %% TASK INSTRUCTIONS
    if strncmp(rmsg,'S',1)
        insert='S (for short) and L (for long)';
    else
        insert='L (for long) and S (for short)';
    end
    Blockinstructions=['Testing  phase\n \n  In this phase, you will first be reminded of the short and long circle durations.  \n'...
        'The first circle will be short, the second long, the third short, the fourth long.  \n '...
        'Please make good use of these first four circles to refresh your memory for the task ahead. \n \n '...
        'After these four circles, you will see circles of varying duration appear on the screen.  \n '...
        'After each circle, the letters ' insert ' will appear on the screen. \n'...
        'Your task will be to estimate if the circle duration was closer to the previously-learned short or long interval. \n \n'...
        'Please wait until the letters appear before you respond. \n '...
        'Remember to not use counting or humming strategies. \n'...
        'Please maintain your focus on the center of the screen at all times.\n Press the RED BUTTON to begin.'];
    
    for blocks = 1:par.blocknum
        %% specifying block of trials
        blockstim = par.expstimuli(par.blocktrialstarts(blocks):par.blocktrialstarts(blocks)+par.trialnum-1+par.preBlockAnc,:);
        
        %% INSTRUCTIONS
        if strncmp(rmsg,'S',1)
            ImgInstruct = imread([rootFolder '\images\instructions\SLimg.jpg']); howBig= size(ImgInstruct);
        else
            ImgInstruct = imread([rootFolder '\images\instructions\LSimg.jpg']); howBig= size(ImgInstruct);
        end
        ImgInstruct = Screen('MakeTexture', w, ImgInstruct);
        [width, height]=Screen('WindowSize', w, []);
        Screen('DrawTexture', w, ImgInstruct,[],[width/2-howBig(2)/2 height/2+50 width/2+howBig(2)/2 height/2+50+howBig(1)]);
        Screen('TextSize', w, 27);
        Screen('TextFont', w, 'Arial');
        DrawFormattedText(w, Blockinstructions,'center', height*0.05, WhiteIndex(w));
        % flip instructions screen
        Screen('Flip',w);
        
        % % wait for response to start the block
        while KbCheck; end
        while 1
            pressed = 0;
            while pressed == 0
                [pressed,secs, kbData,deltaSecs] = KbCheck;
            end
            if kbData(par.keys.begin)==1
                break;
            end
        end
        
        %% Time the duration of experimental blocks:
        blockStarts=GetSecs();
        
        for es=1:par.trialnum+par.preBlockAnc
             if quitFlag == 1 %!!! AJ
                 break;  % !!!
             end % !!!
            %% EXPERIMENTAL STIMULI
            %% START ISI1 (blank screen)
            isi1ON.VBLstamp=Screen('Flip',w); %start ISI 1
            
            %% end of ISI1 - STIMULUS ON
            Screen('FillOval', w, par.circleRGB,stim.dim', stim.diam)
            stimsON.VBLstamp=Screen('Flip',w,isi1ON.VBLstamp + par.expstimuli(par.blocktrialstarts(blocks)+es-1,2)-wakeUp);%.005); % Result of subtract .005 is 2-3 ms ISI offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
            
            %% stimulus off - START ISI2 (blank screen)
            isi2ON.VBLstamp=Screen('Flip',w,stimsON.VBLstamp + par.expstimuli(par.blocktrialstarts(blocks)+es-1,1)-wakeUp);%.005);% Result of subtract .005 is 2-3 ms interval duration offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
            
            %% end of ISI2 - RESPONSE SCREEN ON
            Screen('TextSize', w, 42);
            DrawFormattedText(w, rmsg, 'center', 'center', WhiteIndex(w));
            
            %% monitor premature responses
            premature = 0;
            while GetSecs() < isi2ON.VBLstamp+par.isi2-.1
                [~,secs, kbData] = KbCheck;
                for i = 1:length(par.keys.Wanted)
                    if kbData(par.keys.Wanted(i)) == 1
                        premature = secs;
                        break
                    end
                end
            end
            respMsgON.VBLstamp=Screen('Flip',w,isi2ON.VBLstamp+par.isi2-wakeUp);%.025);%.005);% Result of subtract .005 is 2-3 ms interval duration offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
            
            %% RESPONSE OUTPUT
            %         KbQueueFlush % recording of key5s continues. Default flushes events returned by KbCheck only: http://psychtoolbox.org/docs/KbQueueFlush
            while KbCheck; end
            success = 0;
            while success == 0
                pressed = 0;
                while pressed == 0
                    [pressed,secs, kbData,deltaSecs] = KbCheck;
                    %Time in seconds since this KbCheck query and the most recent previous query (if any). This value is in some
                    %   sense a confidence interval, e.g., for reaction time measurements. Therefore, 'deltaSecs' tells you about the
                    %   interval in which depression of the key(s) might have happened: [secs - deltaSecs; secs]. This means that
                    %  RT's can't be more accurate than 'deltaSecs' seconds - the interval between the two most recent keyboard checks.
                end
                for i = 1:length(par.keys.Wanted)
                    if kbData(par.keys.Wanted(i)) == 1
                        success = 1;
                        keyPressed = par.keys.Wanted(i);
                        scs=secs; deltaScs=deltaSecs;
                        break;
                    end
                end
            end
            if keyPressed == par.keys.key1 && strncmp(rmsg(1),'S',1) == 1
                response = 0; %short response coded as 0
            elseif keyPressed == par.keys.key2 && strncmp(rmsg(1),'L',1) == 1
                response = 0; %short response coded as 0
            elseif keyPressed == par.keys.escapeKey %!!! Added for quit - AJ
                quitFlag = 1; %!!!
                ShowCursor; %!!!
                break; %!!!
            else
                response = 1; %long response coded as 1
            end
            
            %% save output file
            outputTest(par.blocktrialstarts(blocks)+es-1,:) = [blockstim(es,1:2), par.isi2...
                isi2ON.VBLstamp-stimsON.VBLstamp, stimsON.VBLstamp-isi1ON.VBLstamp, respMsgON.VBLstamp-isi2ON.VBLstamp...
                isi1ON.VBLstamp,  stimsON.VBLstamp, isi2ON.VBLstamp, respMsgON.VBLstamp...
                scs, deltaScs, scs-respMsgON.VBLstamp, response, premature];
           
            % saves patient's data after each trial, in day1 or day2 folder
            save([rootFolder '\DATA\' testmode '\subj' num2str(id) '__' stringID '\Backup_test.mat'], 'outputTest')
            
        end
        
        %% Time the experiment - duration of experimental blocks
        BlockDuration (blocks)= (GetSecs() - blockStarts)/60;
        
        %% !!! Added for quit key - AJ
        if quitFlag == 1 %!!! AJ
           break;  % !!!
        end % !!!
        
        %% BLOCK INSTRUCTIONS
        Blockinstructions=['\n \n \n \n Please take a moment to relax. You have ' num2str(par.blocknum-blocks) ' block(s) left.  \n \n'...
            'As before, the block will start with four reminders of the short and long circle durations  \n'...
            'The first circle will be short, the second long, the third short, the fourth long.  \n \n'...
            'When responding, please remember to wait until after the response letters have appeared.  \n \n '...
            'Please maintain your focus on the center of the screen at all times.\n Press the RED BUTTON to begin.'];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%                                                SCRIPT CRASHED:  ATTEMPT TO COMPLETE THE TESTING!
catch
    %% CONTINUE WITH THE SAME BLOCK-TRIAL STRUCTURE
    % count crashes if >1
    countCrash = 1;
    % count completed trials
    doneTrials = find(ismember(outputTest,zeros(1,size(outputTest,2)), 'rows'), 1) - 1;
    
    while size(outputTest,1) - doneTrials > 0
        try           
            %% PART 1:  unfinished block - finish remaining trials:
            if mod(doneTrials,par.trialnum+par.preBlockAnc) > 0
                % determine current block:
                blocks = ceil(doneTrials/ (par.trialnum+par.preBlockAnc));
                % make sure to record the trials of the block:
                blockstim = par.expstimuli(par.blocktrialstarts(blocks):par.blocktrialstarts(blocks)+par.trialnum-1+par.preBlockAnc,:);
                
                %% RE-START DATA COLLECTION                
                for es = mod(doneTrials,par.trialnum+par.preBlockAnc)+1 : (par.trialnum+par.preBlockAnc)
                    %% START ISI1 (blank screen)
                    isi1ON.VBLstamp=Screen('Flip',w); %start ISI 1
                    
                    %% end of ISI1 - STIMULUS ON
                    Screen('FillOval', w, par.circleRGB,stim.dim', stim.diam)
                    stimsON.VBLstamp=Screen('Flip',w,isi1ON.VBLstamp + par.expstimuli(par.blocktrialstarts(blocks)+es-1,2)-wakeUp);%.005); % Result of subtract .005 is 2-3 ms ISI offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
                    
                    %% stimulus off - START ISI2 (blank screen)
                    isi2ON.VBLstamp=Screen('Flip',w,stimsON.VBLstamp + par.expstimuli(par.blocktrialstarts(blocks)+es-1,1)-wakeUp);%.005);% Result of subtract .005 is 2-3 ms interval duration offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
                    
                    %% end of ISI2 - RESPONSE SCREEN ON
                    Screen('TextSize', w, 42);
                    DrawFormattedText(w, rmsg, 'center', 'center', WhiteIndex(w));
                    
                    %% monitor premature responses
                    premature = 0;
                    while GetSecs() < isi2ON.VBLstamp+par.isi2-.010
                        [~,secs, kbData] = KbCheck;
                        for i = 1:length(par.keys.Wanted)
                            if kbData(par.keys.Wanted(i)) == 1
                                premature = secs;
                                break
                            end
                        end
                    end
                    respMsgON.VBLstamp=Screen('Flip',w,isi2ON.VBLstamp+par.isi2-wakeUp);%.005);% Result of subtract .005 is 2-3 ms interval duration offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
                    
                    %% RESPONSE OUTPUT
                    while KbCheck; end
                    success = 0;
                    while success == 0
                        pressed = 0;
                        while pressed == 0
                            [pressed,secs, kbData,deltaSecs] = KbCheck;
                        end
                        for i = 1:length(par.keys.Wanted)
                            if kbData(par.keys.Wanted(i)) == 1
                                success = 1;
                                keyPressed = par.keys.Wanted(i);
                                scs=secs; deltaScs=deltaSecs;
                                break;
                            end
                        end
                    end
                    if keyPressed == par.keys.key1 && strncmp(rmsg(1),'S',1) == 1
                        response = 0; %short response coded as 0
                    elseif keyPressed == par.keys.key2 && strncmp(rmsg(1),'L',1) == 1
                        response = 0; %short response coded as 0
                    elseif keyPressed == par.keys.escapeKey %!!! Added for quit - AJ
                         quitFlag = 1; %!!!
                         ShowCursor; %!!!
                         break; %!!!
                    else
                        response = 1; %long response coded as 1
                    end
                    
                    %% save output file  
                    outputTest(par.blocktrialstarts(blocks)+es-1,:) = [blockstim(es,1:2), par.isi2...
                        isi2ON.VBLstamp-stimsON.VBLstamp, stimsON.VBLstamp-isi1ON.VBLstamp, respMsgON.VBLstamp-isi2ON.VBLstamp...
                        isi1ON.VBLstamp,  stimsON.VBLstamp, isi2ON.VBLstamp, respMsgON.VBLstamp...
                        scs, deltaScs, scs-respMsgON.VBLstamp, response, premature];
                    % saves patient's data after each trial, in day1 or day2 folder
                    save([rootFolder '\DATA\' testmode '\subj' num2str(id) '__' stringID '\Backup_test.mat'], 'outputTest')
                   
                end
            end
            
            
            %% PART 2:  finish remaining BLOCKS:
            doneTrials = find(ismember(outputTest,zeros(1,size(outputTest,2)), 'rows'), 1) - 1;
            blocks = doneTrials/(par.trialnum+par.preBlockAnc);
            
            if blocks < par.blocknum
                for blocks= blocks+1:par.blocknum
                    % make sure to record the trials of the block:
                    blockstim = par.expstimuli(par.blocktrialstarts(blocks):par.blocktrialstarts(blocks)+par.trialnum-1+par.preBlockAnc,:);
                    %% INSTRUCTIONS
                    if strncmp(rmsg,'S',1)
                        ImgInstruct = imread([rootFolder '\images\instructions\SLimg.jpg']); howBig= size(ImgInstruct);
                    else
                        ImgInstruct = imread([rootFolder '\images\instructions\LSimg.jpg']); howBig= size(ImgInstruct);
                    end
                    ImgInstruct = Screen('MakeTexture', w, ImgInstruct);
                    [width, height]=Screen('WindowSize', w, []);
                    Screen('DrawTexture', w, ImgInstruct,[],[width/2-howBig(2)/2 height/2+50 width/2+howBig(2)/2 height/2+50+howBig(1)]);
                    Screen('TextSize', w, 27);
                    Screen('TextFont', w, 'Arial');
                    DrawFormattedText(w, Blockinstructions,'center', height*0.05, WhiteIndex(w));
                    % flip instructions screen
                    Screen('Flip',w);
                    
                    % % wait for response to start the block
                    while KbCheck; end
                    while 1
                        pressed = 0;
                        while pressed == 0
                            [pressed,secs, kbData,deltaSecs] = KbCheck;
                        end
                        if kbData(par.keys.begin)==1
                            break;
                        end
                    end
                    
                    %% Time the duration of experimental blocks:
                    blockStarts=GetSecs();
                    
                    for es=1:par.trialnum+par.preBlockAnc
                        %% EXPERIMENTAL STIMULI
                        %% START ISI1 (blank screen)
                        isi1ON.VBLstamp=Screen('Flip',w); %start ISI 1
                        
                        %% end of ISI1 - STIMULUS ON
                        Screen('FillOval', w, par.circleRGB,stim.dim', stim.diam)
                        stimsON.VBLstamp=Screen('Flip',w,isi1ON.VBLstamp + par.expstimuli(par.blocktrialstarts(blocks)+es-1,2)-wakeUp);%.005); % Result of subtract .005 is 2-3 ms ISI offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
                        
                        %% stimulus off - START ISI2 (blank screen)
                        isi2ON.VBLstamp=Screen('Flip',w,stimsON.VBLstamp + par.expstimuli(par.blocktrialstarts(blocks)+es-1,1)-wakeUp);%.005);% Result of subtract .005 is 2-3 ms interval duration offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
                        
                        %% end of ISI2 - RESPONSE SCREEN ON
                        Screen('TextSize', w, 42);
                        DrawFormattedText(w, rmsg, 'center', 'center', WhiteIndex(w));
                        
                        %% monitor premature responses
                        premature = 0;
                        while GetSecs() < isi2ON.VBLstamp+par.isi2-.010
                            [~,secs, kbData] = KbCheck;
                            for i = 1:length(par.keys.Wanted)
                                if kbData(par.keys.Wanted(i)) == 1
                                    premature = secs;
                                    break
                                end
                            end
                        end
                        respMsgON.VBLstamp=Screen('Flip',w,isi2ON.VBLstamp+par.isi2-wakeUp);%.005);% Result of subtract .005 is 2-3 ms interval duration offset. Without it flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
                        
                        %% RESPONSE OUTPUT
                        %         KbQueueFlush % recording of key5s continues. Default flushes events returned by KbCheck only: http://psychtoolbox.org/docs/KbQueueFlush
                        while KbCheck; end
                        success = 0;
                        while success == 0
                            pressed = 0;
                            while pressed == 0
                                [pressed,secs, kbData,deltaSecs] = KbCheck;
                                %Time in seconds since this KbCheck query and the most recent previous query (if any). This value is in some
                                %   sense a confidence interval, e.g., for reaction time measurements. Therefore, 'deltaSecs' tells you about the
                                %   interval in which depression of the key(s) might have happened: [secs - deltaSecs; secs]. This means that
                                %  RT's can't be more accurate than 'deltaSecs' seconds - the interval between the two most recent keyboard checks.
                            end
                            for i = 1:length(par.keys.Wanted)
                                if kbData(par.keys.Wanted(i)) == 1
                                    success = 1;
                                    keyPressed = par.keys.Wanted(i);
                                    scs=secs; deltaScs=deltaSecs;
                                    break;
                                end
                            end
                        end
                        if keyPressed == par.keys.key1 && strncmp(rmsg(1),'S',1) == 1
                            response = 0; %short response coded as 0
                        elseif keyPressed == par.keys.key2 && strncmp(rmsg(1),'L',1) == 1
                            response = 0; %short response coded as 0
                        elseif keyPressed == par.keys.escapeKey %!!! Added for quit - AJ
                            quitFlag = 1; %!!!
                            ShowCursor; %!!!
                            break; %!!!
                        else
                            response = 1; %long response coded as 1
                        end
                        
                        %% save output file
                        outputTest(par.blocktrialstarts(blocks)+es-1,:) = [blockstim(es,1:2), par.isi2...
                            isi2ON.VBLstamp-stimsON.VBLstamp, stimsON.VBLstamp-isi1ON.VBLstamp, respMsgON.VBLstamp-isi2ON.VBLstamp...
                            isi1ON.VBLstamp,  stimsON.VBLstamp, isi2ON.VBLstamp, respMsgON.VBLstamp...
                            scs, deltaScs, scs-respMsgON.VBLstamp, response, premature];
                        % saves patient's data after each trial, in day1 or day2 folder
                        save([rootFolder '\DATA\' testmode '\subj' num2str(id) '__' stringID '\Backup_test.mat'], 'outputTest')
                    end
                    
                    %% Time the experiment - duration of experimental blocks
                    BlockDuration (blocks)= (GetSecs() - blockStarts)/60;
                    
                    %% !!! Added for quit key - AJ
                    if quitFlag == 1 %!!! AJ
                        break;  % !!!
                    end % !!!
        
                    %% BLOCK INSTRUCTIONS
                    Blockinstructions=['\n \n \n \n Please take a moment to relax. You have ' num2str(par.blocknum-blocks) ' block(s) left.  \n \n'...
                        'As before, the block will start with four reminders of the short and long circle durations  \n'...
                        'The first circle will be short, the second long, the third short, the fourth long.  \n \n'...
                        'When responding, please remember to wait until after the response letters have appeared.  \n \n '...
                        'Please maintain your focus on the center of the screen at all times.\n Press the RED BUTTON to begin.'];
                end
            end
        
            % number of completed trials:
            doneTrials = find(ismember(outputTest,zeros(1,size(outputTest,2)), 'rows'), 1) - 1;

        catch
            %% re-start Psychtoolbox and try to continue...
            Screen('CloseAll');
            countCrash=countCrash+1;
            uiwait(msgbox ('SCRIPT HAS CRASHED. PRESS OK AND FINISH THE EXPERIMENT. PLEASE INVESTIGATE AFTER THE EXPERIMENT', ['Crash number: ' num2str(countCrash)], 'error','modal'));  
            Screen('Preference', 'VBLTimestampingMode', 4); %this helps on windows machines; cf. help BeampositionQueries
            Screen('Preference', 'SkipSyncTests', 1); %0); !!! Changed this to match DA_Timerunexp1.m - AJ
            screens=Screen('Screens');
            screenNumber=max(screens);
            black=BlackIndex(screenNumber);
            [w, ~]=Screen('OpenWindow',screenNumber, black);
            % Hide the mouse cursor:
            HideCursor;
            
            % number of completed trials:
            doneTrials = find(ismember(outputTest,zeros(1,size(outputTest,2)), 'rows'), 1) - 1;
        end
    end
end
end