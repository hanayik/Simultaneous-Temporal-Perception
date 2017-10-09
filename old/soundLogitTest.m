%soundLogitTest
clear all; clc; close all;
%exp setup:
stimulusHz = 1500;
stimulus2Hz = 1500;
gapDur = 0; % in samples, not secs
nTrials = 40;
threshGuess = 500;
sdGuess = threshGuess;
distSize = nTrials;
stimMin = 1;
stimMax = threshGuess*2;

pa = psychAdapt('setup', 'targetAcc', 0.75, 'threshGuess', threshGuess, 'sdGuess', sdGuess, 'min', stimMin, 'max', stimMax, 'probeLength', nTrials); 


%sound setup:
sf = 44100; % sample frequency (Hz)
d = 1.0;    % duration (s)
n = sf * d; % number of samples
stim = (1:n) / sf; % sound data preparation
stim1 = sin(2 * pi * stimulusHz * stim);     % sinusoidal modulation
stim2 = sin(2 * pi * stimulus2Hz * stim);    % intertrial sound (its)
minGapLoc = round(n*0.4); % start at minimum of 40% through stimulus
maxGapLoc = round(n*0.6); % start at maximum of 60% through stimulus
%sound(stim, sf);  % sound presentation
%pause(d + 0.5);    % waiting for sound end

%% train
 %R = round(normrnd(threshGuess, sdGuess, [1 distSize]));
 nodetect = [];
 detect = [];
LR = [zeros(1,nTrials/2) ones(1,nTrials/2)]';
rp = randperm(nTrials);
LR = LR(rp);
for i = 1:nTrials
    %setup random stimulus val:
    %R = round(normrnd(threshGuess, sdGuess, [1 distSize]));
    %r = randi([1 length(R)]);
    %gapDur = R(i);
    gapDur = round(pa.train.stimVal);
    
    if gapDur < 0
        gapDur = 1;
    end
    
    thisStim(1,:) = stim1;
    thisStim(2,:) = stim2;
    thisStim(1,1:gapDur) = 0;
%     if LR(i) %L = 1
%         thisStim(1,1:gapDur) = 0; % set sound to zero to make gap
%     else %R = 0
%         thisStim(2,1:gapDur) = 0; % set sound to zero to make gap
%     end
    % play sound
    sound(thisStim, sf);  % sound presentation
    pause(d);    % waiting for sound end
    reply = input('Onset difference? Y/N: ','s');
    if strcmpi(reply, 'y')
        detect = [detect gapDur];
        acc = 1;
    elseif strcmpi(reply, 'n')
        nodetect = [nodetect gapDur];
        acc = 0;
    end
    pa = psychAdapt('train','model',pa,'acc',acc,'stimulusValue',gapDur);
    pause(1);
end
%pa = psychAdapt('plotTraining', 'model',pa);
%nodetect = normrnd(0.4, 0.1,10,1);
%detect = normrnd(0.2, 0.1,10,1);
% acc = [zeros(size(nodetect)) ones(size(detect))]';
% stimVals = [nodetect detect]';
% n = ones(size(acc));
% b = glmfit(stimVals,[acc n],'binomial','link','logit');
% yfit = glmval(b,stimVals,'logit');
% [yfits, I] = sort(yfit);
% plot(stimVals(I), acc(I)./n,'o',stimVals(I),yfits./n,'-','LineWidth',2)
% p75 = 0.75;
% thresh75 = (log(p75/(1-p75)) + abs(b(1)))/b(2);
% 
% pupper = p75+0.1;
% threshUpper = (log(pupper/(1-pupper)) + abs(b(1)))/b(2);
% 
% plower = p75-0.1;
% threshLower = (log(plower/(1-plower)) + abs(b(1)))/b(2);


%% test
testDetect = [];
testNodetect = [];
testStim = [];
LR = [zeros(1,nTrials/2) ones(1,nTrials/2)]';
rp = randperm(nTrials);
LR = LR(rp);
for i = 1:nTrials
    % setup random stimulus val:
    %R = round(normrnd(thresh75, (threshUpper-threshLower)/2, [1 distSize]));
%     R = round(normrnd(thresh75, thresh75*0.25, [1 distSize]));
%     r = randi([1 length(R)]);
%     gapDur = R(r);
    gapDur = round(pa.test.stimVal);
    %gapDur = round(mean(R));
    %gapDur = round(thresh75);
    if gapDur < 0
        gapDur = 1;
    end
    
    %gapDur = 1;   
    
    thisStim(1,:) = stim1;
    thisStim(2,:) = stim2;
    thisStim(1,1:gapDur) = 0;
%     if LR(i) %L = 1
%         thisStim(1,1:gapDur) = 0; % set sound to zero to make gap
%     else %R = 0
%         thisStim(2,1:gapDur) = 0; % set sound to zero to make gap
%     end
    % play sound
    sound(thisStim, sf);  % sound presentation
    pause(d);    % waiting for sound end
    reply = input('[testing] Onset difference? Y/N: ','s');
    if strcmpi(reply, 'y')
        detect = [detect gapDur];
        testDetect = [testDetect gapDur];
        acc = 1;
    elseif strcmpi(reply, 'n')
        nodetect = [nodetect gapDur];
        testNodetect = [testNodetect gapDur];
        acc = 0;
    end
    
    pa = psychAdapt('test','model',pa,'acc',acc,'stimulusValue',gapDur);
    pause(1);
%     acc = [zeros(size(nodetect)) ones(size(detect))]';
%     testAcc = [zeros(size(testNodetect)) ones(size(testDetect))]';
%     testStim = [testStim gapDur];
%     stimVals = [nodetect detect]';
%     n = ones(size(acc));
%     b = glmfit(stimVals,[acc n],'binomial','link','logit');
%     yfit = glmval(b,stimVals,'logit');
%     [yfits, I] = sort(yfit);
%     p75 = 0.75;
%     thresh75 = (log(p75/(1-p75)) + abs(b(1)))/b(2);
%     
%     pupper = p75+0.1;
%     threshUpper = (log(pupper/(1-pupper)) + abs(b(1)))/b(2);
%     
%     plower = p75-0.1;
%     threshLower = (log(plower/(1-plower)) + abs(b(1)))/b(2);
%     plot(stimVals(I), acc(I)./n,'o',stimVals(I),yfits./n,'-','LineWidth',2)
end
pa = psychAdapt('plotTesting', 'model',pa);
%plot(stimVals(I), acc(I)./n,'o',stimVals(I),yfits./n,'-','LineWidth',2)





