function [outputTrain] = step4_trainTrials (w,stim)
% Runs training phase of the experiment

global rootFolder rmsg par
wakeUp = .01;

%% output
outputTrain= zeros(size(par.ancTrain,1),15); %empty holder for the output data
format short

%% TASK INSTRUCTIONS
if strncmp(rmsg,'S',1)
    insert='S (for short) and L (for long)';
else
    insert='L (for long) and S (for short)';
end
task_instructions=['Training phase \n Your task later in the experiment will be to judge a variety of different time intervals  \n'...
    'with reference to a short and a long interval that you will now learn. \n \n'...
    'You will soon see circles appearing on the screen for one of two durations. \n'...
    'The first circle will be short and the second will be long. \n '...
    'Afterwards, these two circle durations will be presented in a mixed order. \n \n'...
    'After each circle, the letters ' insert ' will appear. \n'...
    'Your task will be to judge the duration of each circle by pressing the controller button \n'...
    'that corresponds to the location of the response letter on the screen (see image below) \n \n'...
    'Please do not respond before the letters appear on the screen!\n \n'...
    'Counting or humming is known to impair performance. Please refrain from using these strategies.\n'...
    'Please maintain your focus on the center of the screen throughout the task.  \n Press the RED BUTTON to begin the training.'];

%% PRESENT PRE-ANCHOR INSTRUCTIONS
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
DrawFormattedText(w, task_instructions,'center', height*0.05, WhiteIndex(w));
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


%% ANCHOR TRAINING
% success of training performance (only for day 1)
if par.expstimuli<201 % day 1 has fewer = 200 trials
    training_success = 0;
    while training_success == 0
        
        for as=1:par.anchornum
            %% START ISI1 (blank screen)
            isi1ON.VBLstamp=Screen('Flip',w); %start ISI 1
            
            %% end of ISI1 - STIMULUS ON
            Screen('FillOval', w, par.circleRGB,stim.dim', stim.diam)
            stimsON.VBLstamp=Screen('Flip',w,isi1ON.VBLstamp + par.ancTrain(as,2)-wakeUp); % Without the wakeup, flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
            
            %% stimulus off - START ISI2 (blank screen)
            isi2ON.VBLstamp=Screen('Flip',w,stimsON.VBLstamp + par.ancTrain(as,1)-wakeUp); % Without the wakeup, flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
            
            %% end of ISI2 - RESPONSE SCREEN ON
            Screen('TextSize', w, 42); % prep the response screen
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
            respMsgON.VBLstamp=Screen('Flip',w,isi2ON.VBLstamp+par.isi2-wakeUp); % Without the wakeup, flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
            
            %% RESPONSE OUTPUT
            %     KbQueueFlush % recording of key5s continues. Default flushes events returned by KbCheck only: http://psychtoolbox.org/docs/KbQueueFlush
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
            else
                response = 1; %long response coded as 1
            end
            
            %% saving data
            outputTrain(as,:) = [par.ancTrain(as,1:2), par.isi2...
                isi2ON.VBLstamp-stimsON.VBLstamp, stimsON.VBLstamp-isi1ON.VBLstamp, respMsgON.VBLstamp-isi2ON.VBLstamp...
                isi1ON.VBLstamp,  stimsON.VBLstamp, isi2ON.VBLstamp, respMsgON.VBLstamp...
                scs, deltaScs, scs-respMsgON.VBLstamp, response premature];
        end
        
        indx = outputTrain(:,1)==outputTrain(1,1);
        % pass training if the proportion of correct is 75% plus
        correctResp = sum(outputTrain(indx,14)==0) + sum(outputTrain(~indx,14)==1);
        if correctResp / size(outputTrain,1) >.74 % if 15 or more of total 20 correct
            training_success = 1;
        else
            training_success = 0;
            % screen announcing more training trials
            instr = 'It looks like you may need more time to practise. The training phase will repeat once more. \n \n';
            Screen('DrawTexture', w, ImgInstruct,[],[width/2-howBig(2)/2 height/2+50 width/2+howBig(2)/2 height/2+50+howBig(1)]);
            Screen('TextSize', w, 27);
            Screen('TextFont', w, 'Arial');
            DrawFormattedText(w, [instr task_instructions],'center', height*0.05, WhiteIndex(w));
            Screen('Flip',w);
            % wait for response
            % % wait for response to start the block
            while KbCheck; end
            while 1
                pressed = 0;
                while pressed == 0
                    [pressed,~, kbData,~] = KbCheck;
                end
                if kbData(par.keys.begin)==1
                    break;
                end
            end
        end
    end
else
    for as=1:par.anchornum
        %% START ISI1 (blank screen)
        isi1ON.VBLstamp=Screen('Flip',w); %start ISI 1
        
        %% end of ISI1 - STIMULUS ON
        Screen('FillOval', w, par.circleRGB,stim.dim', stim.diam)
        stimsON.VBLstamp=Screen('Flip',w,isi1ON.VBLstamp + par.ancTrain(as,2)-wakeUp); % Without the wakeup, flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
        
        %% stimulus off - START ISI2 (blank screen)
        isi2ON.VBLstamp=Screen('Flip',w,stimsON.VBLstamp + par.ancTrain(as,1)-wakeUp); % Without the wakeup, flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
        
        %% end of ISI2 - RESPONSE SCREEN ON
        Screen('TextSize', w, 42); % prep the response screen
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
        respMsgON.VBLstamp=Screen('Flip',w,isi2ON.VBLstamp+par.isi2-wakeUp); % Without the wakeup, flip misses VBL and waits for ~15 milliseconds (with 60 Hz monitor refresher rate));
        
        %% RESPONSE OUTPUT
        %     KbQueueFlush % recording of key5s continues. Default flushes events returned by KbCheck only: http://psychtoolbox.org/docs/KbQueueFlush
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
        else
            response = 1; %long response coded as 1
        end
        
        %% saving data
        outputTrain(as,:) = [par.ancTrain(as,1:2), par.isi2...
            isi2ON.VBLstamp-stimsON.VBLstamp, stimsON.VBLstamp-isi1ON.VBLstamp, respMsgON.VBLstamp-isi2ON.VBLstamp...
            isi1ON.VBLstamp,  stimsON.VBLstamp, isi2ON.VBLstamp, respMsgON.VBLstamp...
            scs, deltaScs, scs-respMsgON.VBLstamp, response premature];
    end
end