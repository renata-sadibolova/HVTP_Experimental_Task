function varargout = step3_key5strokes(cmd, param)
% Records key5 strokes (voltammogram pulses) in the background
% The function is called to first initiate and later to stop the recording
% (this is specified by 'param' input)


%% call variables
persistent kCode started evts
global KbQueueDevice; % allow to change in user code
if isempty(started), started = false; end
if nargin<1 || isempty(cmd), cmd = 'start'; end
if any(cmd=='?'), subFuncHelp('KbQueue', cmd); return; end

%% start
if strcmpi(cmd, 'start')
    if started, BufferEvents; end
    if nargin<2
        param = {'5' '5%'};
    end
    KbName('UnifyKeyNames');
    if ischar(param) || iscellstr(param) % key names
        kCode = zeros(256, 1);
        kCode(KbName(param)) = 1;
    elseif length(param)==256 % full keycode
        kCode = param;
    else
        kCode = zeros(256, 1);
        kCode(param) = 1;        
    end
    if isempty(KbQueueDevice), KbQueueDevice = responseDevice; end
    try KbQueueReserve(2, 1, KbQueueDevice); end %#ok
    KbQueueCreate(KbQueueDevice, kCode,0,500000);
    KbQueueStart(KbQueueDevice);
    started = true;
    return;
end

if ~started, KbQueue('start'); end

%% nEvents
if strcmpi(cmd, 'nEvents')
    BufferEvents;
    n = length(evts);
    if n
        nPress = sum([evts.Pressed] == 1);
        kTime= evts([evts.Pressed]==1);
        kTime=  [kTime.Time]';
    else
        nPress = 0;
    end
    if nargin<2, param = 'press'; end
    if strncmpi(param, 'press', 5)
        varargout{1} = kTime;
    elseif strncmpi(param, 'release', 7)
        varargout{1} = n - nPress;
    else
        varargout{1} = n;
    end
    
    %% check 
elseif strcmpi(cmd, 'check')
    [down, p1, r1, p2, r2] = KbQueueCheck(KbQueueDevice);
    if ~down 
        varargout = repmat({[]}, 1, nargout);
        return;
    end
    if nargin<2, param = 0; end
    i1 = find(p1); i2 = find(p2);
    varargout{1} = [i1 i2; [p1(i1) p2(i2)]-param];
    if nargout>1
        i1 = find(r1); i2 = find(r2);
        varargout{2} = [i1 i2; [r1(i1) r2(i2)]-param];
    end
    %% wait
elseif strcmpi(cmd, 'wait')
    endSecs = GetSecs;
    secs = inf; % wait forever unless secs provided
    newCode = kCode; % use old keys unless new keys provided
    if nargin>1 % new keys or secs provided
        if isempty(param), param = inf; end
        if isnumeric(param) % input is secs
            secs = param;
        else % input is keys
            newCode = zeros(256, 1);
            newCode(param) = 1;
        end
    end
    esc = KbName('Escape');
    escExit = ~newCode(esc);
    newCode(esc) = 1;
    changed = any(newCode~=kCode);
    if changed % change it so we detect new keys
        BufferEvents;
        KbQueueCreate(KbQueueDevice, newCode);
        KbQueueStart(KbQueueDevice); % Create and Start are twins here :)
    else
        KbQueueFlush(KbQueueDevice, 1); % flush KbQueueCheck buffer
    end
    endSecs = endSecs+secs;
    while 1
        [down, p1] = KbQueueCheck(KbQueueDevice);
        if down || GetSecs>endSecs, break; end
        WaitSecs('YieldSecs', 0.005);
    end
    if changed % restore original keys if it is changed
        BufferEvents;
        KbQueueCreate(KbQueueDevice, kCode);
        KbQueueStart(KbQueueDevice);
    end
    if isempty(p1)
        varargout = repmat({[]}, 1, nargout);
        return;
    end
    ind = find(p1);
    if escExit && any(ind==esc)
        error('User pressed ESC. Exiting ...'); 
    end
    varargout = {p1(ind) ind};
    
    %% flush
elseif strcmpi(cmd, 'flush')
    KbQueueFlush(KbQueueDevice, 3); % flush both buffers
    evts = [];
    
    %% until
elseif strcmpi(cmd, 'until')
    if nargin<2 || isempty(param), param = 0; end
    while 1
        [down, t, kc] = KbCheck(-1);
        if down && kc(KbName('Escape'))
            error('User pressed ESC. Exiting ...'); 
        end
        if t>=param, break; end
        WaitSecs('YieldSecs', 0.005);
    end
    if nargout, varargout = {t}; end
    
    %% stop
elseif strcmpi(cmd, 'stop')
    KbQueueStop(KbQueueDevice);
    started = false;
    if nargout
        BufferEvents;
        if isempty(evts)
            varargout = repmat({[]}, 1, nargout);
            return;
        end

        isPress = [evts.Pressed] == 1;
        if nargin<2, param = 0; end
        varargout{1} = [[evts(isPress).Keycode] 
                        [evts(isPress).Time]-param];
        if nargout>1
            varargout{2} = [[evts(~isPress).Keycode] 
                            [evts(~isPress).Time]-param];
        end
    end
    KbQueueRelease(KbQueueDevice);
else 
    error('Unknown command: %s.', cmd);
end

    function BufferEvents % buffer events so we don't lose them
        n = KbEventAvail(KbQueueDevice);
        if n<1, return; end
        for ic = 1:n
            foo(ic) = KbEventGet(KbQueueDevice); %#ok
        end
        if isempty(evts), evts = foo;
        else
            evts = [evts foo];
        end
    end

end

function idx = responseDevice
    if IsWin, idx = []; return; end % all keyboards

    clear PsychHID; % refresh
    [ind, pName] = GetKeyboardIndices;
    if IsOSX
        idx = ind(1); % based on limited computers
    else % Linux
        for i = length(ind):-1:1
            if ~isempty(strfind(pName{i}, 'HIDKeys')) || ...
                ~isempty(strfind(pName{i}, 'fORP')) % faked, need to update
                idx = ind(i);
                return;
            end
            idx = ind(end); % based on limited computers
        end
    end
end



