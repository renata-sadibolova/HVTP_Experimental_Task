function [id] = step1_counterbalancing (stringID)
%% COUNTERBALANCING
% The experimenter may be asked to enter values in prompt dialogs!
% Outputs:
% *id* variable is used to counterbalance the response message screen
% across participants.
% *dataFolder* is used to save the output to appropriate folder - the counterbalancing
% works by counting how many folders/patients were tested!

global rootFolder rmsg testmode dataFolder;

while 1
    % stringID-independent, numerical id (subj order) will be count+1 data subfolders in DAY1 folder
    if strcmp(testmode,'day1')
        % get subj id = numerical order
        countSubj = dir([rootFolder '\DATA\day1\']);
        countSubj = sum ([countSubj(~ismember({countSubj.name},{'.', '..'})).isdir]);   % count existing subfolders
        id=countSubj+1;
        % confirm new participant
        newSubj=cell2mat(inputdlg('Day 1 - new patient? (enter y or n)'));
        if strcmp(newSubj,'y')
            mkdir(rootFolder,['DATA\day1\subj' num2str(id) '__' stringID]); %new subfolder for data in Day 1
            mkdir(rootFolder,['DATA\day2\subj' num2str(id) '__' stringID]); %new subfolder for data in Day 2
            dataFolder = ([rootFolder 'DATA\day1\subj' num2str(id) '__' stringID]);
            break
        else
            testmode = 'testScript';
        end
      
    elseif strcmp(testmode,'day2')
        % find in day2 folder the string ID and the corresponding num id
        getFolders = dir([rootFolder '\DATA\day2\']);
        getFolders = getFolders(~ismember({getFolders.name},{'.', '..','desktop.ini'})); 
        
        % folders sorted by their name (e.g., subj10 precedes subj9 !!!)
        temporary = struct2table(getFolders); % convert the struct array to a table
        temporary = sortrows(temporary, 'datenum'); % sort directory content by date
        getFolders = table2struct(temporary); % folders sorted by date
        
        id=[];
        if isempty(getFolders)
            uiwait(msgbox('No Day1 data found!'));
            testmode = 'testScript';
        else
            for f = 1:length(getFolders)
                if strcmp(stringID, getFolders(f).name(strfind(getFolders(f).name,'__')+2:end))
                    id=f;
                    dataFolder = ([rootFolder 'DATA\day2\subj' num2str(id) '__' stringID]);
                end
            end
        end
        if ~isempty(id)
            break
        else
            uiwait(msgbox('No Day1 data found!'));
            testmode = 'testScript';
        end
            
    elseif strcmp(testmode,'testScript')  
        % testing day1 or day2?
        options={'day1' 'day2'};
        indx = listdlg('PromptString',{'Piloting...?';'Debugging...?';'Phantom-testing...?'},...
            'SelectionMode','single',...
            'ListString',options);
        options = options(indx);
        testmode = options{1,1};       
        id = 999; % no counterbalancing for piloting/script-testing purposes
        mkdir(rootFolder,['DATA\testingScript\subj_' stringID]);
        dataFolder = ([rootFolder 'DATA\testingScript\subj_' stringID]);
        break
    else
        % ask to re-enter whichTest choice
        options={'day1' 'day2' 'testScript'};
        indx = listdlg('PromptString','Re-enter your choice:',...
            'SelectionMode','single',...
            'ListString',options);
        options = options(indx);
        testmode = options{1,1};
    end
end

% counterbalancing
if mod(id,2) == 1
    rmsg = 'S      L';
else
    rmsg = 'L      S';
end
end