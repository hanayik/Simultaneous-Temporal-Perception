function [A] = CalculateStimLevel(A,accuracy,inverted)
%
%This function is designed to be called after 'SetUpAdaptiveThreshold'
%and is to accompany PEST adaptive thresholding methods.
%
%A : is a structure output from 'SetUpAdaptiveStimLevel'
%accuracy : true/false for correct, incorrect response (accuracy comes
%after a stimulus in a trial loop)
%inverted : [optional] true/false: does correct response make stimulus level smaller or larger
%
%%%%% QUEST WILL BE ADDED IN THE FUTURE %%%%%%
% if strncmpi(A.method,'QUEST',5)
%     A = QuestUpdate(A,A.stimlevel,accuracy);
%     A.stimlevel = QuestQuantile(A);
%     %bound all values
%     if A.stimlevel < A.stimMin %set lower limit of this threshold
%         A.stimlevel = A.stimMin;
%     end
%     if A.stimlevel > A.stimMax %set upper limit of this threshold
%         A.stimlevel = A.stimMax;
%     end
%     A.trialCount = A.trialCount+1;
%     return;
% end
A.accuracy(A.trialCount) = accuracy;
if ~exist('inverted','var')
    inverted = false;
end
A.allStimlevels(A.trialCount) = A.stimlevel;
if accuracy
    A.numRunOK = A.numRunOK + 1;
    if A.numRunOK < A.numOKToMakeHarder
        A.trialCount = A.trialCount + 1;
        return; %not enough consecutive correct responses to make harder
    end

else
    A.numRunOK = 0; %error
end
if (A.trialCount > 1) && (A.prevAccuracy ~= accuracy)
    A.numReverse = A.numReverse + 1; %responses switched between accurate and inaccurate
    if A.numRun >= 3
        A.numRun = -1; %rule 4
    else
        A.numRun = 0;
    end
end
if (A.trialCount > 1) && (A.prevAccuracy == accuracy)
    A.numRun = A.numRun + 1; %responses switched between accurate and inaccurate
end

if (accuracy && ~inverted) || (~accuracy && inverted)
    makeSmaller = true;
else
    makeSmaller = false;
end
%PEST sequence follows
%RULE 1: HALVE stepsize after each reversal
%RULE 2: repeated step in same direction uses same step size EXCEPT
%RULE 3: third or more repeated step and each subsequent step DOUBLE in size
%RULE 4: a reversal following DOUBLING requires extra step in same direction to double
%RULE 5: maximum step size is defined, at least 8 times min step size
if (A.trialCount > 1) && (A.prevAccuracy ~= accuracy) %reversal
    A.stepSize = A.stepSize / 2; %rule 1: HALVE stepsize
end
if (A.numRun >= 3) %repeated responses of same type
    A.stepSize = A.stepSize * 2; %rule 3: DOUBLE stepsize
end
if A.stepSize < A.minStep
    A.stepSize = A.minStep;
end
if A.stepSize > A.maxStep
    A.stepSize = A.maxStep;
end

if makeSmaller
    A.stimlevel = A.stimlevel - A.stepSize; %decrease stim level (make easier)
else
    A.stimlevel = A.stimlevel + A.stepSize; %increase stim level (make easier)
end


%bound all values
if A.stimlevel < A.stimMin %set lower limit of this threshold
    A.stimlevel = A.stimMin;
end
if A.stimlevel > A.stimMax %set upper limit of this threshold
    A.stimlevel = A.stimMax;
end
A.prevAccuracy = accuracy;
A.trialCount = A.trialCount + 1;

