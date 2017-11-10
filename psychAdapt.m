function pa = psychAdapt(cmd, varargin)
%{ 
    cmd is a STRING input and should be one of the following:

    'setup'             (prepare the adaptive track with initial values
    'train'             (train the adaptive model around a threshold estimate
    'test'              (use this for upating the model after each trial with the most
                        recent information: threshold used and trial accuracy)
    'plotTraining       (plot the logistic psychometric function with the
                        threshold estimate "starred" on the plot)
    'outputEstimate'    (display the threshold at the target accuracy level)
  
    variable inputs should be in pairs('input', val), and can be any of the following:

    'model' :structure                ----  the model structure that saves all adaptive track information (needs to be passed in each time during training and updating)
    'targetAcc': number (> 0 and < 1) ----  the target accuracy that the model will adapt performance to
    'threshGuess': number             ----  the guess for the threshold at the targetAcc (supply this if training, if updating this will be computed for you) 
    'min': number                     ----  minimum stimulus value
    'max': number                     ----  maximum stimulus value
    'acc': number 0 or 1              ----  accuracy for the trial that was shown (0 or 1)
    'name': string                    ----  optional name for this adaptive track (ex. audio, visual, haptic, etc.)
    'probeLength': number             ----  number of trials for training
    'stimulusValue': number           ----  value used for the most recent stimulus
%}

switch cmd
    
    case 'setup'
        pa.train.trialIdx = 0;
        pa.test.trialIdx = 0;
        pa.train.targetAcc   = cell2mat(varargin(find(strcmp(varargin, 'targetAcc'))+1));
        pa.test.targetAcc    = cell2mat(varargin(find(strcmp(varargin, 'targetAcc'))+1));
        pa.train.threshGuess = cell2mat(varargin(find(strcmp(varargin, 'threshGuess'))+1));
        pa.train.min         = cell2mat(varargin(find(strcmp(varargin, 'min'))+1));
        pa.train.max         = cell2mat(varargin(find(strcmp(varargin, 'max'))+1));
        pa.train.probeLength = cell2mat(varargin(find(strcmp(varargin, 'probeLength'))+1));
        %{
        pa.train.probeVals   = normrnd(pa.train.threshGuess, pa.train.sdGuess, [1 pa.train.probeLength]);
        pa.train.probeVals(pa.train.probeVals > pa.train.max) = pa.train.max;
        pa.train.probeVals(pa.train.probeVals < pa.train.min) = pa.train.min;
        pa.train.probeVals(pa.train.probeVals > pa.train.threshGuess+pa.train.sdGuess) = pa.train.threshGuess+pa.train.sdGuess;
        pa.train.probeVals(pa.train.probeVals < pa.train.threshGuess-pa.train.sdGuess) = pa.train.threshGuess-pa.train.sdGuess;
        %}
        pa.train.probeVals = Shuffle(linspace(pa.train.min,pa.train.max,pa.train.probeLength));
        pa.train.stimVal = pa.train.threshGuess;
        pa.stimVal = pa.train.stimVal;
    case 'train'
        pa                   = cell2mat(varargin(find(strcmp(varargin, 'model'))+1));
        pa.train.trialIdx    = pa.train.trialIdx + 1;
        i                    = pa.train.trialIdx;
        pa.train.acc(i)      = cell2mat(varargin(find(strcmp(varargin, 'acc'))+1));
        pa.train.trainAcc    = mean(pa.train.acc);
        pa.train.stimVal     = pa.train.probeVals(i);
        pa.train.stimulusVals(i) = cell2mat(varargin(find(strcmp(varargin, 'stimulusValue'))+1));
        pa = computeTrainingThreshold(pa); 
        pa.stimVal = pa.train.stimVal;
    case 'computeThreshold' % call this after training to set starting point for testing
        pa = cell2mat(varargin(find(strcmp(varargin, 'model'))+1));
        pa.stimVal = pa.test.stimVal;
    case 'test'
        pa = cell2mat(varargin(find(strcmp(varargin, 'model'))+1));
        pa.test.min = pa.train.min;
        pa.test.max = pa.train.max;
        pa.test.trialIdx = pa.test.trialIdx + 1;
        i = pa.test.trialIdx;
        pa.test.acc(i) = cell2mat(varargin(find(strcmp(varargin, 'acc'))+1));
        pa.test.stimulusVals(i) = cell2mat(varargin(find(strcmp(varargin, 'stimulusValue'))+1));
        pa.test.testAcc    = mean(pa.test.acc);
        pa = updateTestingModel(pa);
        pa.stimVal = pa.test.stimVal;
    case 'plotTraining'
        pa = cell2mat(varargin(find(strcmp(varargin, 'model'))+1));
        [acc, aI] = sort(pa.train.acc);
        acc = acc';
        stimVals = pa.train.stimulusVals(aI)';
        n = ones(size(acc));
        [b,~,stats] = glmfit(stimVals,[acc n],'binomial','link','logit');
        %[b,~,stats] = glmfit(stimVals,[acc n],'binomial','link','logit','weights',w(aI));
        yfit = glmval(b,stimVals,'logit');
        [yfits, I] = sort(yfit);
        if b(2) < 0
            threshGuess = (log(pa.train.targetAcc/(1-pa.train.targetAcc)) + b(1)) / abs(b(2));
        else
            threshGuess = (log(pa.train.targetAcc/(1-pa.train.targetAcc)) + abs(b(1))) / b(2);
        end
        pa.train.threshGuessAtTargetAcc = threshGuess;
        figure;
        %plot(stimVals(I), acc(I)./n,'o',stimVals(I),yfits./n,'-','LineWidth',2, threshGuess,pa.train.targetAcc,'*');
        plot(stimVals(I), acc(I)./n,'o',stimVals(I),yfits./n,'-','LineWidth',2);
        hold on;
        plot(threshGuess,pa.train.targetAcc,'*k');
        x = [threshGuess threshGuess];
        y = [0 pa.train.targetAcc];
        line(x,y,'Color','red','LineStyle','--')
        x = [0 threshGuess];
        y = [pa.train.targetAcc pa.train.targetAcc];
        line(x,y,'Color','red','LineStyle','--')
        hold off;
        
    case 'plotTesting' %includes data from training plot too!
        pa = cell2mat(varargin(find(strcmp(varargin, 'model'))+1));
        testingFactor = 10;
        CI = 0.95;
        trainAcc = pa.train.acc;
        testAcc = pa.test.acc;
        allAcc = [trainAcc testAcc]; 
        %allAcc = [testAcc];
        [acc, aI] = sort(allAcc);
        trainVals = pa.train.stimulusVals;
        testVals = pa.test.stimulusVals;
        allVals = [trainVals testVals];
        testMiss = find(testAcc == 0);
        testHit = find(testAcc == 1);
        testW = sqrt(1:length(testAcc))+testingFactor;
        %testW = ones(size(testAcc));
        %testW(testMiss) = hitWeightFactor;
        %testW(testHit) = hitWeightFactor;
        w = [ones(size(trainVals)) testW];
        w = w';
        %w = ones(size(allAcc));
        %allVals = [testVals];
        acc = acc';
        stimVals = allVals(aI)';
        n = ones(size(acc));
        %[b,~,stats] = glmfit(stimVals,[acc n],'binomial','link','logit');
        [b,~,stats] = glmfit(stimVals,[acc n],'binomial','link','logit','weights',w(aI)); % with weights
        %[b,~,stats] = glmfit(stimVals,[acc n],'binomial','link','logit'); % no weights 
        yfit = glmval(b,stimVals,'logit'); %only needed if plotting
        [yfits, I] = sort(yfit); %only needed if plotting
        threshGuess = (log(pa.test.targetAcc/(1-pa.test.targetAcc)) + abs(b(1))) / b(2);
        figure;
        plot(stimVals(I), acc(I)./n,'o',stimVals(I),yfits./n,'-','LineWidth',2);
        hold on;
        plot(threshGuess,pa.test.targetAcc,'*k');
        if CI >0.5
            z = norminv([(1-CI)/2 (CI-((1-CI)/2))]);
        else
            z = norminv([(CI-((1-CI)/2)) (1-CI)/2]);
        end
        %padj ± z * sqrt(padj(1- padj)/nadj)
        upperCI = b+(z(2)*stats.se);
        lowerCI = b-(z(2)*stats.se);
        %upperCI = b+(sqrt(length(allVals))*stats.se);
        %lowerCI = b-(sqrt(length(allVals))*stats.se);
        yfitUpper = glmval(upperCI,stimVals,'logit'); %only needed if plotting
        yfitLower = glmval(lowerCI,stimVals,'logit');
        [yfitsUpper, upperI] = sort(yfitUpper); %only needed if plotting
        [yfitsLower, lowerI] = sort(yfitLower);
        plot(stimVals(upperI),yfitsUpper./n,'b:','LineWidth',2);
        plot(stimVals(lowerI),yfitsLower./n,'b:','LineWidth',2);
        upperGuess = (log(pa.test.targetAcc/(1-pa.test.targetAcc)) + abs(upperCI(1))) / upperCI(2);
        lowerGuess = (log(pa.test.targetAcc/(1-pa.test.targetAcc)) + abs(lowerCI(1))) / lowerCI(2);
        plot(upperGuess,pa.test.targetAcc,'*k');
        plot(lowerGuess,pa.test.targetAcc,'*k');
        hold off;
        
    case 'outputEstimate'
        
    otherwise
        error('command: %s is not recognized by the psychAdapt function', cmd);       
end

end %end psychAdapt


function pa = updateTestingModel(pa)
%hitWeightFactor = 10;
%missWeightFactor = hitWeightFactor - (hitWeightFactor*pa.test.targetAcc);
CI = 0.95;
CIspread = 5;
testingFactor = 10;
trainAcc = pa.train.acc;
testAcc = pa.test.acc;
allAcc = [trainAcc testAcc];
[acc, aI] = sort(allAcc);
trainVals = pa.train.stimulusVals;
testVals = pa.test.stimulusVals;
allVals = [trainVals testVals];
testMiss = find(testAcc == 0);
testHit = find(testAcc == 1);
testW = sqrt(1:length(testAcc))+testingFactor;
%testW = ones(size(testAcc));
%testW(testMiss) = hitWeightFactor;
%testW(testHit) = hitWeightFactor;
w = [ones(size(trainVals)) testW];
w = w';
acc = acc';
stimVals = allVals(aI)';
n = ones(size(acc));
[b,~,stats] = glmfit(stimVals,[acc n],'binomial','link','logit','weights',w(aI));
pa.test.threshGuess = (log(pa.test.targetAcc/(1-pa.test.targetAcc)) + abs(b(1))) / b(2);
%pa.test.sdGuess = pa.test.threshGuess * 0.5;
if CI >0.5
    z = norminv([(1-CI)/2 (CI-((1-CI)/2))]);
else
    z = norminv([(CI-((1-CI)/2)) (1-CI)/2]);
end
%padj ± z * sqrt(padj(1- padj)/nadj) %possible other method
upperCI = b+(z(2)*stats.se);
lowerCI = b-(z(2)*stats.se);
pa.test.upperGuess = (log(pa.test.targetAcc/(1-pa.test.targetAcc)) + abs(upperCI(1))) / upperCI(2);
pa.test.lowerGuess = (log(pa.test.targetAcc/(1-pa.test.targetAcc)) + abs(lowerCI(1))) / lowerCI(2);
%R = normrnd(pa.test.threshGuessAtTargetAcc, pa.test.sdGuess, [1 pa.train.probeLength]);
%harderStims = R(R<pa.test.threshGuessAtTargetAcc);
%easierStims = R(R>pa.test.threshGuessAtTargetAcc);
%R = (pa.test.lowerGuess-pa.test.upperGuess).*rand(pa.train.probeLength,1) + pa.test.upperGuess;
% R = linspace(pa.test.upperGuess,pa.test.lowerGuess,pa.train.probeLength);
% harderStims = R(R<pa.test.threshGuess);
% easierStims = R(R>pa.test.threshGuess);
easierStims = linspace(pa.test.lowerGuess,pa.test.threshGuess,CIspread);
harderStims = linspace(pa.test.threshGuess,pa.test.upperGuess,CIspread);
%stimRange = linspace(pa.test.upperGuess,pa.test.lowerGuess,CIspread);


% if testAcc(end) == 0
%     pa.test.stimVal = easierStims(randi([1 length(easierStims)]));
% else
%     pa.test.stimVal = harderStims(randi([1 length(harderStims)]));
% end

%pa.test.stimVal = stimRange(randi([1 length(stimRange)]));
%pa.test.stimVal = pa.test.threshGuess;
if pa.test.testAcc < pa.test.targetAcc
    %pa.test.stimVal = pa.test.lowerGuess;
    pa.test.stimVal = easierStims(randi([1 length(easierStims)]));
else
    %pa.test.stimVal = pa.test.upperGuess;
    pa.test.stimVal = harderStims(randi([1 length(harderStims)]));
end
if pa.test.stimVal > pa.test.max
    pa.test.stimVal = pa.test.max;
end
if pa.test.stimVal < pa.test.min
    pa.test.stimVal = pa.test.min;
end
end %end updateModel


function pa = computeTrainingThreshold(pa)
[acc, aI] = sort(pa.train.acc);
acc = acc';
stimVals = pa.train.stimulusVals(aI)';
n = ones(size(acc));
b = glmfit(stimVals,[acc n],'binomial','link','logit');
yfit = glmval(b,stimVals,'logit');
pa.test.stimVal = (log(pa.test.targetAcc/(1-pa.test.targetAcc)) + abs(b(1))) / b(2);
end %end computeTrainingThreshold


