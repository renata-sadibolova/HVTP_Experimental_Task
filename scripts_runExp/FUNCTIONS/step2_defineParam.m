function step2_defineParam
%% define experimental variables
% Defines the number of blocks and trials in the Training and Testing phase
% Defines the stimulus intervals, ISIs,  and response keys
global par testmode;

%% KEYBOARD
KbName('UnifyKeyNames')
par.keys.begin=KbName('space');
par.keys.Wanted=[KbName('0') KbName('.')];
par.keys.key1 = KbName('0'); par.keys.key2 = KbName('.');


%% TRIAL ISIs
% isi 1
isi_all = (.400:1/60:.600)';
lambdahat = poissfit(1:length(isi_all));
% isi 2
par.isi2=.900;   %fixed post-stimulus empty screen duration before the response letters appear

%% STIMULI
% circle colour
par.circleRGB=[255 255 255];

% intervals
intervals=[
    .500;
    .650;
    .750;
    .850;
    .950;
    1.100];

% split into anchors and mid-intervals
indx = intervals(:,1)==intervals(1,1) | intervals(:,1)==intervals(length(intervals),1) ;
anc=intervals(indx,:); % the shortest and longest intervals are the anchors (easy trials)
mid=intervals(~indx,:);

%% TRAINING PHASE TRIALS
par.anchornum=20; % TRAINING phase trials: half short, half long 

% ISI 1 (jitter)
jitter = poissrnd(lambdahat,par.anchornum,1);
%truncate the Poisson distribution
jitter(jitter>length(isi_all))=length(isi_all);
jitter(jitter<1)=1;

% RANDOMISE ANCHORS
par.ancTrain=sortrows(repmat(anc,par.anchornum/2,1));
par.ancTrain(:,2) = isi_all(jitter,1);
par.ancTrain = par.ancTrain([1 length(par.ancTrain) 2:length(par.ancTrain)-1],:);
par.ancTrain = par.ancTrain([1 2 randperm(size(par.ancTrain,1)-2)+2],:);


%% TESTING PHASE TRIALS
par.preBlockAnc=4;     % each block starts with 4 anchors (2 short, 2 long) 
par.inBlockAnc=6;       % each block contains additional 6 anchors (3 short, 3 long), shuffled in
par.trialnum=46;        % trials in block, EXCLUDING the preBlockAnchor trials in which the duration is explicitly told
if strcmp('day1',testmode)    
    mid_repeat= 40; % repetitions for each mid-interval
    par.blocknum=4;         % number of blocks (Ken recommends 2-3 min for each)
else    
    mid_repeat= 60; % repetitions for each mid-interval
    par.blocknum=6;         % number of blocks (Ken recommends 2-3 min for each)
end

%% Four anchors starting each block
howMany = par.blocknum*par.preBlockAnc;

% ISI 1 (jitter)
jitter = poissrnd(lambdahat,howMany,1);
%truncate the Poisson distribution
jitter(jitter>length(isi_all))=length(isi_all);
jitter(jitter<1)=1;

ancstart=repmat(anc,howMany/2,1);
ancstart(:,2) = isi_all(jitter,1); % anchors to append at the start of each block

%% Remaining trials

% anchors to shuffle in the blocks
howMany = par.blocknum*par.inBlockAnc;
jitter = poissrnd(lambdahat,howMany,1);
%truncate the Poisson distribution
jitter(jitter>length(isi_all))=length(isi_all);
jitter(jitter<1)=1;
ancblock=repmat(anc,howMany/2,1);
ancblock(:,2) = isi_all(jitter,1);%in-block anchors to shuffle in

% mid-interval trials 
mid=sortrows(repmat(mid,mid_repeat,1));
jitter = poissrnd(lambdahat,length(mid),1);
%truncate the Poisson distribution
jitter(jitter>length(isi_all))=length(isi_all);
jitter(jitter<1)=1;
mid(:,2) = isi_all(jitter,1);%remaining trials in all blocks
mid = mid(randperm(length(mid)),:);

par.expstimuli=[];
for count=1:par.blocknum                                          
    % select 2 short and long anchor pairs - append to the start
    ancFirst=ancstart (1:par.preBlockAnc,:);
    ancstart=ancstart(par.preBlockAnc+1:end,:);
    
    % select 3 short and long anchor pairs - shuffle in with other block trials
    ancIn=ancblock (1:par.inBlockAnc,:);
    ancblock=ancblock(par.inBlockAnc+1:end,:);
    
    % select block's mid-intervals
    selectStim = mid(1:par.trialnum-par.inBlockAnc,:);                                          
    mid = mid (par.trialnum-par.inBlockAnc+1:end,:);
    
    % shuffle in the 'in-block' anchors
    mix= [[ancIn; selectStim] shuffle(1:par.trialnum)'];
    mix=sortrows(mix,3);
    
    % append the 'start-block' anchors
    newBlock=[ancFirst; mix(:,1:2)];
    
    %merge blocks together                                       
    par.expstimuli(length(par.expstimuli)+1 : length(par.expstimuli)+length(newBlock),:) = newBlock (:,1:2);    
end


%% BLOCK START POINTS
par.blocktrialstarts=1:par.trialnum+4:size(par.expstimuli,1);sca
end

