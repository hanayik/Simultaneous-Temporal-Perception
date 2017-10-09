function CatchError = tbv4(sub,runtype)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              Scan order: t1, fmri1, fmri2
%
% the t1 will last ~6min and will present each task,
% simulaneity, orientation, and color, so that the participant can
% titrate down to at or near their threshold using our PEST algorithms.
%
% Trial timing:
% 
% stim duration:        500 ms
% response time:        1100 ms
% max trial time:       1800 ms (about 200 ms ISI built into trial, will catch lag)
% 
% num. blocks T1:       3 (for initial adaptation to task)
% num. trials T1:       40
%
% task text/block:      1000 ms * 18
% num. blocks fMRI-1:   18 (6 blocks x 3 tasks)
% num. blocks fMRI-2:   18 (6 blocks x 3 tasks)
% num. trials/block:    16 (can't do less than 16 for property balancing reasons)
% task block duration:  28.8 s (1.8 * 16)
% rest between blocks:  15 s (900 frames @ 60 Hz)
% num. rest blocks:     num. fMRI blocks + 1 (start with rest)
% fMRI run duration:    ((18*28.8)+(19*15)+18)/60 = 13.69 min (13 min, 41.4 sec)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CatchError = 0; %for error handling, default to "0" exit code
KbName('UnifyKeyNames');

if IsOSX
    Screen('Preference', 'SkipSyncTests', 2);
else
    Screen('Preference', 'SkipSyncTests', 0);
end
if ~isnumeric(sub) %make sure sub and runnum are numbers and not strings
    error('The given SUBJECT value is not a number, please provide an integer number!');
end
[datapth] = fileparts(mfilename('fullpath')); %get path of this mfile
datadir = fullfile(datapth,'data'); %construct data'dir' path
if ~exist(datadir,'dir'); mkdir(datadir); end; %make data directory if it's not there
subjectString = sprintf('%03d',sub);
subdir = fullfile(datadir,['sub_' subjectString]);
if ~exist(subdir,'dir'); mkdir(subdir); end;
subFile = fullfile(subdir,['sub_' subjectString '_' runtype '.mat']);


try %Use try catch loops for elegant error handling with PTB
    %trial event times = stim[501ms] + resp[1100ms] + iti[199ms]
    %s.nRestFrames = 900-1; % THIS IS FOR RUNNING SUBJECTS
    s.nRestFrames = 300-1; %for testing on myself
    s.respTimeOut = 1.1;
    s.maxTrialSecs = 1.8;
    s.trimTime = 0;
    s.redColor = [.8 0 0];
    s.grnColor = [0 .8 0];
    s.gryColor = [0.5 0.5 0.5];
    s.otherColor = [0 0.8 0.8];
    PsychDefaultSetup_dev(3);%custom, made by TH
    params = PsychSetupParams(s.gryColor,0,1);%custom, made by TH
    [s.redColor, s.grnColor, s.gryColor] = FlickerTest(params);
    s.redColor = s.redColor';
    s.grnColor = s.grnColor';
    s.gryColor = s.gryColor';
    Screen('Close',params.win);
    %params.win = PsychImaging('OpenWindow', params.screen, s.gryColor,[],32,2,[],[],kPsychNeed32BPCFloat);
    %Screen('BlendFunction', params.win, 'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');
    params = PsychSetupParams(s.gryColor,0,1);%custom, made by TH
    %HideCursor(params.screen);
    Screen('TextSize', params.win, 28);
    xplaces = linspace(0, params.maxXpixels,5);
    rectPad = 150;
    %rectSize = xplaces(3) - xplaces(1)-(rectPad*2);
    rectSize = 300;
    baseRect = [0 0 rectSize rectSize]; %make a PTB rect var
    posXs = [params.maxXpixels*0.3 params.maxXpixels*0.7];%X positions for the stimuli
    %posXs = [xplaces(2) xplaces(4)];%X positions for the stimuli
    posYs = [params.maxYpixels*0.5 params.maxYpixels*0.5];%Y positions for the stimuli
    s.angles = [0 0];%%IMPORTANT
    s.SOA = 1;%%IMPORTANT
    s.angleMin = -90;
    s.angleMax = 90;
    params.stimDur = 30; %30 frames = 500 msec
    params.dotType = 2;%fixation dot type
    params.dotSize = 10;%size of circle
    params.dotdur = 15;%duration of fixation alone, at beginning of trials
    doRand = 1; %randomize and balance trials
    gaborDimPix = rectSize;
    sigma = gaborDimPix / 6;
    contrast = 0.7;
    aspectRatio = 1;
    phase = 0;
    numCycles = 15;
    freq = numCycles / gaborDimPix;
    backgroundOffset = [s.gryColor 0];
    disableNorm = 1;
    preContrastMultiplier = 0.5;
    propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];
    gabortex1 = CreateProceduralGabor(params.win, gaborDimPix, gaborDimPix, [], backgroundOffset, disableNorm, preContrastMultiplier,[0 1]);
    gabortex2 = CreateProceduralGabor(params.win, gaborDimPix, gaborDimPix, [], backgroundOffset, disableNorm, preContrastMultiplier,[0 1]);
    % For psychAdapt:
    targetAcc = 0.75;
    sj_threshGuess = 0.2;
    sj_minVal = 0.01;
    sj_maxVal = 0.4; %sj comparison value is set to 0.5, so cant go above that
    %OR
    or_threshGuess = 15;
    or_minVal = 1;
    or_maxVal = 45;
    %CL
    cl_threshGuess = 0.1;
    cl_minVal = 0.001;
    cl_maxVal = 0.25;
    if strcmpi(runtype,'t1')
        s.trainTrials = 56;
        %instruct1 = sprintf('For this part of the experiment you will\nsee two rectangles on the screen and\nyou will make decisions based on your current task.\nSometimes you will make decisions about TIME\nand other times you will make decisions\nabout the COLOR or ANGLE of the rectangles.\nYour decision will be one of two options\nSAME or DIFFERENT.\nPress your thumb button for SAME\nand your index finger button for DIFFERENT.\nPress the thumb button now to continue.');
        %instruct2 = sprintf('During the experiment the task\nmay change from one block to the next.\nTo indicate your task, there will be\n the word TIME, COLOR, or ANGLE\ndisplayed on the screen for 1 second\n after each rest period. Keep in\n mind that the timing, color, and angle\nof each rectangle may be different\nor the same, but you must focus only on the\nproperty indicated by your task.\nPress the index finger button to begin.');
        s.task = {};
        s.tasks = {'SJ','OR','CL'}; %do all 3 tasks for initial titration
        s.SJ = psychAdapt('setup',...
            'targetAcc', targetAcc,...
            'threshGuess', sj_threshGuess,...
            'min', sj_minVal,...
            'max', sj_maxVal,...
            'probeLength', s.trainTrials); 
        s.CL = psychAdapt('setup',...
            'targetAcc', targetAcc,...
            'threshGuess', cl_threshGuess,...
            'min', cl_minVal,...
            'max', cl_maxVal,...
            'probeLength', s.trainTrials);
        s.OR = psychAdapt('setup',...
            'targetAcc', targetAcc,...
            'threshGuess', or_threshGuess,...
            'min', or_minVal,...
            'max', or_maxVal,...
            'probeLength', s.trainTrials);
        %s.SJ = simpleStair2('create', 'initialVal', sj_initVal, 'minVal', sj_minVal, 'maxVal', sj_maxVal, 'stepSize', sj_stepSize, 'name', 'SJ');
        %s.CL = simpleStair2('create', 'initialVal', cl_initVal, 'minVal', cl_minVal, 'maxVal', cl_maxVal, 'stepSize', cl_stepSize, 'name', 'CL');
        %s.OR = simpleStair2('create', 'initialVal', or_initVal, 'minVal', or_minVal, 'maxVal', or_maxVal, 'stepSize', or_stepSize, 'name', 'OR');

    elseif strcmpi(runtype,'fmri1')
        l = load(fullfile(subdir,['sub_' subjectString '_t1.mat']));
        %s.SJ = l.s.SJ;
        s.SJ = psychAdapt('computeThreshold', 'model', l.s.SJ);
        s.CL = psychAdapt('computeThreshold', 'model', l.s.CL);
        s.OR = psychAdapt('computeThreshold', 'model', l.s.OR);
    elseif strcmpi(runtype,'fmri2')
        l = load(fullfile(subdir,['sub_' subjectString '_fmri1.mat']));
        s.SJ = psychAdapt('computeThreshold', 'model', l.s.SJ);
        s.CL = psychAdapt('computeThreshold', 'model', l.s.CL);
        s.OR = psychAdapt('computeThreshold', 'model', l.s.OR);
    end
    if ~strcmpi(runtype,'t1') %if any run but the t1 scan (initial titration)
        s.nblockseach = 6;
        vals = {'SJ','CL','OR'}; %will be 12 blocks per fmri scan
        s.tasks = [];
        for i = 1:s.nblockseach
            s.tasks = [s.tasks repmat(vals(randperm(size(vals,2))),1,1)];
        end
        s.nblocks = length(s.tasks);
        s.ntrials = 16;%trials per block, ntrials must be even
    else %else, do 40 trials of each task during t1
        s.ntrials = s.trainTrials;
        s.nblocks = 3;
    end
    instruct1 = sprintf('For this part of the experiment you will\n\nsee two shapes on the screen and\n\nyou will make decisions based on your current task.\n\nSometimes you will make decisions about TIME\n\nand other times you will make decisions\n\nabout the COLOR or ANGLE of the rectangles.\n\nYour decision will be one of two options\n\nSAME or DIFFERENT.\n\nPress your index finger button for SAME\n\nand your middle finger button for DIFFERENT.\n\nPress the index finger button now to continue.');
    instruct2 = sprintf('During the experiment the task\n\nmay change from one block to the next.\n\nTo indicate your task, there will be\n\n the word TIME, COLOR, or ANGLE\n\ndisplayed on the screen for 1 second\n\n after each rest period. Keep in\n\n mind that the timing, color, and angle\n\nof each rectangle may be different\n\nor the same, but you must focus only on the\n\nproperty indicated by your task.\n\nPress the middle finger button to begin.');
    ShowInstructions(instruct1,'2@');
    ShowInstructions(instruct2,'3#');
    s.expStartTime = WaitForScannerStart;
    
    for b = 1:s.nblocks   
        if b == 1
            Screen('DrawDots', params.win, [params.Xc params.Yc], params.dotSize ,params.colors.black, [], params.dotType);
            dotOn = Screen('Flip', params.win);
            Screen('Flip', params.win,dotOn+ (params.ifi*(s.nRestFrames-0.5)));
        end
        s.blockOnsetTime(b) = GetSecs-s.expStartTime;
        if strcmpi(s.tasks{b},'SJ')
            taskText = 'TIME';
            %s.simCL = s.CL;
            %s.simOR = s.OR;
        elseif strcmpi(s.tasks{b},'OR')
            taskText = 'ANGLE';
            %s.simSJ = s.SJ;
            %s.simCL = s.CL;
        elseif strcmpi(s.tasks{b},'CL')
            taskText = 'COLOR';
            %s.simSJ = s.SJ;
            %s.simOR = s.OR;
        end
        params.taskText = taskText;
        DrawFormattedText(params.win,taskText, 'center', 'center');
        taskTextOn = Screen('Flip',params.win);
        Screen('Flip',params.win,taskTextOn + (60-0.5) * params.ifi);%wait 60 frames (about 1sec at 60Hz)
        %[s.leftRight(b,:), s.sameDiffSJ(b,:), s.sameDiffCL(b,:), s.sameDiffOR(b,:)] = BalanceTrials(s.ntrials,doRand,[0 1],[0 1],[0 1],[0 1]);
        if strcmpi(s.tasks{b},'SJ')
            if strcmpi(runtype,'fmri1') || strcmpi(runtype,'fmri2')
                [s.leftRight(b,:), s.sameDiffSJ(b,:)] = BalanceTrials(s.ntrials,doRand,[0 1],[0 0 0 1]);
            else
                [s.leftRight(b,:), s.sameDiffSJ(b,:)] = BalanceTrials(s.ntrials,doRand,[0 1],[0 0 0 1]);
                s.sameDiffSJ(b,:) = 0; %set all trials to be different only for training and making model
            end
            s.sameDiffCL(b,1:s.ntrials) = 1;
            s.sameDiffOR(b,1:s.ntrials) = 1;
        elseif strcmpi(s.tasks{b},'CL')
            if strcmpi(runtype,'fmri1') || strcmpi(runtype,'fmri2')
                [s.leftRight(b,:), s.sameDiffCL(b,:)] = BalanceTrials(s.ntrials,doRand,[0 1],[0 0 0 1]);
            else
                [s.leftRight(b,:), s.sameDiffCL(b,:)] = BalanceTrials(s.ntrials,doRand,[0 1],[0 0 0 1]);
                s.sameDiffCL(b,:) = 0; %set all trials to be different only for training and making model
            end
            s.sameDiffSJ(b,1:s.ntrials) = 1;
            s.sameDiffOR(b,1:s.ntrials) = 1;
        elseif strcmpi(s.tasks{b},'OR')
            if strcmpi(runtype,'fmri1') || strcmpi(runtype,'fmri2')
                [s.leftRight(b,:), s.sameDiffOR(b,:)] = BalanceTrials(s.ntrials,doRand,[0 1],[0 0 0 1]);
            else
                [s.leftRight(b,:), s.sameDiffOR(b,:)] = BalanceTrials(s.ntrials,doRand,[0 1],[0 0 0 1]);
                s.sameDiffOR(b,:) = 0; %set all trials to be different only for training and making model
            end
            s.sameDiffCL(b,1:s.ntrials) = 1;
            s.sameDiffSJ(b,1:s.ntrials) = 1;
        end
        for i = 1:s.ntrials
            if strcmpi(s.tasks{b},'SJ')
                %s.randAngle(b,i) = randi([s.angleMin, s.angleMax]);
                s.randAngle(b,i) = 90;
                s.SOA(b,i) = s.SJ.stimVal; 
                s.rectColors(b,i).colorMat = [s.redColor; s.redColor;];
                s.rectAngles(b,i).angles = [s.randAngle(b,i) s.randAngle(b,i)];
                [s.RT(b,i), s.acc(b,i), s.response(b,i), s.TrialOnsetTime(b,i), s.trialOffTime(b,i)] = ShowStimulus(params, s.sameDiffSJ(b,i), s.sameDiffCL(b,i), s.sameDiffOR(b,i), s.leftRight(b,i), s.rectColors(b,i).colorMat, s.rectAngles(b,i).angles, s.SOA(b,i), s.respTimeOut, s.maxTrialSecs, s.tasks(b));
                s.TrialOnsetTime(b,i) = s.TrialOnsetTime(b,i) - s.expStartTime;
                s.trialOffTime(b,i) = s.trialOffTime(b,i) - s.expStartTime;
                if (s.RT(b,i) < 999)
                    if strcmpi(runtype,'t1')
                        cmd = 'train';
                    else
                        cmd = 'test';
                    end
                    if (s.sameDiffSJ(b,i) == 0)
                        %s.SJ = CalculateStimLevel(s.SJ,s.acc(b,i));
                        s.SJ = psychAdapt(cmd,'model',s.SJ,'acc',s.acc(b,i),'stimulusValue',s.SJ.stimVal);
                        %s.SJ = simpleStair2('update', 'data', s.SJ, 'accuracy', s.acc(b,i));
                    elseif (s.sameDiffSJ(b,i) == 1 & s.acc(b,i) == 0) %#ok
                        %s.SJ = CalculateStimLevel(s.SJ,s.acc(b,i));
                        %s.SJ = psychAdapt(cmd,'model',s.SJ,'acc',s.acc(b,i),'stimulusValue',s.SJ.stimVal);
                        %s.SJ = simpleStair2('update', 'data', s.SJ, 'accuracy', s.acc(b,i));
                    end 
                end
                
            elseif strcmpi(s.tasks{b},'CL')
                defaultSOA = s.SJ.train.min;
                %s.randAngle(b,i) = randi([s.angleMin, s.angleMax]);
                s.randAngle(b,i) = 90;
                s.SOA(b,i) = defaultSOA;
                s.rectColors(b,i).colorMat = [s.redColor; [(s.redColor(1)-s.CL.stimVal) s.CL.stimVal*(0.299/0.587) 0];];
                %s.rectColors(b,i).colorMat = [s.redColor; [(s.CL.stimVal) s.CL.stimVal*(0.299/0.587) 0];];
                s.rectAngles(b,i).angles = [s.randAngle(b,i) s.randAngle(b,i)];
                [s.RT(b,i), s.acc(b,i), s.response(b,i), s.TrialOnsetTime(b,i), s.trialOffTime(b,i)] = ShowStimulus(params, s.sameDiffSJ(b,i), s.sameDiffCL(b,i), s.sameDiffOR(b,i), s.leftRight(b,i), s.rectColors(b,i).colorMat, s.rectAngles(b,i).angles, s.SOA(b,i), s.respTimeOut, s.maxTrialSecs, s.tasks(b));
                s.TrialOnsetTime(b,i) = s.TrialOnsetTime(b,i) - s.expStartTime;
                s.trialOffTime(b,i) = s.trialOffTime(b,i) - s.expStartTime;
                
                if (s.RT(b,i) < 999)
                    if strcmpi(runtype,'t1')
                        cmd = 'train';
                    else
                        cmd = 'test';
                    end
                    if (s.sameDiffCL(b,i) == 0)
                        %s.CL = CalculateStimLevel(s.CL,s.acc(b,i));
                        %s.CL = simpleStair2('update', 'data', s.CL, 'accuracy', s.acc(b,i));
                        s.CL = psychAdapt(cmd,'model',s.CL,'acc',s.acc(b,i),'stimulusValue',s.CL.stimVal);
                    elseif (s.sameDiffCL(b,i) == 1 & s.acc(b,i) == 0) %#ok
                        %s.CL = CalculateStimLevel(s.CL,s.acc(b,i));
                        %s.CL = simpleStair2('update', 'data', s.CL, 'accuracy', s.acc(b,i));
                        %s.CL = psychAdapt(cmd,'model',s.CL,'acc',s.acc(b,i),'stimulusValue',s.CL.stimVal);
                    end
                end
                
            elseif strcmpi(s.tasks{b},'OR')
                defaultSOA = s.SJ.train.min;
                %s.randAngle(b,i) = randi([s.angleMin, s.angleMax]);
                s.randAngle(b,i) = 90;
                s.SOA(b,i) = defaultSOA;
                s.rectColors(b,i).colorMat = [s.redColor; s.redColor;];
                %s.rectAngles(b,i).angles = [s.randAngle(b,i) s.randAngle(b,i)-s.OR.stimVal];
                s.rectAngles(b,i).angles = [s.randAngle(b,i) s.randAngle(b,i)-s.OR.stimVal];
                [s.RT(b,i), s.acc(b,i), s.response(b,i), s.TrialOnsetTime(b,i), s.trialOffTime(b,i)] = ShowStimulus(params, s.sameDiffSJ(b,i), s.sameDiffCL(b,i), s.sameDiffOR(b,i), s.leftRight(b,i), s.rectColors(b,i).colorMat, s.rectAngles(b,i).angles, s.SOA(b,i), s.respTimeOut, s.maxTrialSecs, s.tasks(b));
                s.TrialOnsetTime(b,i) = s.TrialOnsetTime(b,i) - s.expStartTime;
                s.trialOffTime(b,i) = s.trialOffTime(b,i) - s.expStartTime;
                %s.trialDuration(b,i) = s.trialOffTime(b,i) - s.TrialOnsetTime(b,i);
                if (s.RT(b,i) < 999)
                    if strcmpi(runtype,'t1')
                        cmd = 'train';
                    else
                        cmd = 'test';
                    end
                    if (s.sameDiffOR(b,i) == 0)
                        %s.OR = CalculateStimLevel(s.OR,s.acc(b,i));
                        %s.OR = simpleStair2('update', 'data', s.OR, 'accuracy', s.acc(b,i));
                        s.OR = psychAdapt(cmd,'model',s.OR,'acc',s.acc(b,i),'stimulusValue',s.OR.stimVal);
                    elseif (s.sameDiffOR(b,i) == 1 & s.acc(b,i) == 0) %#ok
                        %s.OR = CalculateStimLevel(s.OR,s.acc(b,i));
                        %s.OR = simpleStair2('update', 'data', s.OR, 'accuracy', s.acc(b,i));
                        %s.OR = psychAdapt(cmd,'model',s.OR,'acc',s.acc(b,i),'stimulusValue',s.OR.stimVal);
                    end
                end
            end
            s.trialDuration(b,i) = s.trialOffTime(b,i) - s.TrialOnsetTime(b,i);
            if (s.trialDuration(b,i) > s.maxTrialSecs)
                s.trimTime = s.trialDuration(b,i) - s.maxTrialSecs;
            end
            save(subFile,'s');%save 's' structure every trial
        end %--trials
        s.blockOffsetTime(b) = GetSecs-s.expStartTime;
        s.blockDuration(b) = s.blockOffsetTime(b) - s.blockOnsetTime(b);
        save(subFile,'s');%save 's' structure
        %draw central fixation dot in back buffer
        Screen('DrawDots', params.win, [params.Xc params.Yc], params.dotSize ,params.colors.black, [], params.dotType);
        s.RestStart(b) = Screen('Flip', params.win);
        s.RestEnd(b) = Screen('Flip', params.win,s.RestStart(b)+ (params.ifi*(s.nRestFrames-0.5)));
        %s.RestEnd(b) = WaitSecs(10);
        s.RestStart(b) = s.RestStart(b) - s.expStartTime;
        s.RestEnd(b) = s.RestEnd(b) - s.expStartTime;
        s.RestDuration(b) = s.RestEnd(b) - s.RestStart(b);
        save(subFile,'s');
    end %--blocks
    s.expDuration = GetSecs- s.expStartTime;
    s.scannerEndTime = GetSecs;
    %s.scannerEndTime = WaitForScannerEnd;
    
    save(subFile,'s');
    % Clear the screen
    CleanUp;
    %disp(sprintf('\n\n** Accuracies **\n\nSJ: %2.2f, CL: %2.2f, OR: %2.2f', mean(s.SJ.accuracy)*100, mean(s.CL.accuracy)*100, mean(s.OR.accuracy)*100))
    
catch CatchError
    RestrictKeysForKbCheck([])
    ListenChar(0);
    sca;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               Sub routines below:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function expStartTime = WaitForScannerStart(keyToWaitFor)
        if nargin < 1; keyToWaitFor = 's'; end;
        DrawFormattedText(params.win,'Waiting for MRI to start the experiment...', 'center', 'center');
        Screen('Flip',params.win);
        RestrictKeysForKbCheck(KbName(keyToWaitFor));
        deviceN = -2;
        %expStartTime = KbWait(deviceN);
        GetClicks
        expStartTime = GetSecs;
        RestrictKeysForKbCheck([]);
    end %WaitForScannerStart

    function expEndTime = WaitForScannerEnd(keyToWaitFor)
        KbName('UnifyKeyNames');
        if nargin < 1; keyToWaitFor = 'space'; end;
        RestrictKeysForKbCheck(KbName(keyToWaitFor));
        deviceN = -1;
        time2wait = 0.8; %wait max of 800ms (our TR is 720ms)
        timeSinceLastKey = 0;
        expEndTimeVec(1) = GetSecs;
        while timeSinceLastKey < time2wait
            t = GetSecs;
            t2 = KbWait(deviceN,[],t+time2wait);
            timeSinceLastKey = t2-t;
        end
        expEndTime = expEndTimeVec(end);
        RestrictKeysForKbCheck([]);
    end %WaitForScannerEnd

    function ShowInstructions(instruct,keyToWaitFor)
        if nargin < 2; keyToWaitFor = 'escape'; end;
        DrawFormattedText(params.win, instruct, 'center', 'center');
        Screen('Flip',params.win);
        RestrictKeysForKbCheck(KbName(keyToWaitFor));
        deviceN = -2;
        KbWait(deviceN);
        RestrictKeysForKbCheck([]);
    end

    function [accuracy] = responderSub(threshold,noise)
        if nargin < 2
            noise = 1.1;
        end
        %threshold = 25.5; %estimated participant threshold
        perceived = threshold+((rand()-0.5)*noise);
        accuracy = perceived > threshold;
    end %responderSub

    function SJ = setupSJpest(stimStart)
        stimMin = 0.1; 
        if nargin < 1
            stimStart = 0.4; %starting threshold
        end
        stimMax = 1; 
        minStep = 0.05; 
        startStep = 0.1; %starting adjustment size 
        maxStep = 0.4; %largest adjustement size
        SJ = SetUpAdaptiveStimLevel('PEST2',stimStart,stimMin,stimMax,startStep, minStep, maxStep);
        
    end %setupSJpest

    function CL = setupCLpest(stimStart)
        stimMin = 0.001; %minumum difference in red hue
        if nargin < 1
            stimStart = 0.2; %0-1
        end
        stimMax = 0.8; %
        minStep = 0.001; %
        startStep = 0.05; %
        maxStep = 0.2; %largest adjustement size
        CL = SetUpAdaptiveStimLevel('PEST2',stimStart,stimMin,stimMax,startStep, minStep, maxStep);
        
    end %setupCLpest

    function OR = setupORpest(stimStart)
        stimMin = 0.1; %minumum difference in angle of orientation
        if nargin < 1
            stimStart = 20; %
        end
        stimMax = 45;
        minStep = 0.1;
        startStep = 5; %
        maxStep = 10; %largest adjustement size
        OR = SetUpAdaptiveStimLevel('PEST2',stimStart,stimMin,stimMax,startStep, minStep, maxStep);
        
    end %setupORpest

    function [RT, acc, response, TrialOnsetTime, trialOffTime] = ShowStimulus(params, sameSJ, sameCL, sameOR, presOrder, rectColors, rectAngles, SOA, respTimeOut, maxTrialSecs, thisTask)
        %b1 = s.SJ.minVal;
        b1 = 0.5;
        if sameSJ
            SOA = b1;
            b2 = b1;
        else
            b2 = b1-SOA;
        end
        if sameCL
            rectColors(2,:) = rectColors(1,:);
        end
        if sameOR
            rectAngles(2) = rectAngles(1);
        end
        nframes = params.stimDur;
        waitframes = 1;
        RestrictKeysForKbCheck([KbName('escape') KbName('2@') KbName('3#')]);
        dontClear = 1;
        oldSize = Screen('TextSize', params.win, 18);
        DrawFormattedText(params.win,params.taskText(1), 'center', 'center');
        vbl = Screen('Flip', params.win); %flip the screen to get a time stamp
        for f = 1:nframes
            nfdiv2 = nframes/2;
            if f <= nfdiv2
                bias1 = getBias(f/(nfdiv2),b1);
                bias2 = getBias(f/(nfdiv2),b2);
            else
                bias1 = 1 - getBias((f - ceil(nfdiv2))/(nfdiv2),b1);
                bias2 = 1 - getBias((f - ceil(nfdiv2))/(nfdiv2),b2);
            end
            if presOrder; ho1 = 1; ho2 = 2; elseif ~presOrder; ho1 = 2; ho2 = 1; end
            %Screen('DrawDots', params.win, [params.Xc params.Yc], params.dotSize ,params.colors.black, [], params.dotType);
            DrawFormattedText(params.win,params.taskText(1), 'center', 'center');
            Screen('DrawTextures', params.win, gabortex1, [], CenterRectOnPoint(baseRect, posXs(ho1), posYs(1)), rectAngles(1), [], [], rectColors(1,:)*bias1, [], kPsychDontDoRotation, propertiesMat');
            Screen('DrawTextures', params.win, gabortex2, [], CenterRectOnPoint(baseRect, posXs(ho2), posYs(1)), rectAngles(2), [], [], rectColors(2,:)*bias2, [], kPsychDontDoRotation, propertiesMat');
            vbl = Screen('Flip', params.win, vbl + (waitframes-0.5) * params.ifi);%now show it on screen by itself
            if f == 1
                TrialOnsetTime = vbl;
            end
            %[keyDown, secs, keycode] = KbCheck(-1);
        end
        %Screen('DrawDots', params.win, [params.Xc params.Yc], params.dotSize ,params.colors.black, [], params.dotType);
        %Screen('Flip', params.win);
        deviceN = -1;
        forWhat = [];
        untilTime = vbl+respTimeOut - s.trimTime;
        RT = 999;
        [secs, keycode] = KbWait(deviceN, forWhat, untilTime);
        if strcmpi(thisTask,'CL')  
            if keycode(KbName('2@')) && sameCL > 0 %stimuli were same and response was same
                response = 1;
                RT = secs-TrialOnsetTime;
                acc = 1;
            elseif keycode(KbName('2@')) && sameCL == 0
                response = 1;
                RT = secs-TrialOnsetTime;
                acc = 0;
            elseif keycode(KbName('3#')) && sameCL > 0
                response = 2;
                RT = secs-TrialOnsetTime;
                acc = 0;
            elseif keycode(KbName('3#')) && sameCL == 0 %stimuli were different and response was different
                response = 2;
                RT = secs-TrialOnsetTime;
                acc = 1;
            elseif keycode(KbName('escape'))
                sca;
                ListenChar(0);
                error('ESCAPE was pressed during a trial!');
            else
                response = 999;
                RT = 999;
                acc = 0;
            end
        elseif strcmpi(thisTask,'OR')
            if keycode(KbName('2@')) && sameOR > 0 %stimuli were same and response was same
                response = 1;
                RT = secs-TrialOnsetTime;
                acc = 1;
            elseif keycode(KbName('2@')) && sameOR == 0
                response = 1;
                RT = secs-TrialOnsetTime;
                acc = 0;
            elseif keycode(KbName('3#')) && sameOR == 0 %stimuli were different and response was different
                response = 2;
                RT = secs-TrialOnsetTime;
                acc = 1;
            elseif keycode(KbName('3#')) && sameOR > 0 
                response = 2;
                RT = secs-TrialOnsetTime;
                acc = 0;
            elseif keycode(KbName('escape'))
                sca;
                ListenChar(0);
                error('ESCAPE was pressed during a trial!');
            else
                response = 999;
                RT = 999;
                acc = 0;
            end
        elseif strcmpi(thisTask,'SJ')
            if keycode(KbName('2@')) && sameSJ > 0 %stimuli were same and response was same
                response = 1;
                RT = secs-TrialOnsetTime;
                acc = 1;
            elseif keycode(KbName('2@')) && sameSJ == 0 %stimuli were different and response was same
                response = 1;
                RT = secs-TrialOnsetTime;
                acc = 0;
            elseif keycode(KbName('3#')) && sameSJ == 0 %stimuli were different and response was different
                response = 2;
                RT = secs-TrialOnsetTime;
                acc = 1;
            elseif keycode(KbName('3#')) && sameSJ > 0 %stimuli were same and response was different
                response = 2;
                RT = secs-TrialOnsetTime;
                acc = 0;
            elseif sum(keycode) < 1 %no response
                response = 3; %no response
                RT = 999; %dummy value
                acc = 0;
            elseif keycode(KbName('escape'))
                sca;
                ListenChar(0);
                error('ESCAPE was pressed during a trial!');
            else
                response = 999; %impossible value for this experiment!!! (only 1 and 2 allowed)
                RT = 999;
                acc = 0;
            end
        end
        %{
        if strcmpi(runtype,'t1') && acc > 0 && response < 3
            Screen('DrawDots', params.win, [params.Xc params.Yc], params.dotSize ,params.colors.black, [], params.dotType);
            Screen('Flip', params.win);
        elseif strcmpi(runtype,'t1') && acc < 1 && response < 3
            Screen('DrawDots', params.win, [params.Xc params.Yc], params.dotSize ,params.colors.black, [], params.dotType);
            Screen('Flip', params.win);
        else
            Screen('DrawDots', params.win, [params.Xc params.Yc], params.dotSize ,params.colors.black, [], params.dotType);
            Screen('Flip', params.win);
        end
        %}
        trialOffTime = WaitSecs('UntilTime',TrialOnsetTime+maxTrialSecs);
        Screen('TextSize', params.win, oldSize);
        %Screen('Close');
    end %ShowStimulus

    function CleanUp
        RestrictKeysForKbCheck([])
        ListenChar(0);
        sca;
    end %CleanUp
        
    function bias = getBias(t, b)
        %credit: http://demofox.org/biasgain.html
        if (b <= 0) | (t <= 0), bias = 0; return; end; %#ok
        if (b >= 1) | (t >= 1), bias = 1; return; end; %#ok
        bias = (t / ((((1.0/b) - 2.0)*(1.0 - t))+1.0));
        % (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
        
    end

    function gn = getGain(t, g)
        %credit: http://demofox.org/biasgain.html
        if(t < 0.5)
            gn = getBias(t * 2.0,g)/2.0;
        else
            gn = getBias(t * 2.0 - 1.0,1.0 - g)/2.0 + 0.5;
        end
    end
        
    end %temporalPerceptionExp
    
    
    