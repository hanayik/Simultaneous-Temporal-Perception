function A = simpleStair2(cmd, varargin)
% cmd should be one of the following:
%   
%   'create'
%   'update'
%   
% variable inputs should be in pairs, and can be any of the following:
%
%   'data',         structure (contains 'A')
%   'initialVal',   number
%   'minVal',       number
%   'maxVal',       number
%   'stepSize',     number
%   'targetAcc',    number (0..1)
%   'accuracy',     number (0..1)
%   'invert',       logical (true, false) default is false
%   'name',         string 'optional name of this staircase'
%
%   usage:
%   simpleStair('create', 'initialVal', 0.5 'minVal', 0, 'maxVal', 3, 'stepSize', 0.25, 'name', 'SJ')


A = [];
initialVal = [];
minVal = [];
maxVal = [];
stepSize = [];
targetAcc = [];
accuracy = [];
invert = [];
name = '';
if (~isempty(varargin)) % if varargin contains variables then parse them
    dataInd = find(strcmp(varargin, 'data')); 
    if (~isempty(dataInd)) 
        A = varargin{dataInd+1}; 
    end
    initialValInd = find(strcmp(varargin, 'initialVal')); 
    if (~isempty(initialValInd))
        initialVal = varargin{initialValInd+1}; 
    end
    minValInd = find(strcmp(varargin, 'minVal')); 
    if (~isempty(minValInd))
        minVal = varargin{minValInd+1}; 
    end
    maxValInd = find(strcmp(varargin, 'maxVal')); 
    if (~isempty(maxValInd))
        maxVal = varargin{maxValInd+1}; 
    end
    stepSizeInd = find(strcmp(varargin, 'stepSize')); 
    if (~isempty(stepSizeInd))
        stepSize = varargin{stepSizeInd+1}; 
    end
    targetAccInd = find(strcmp(varargin, 'targetAcc')); 
    if (~isempty(targetAccInd))
        targetAcc = varargin{targetAccInd+1}; 
    end
    accuracyInd = find(strcmp(varargin, 'accuracy')); 
    if (~isempty(accuracyInd))
        accuracy = varargin{accuracyInd+1}; 
    end
    invertInd = find(strcmp(varargin, 'invert')); 
    if (~isempty(invertInd))
        invert = varargin{invertInd+1}; 
    end
    nameInd = find(strcmp(varargin, 'name')); 
    if (~isempty(nameInd))
        name = varargin{nameInd+1}; 
    end
    
    
end
switch cmd
    case 'create'
        if (~isempty(A)); 
            A = struct;
            warning('When creating the staircase, the data argument is not needed. Setting to empty now');
        end;
        if (~isempty(initialVal)); A.initialVal = initialVal; else error('must give initialVal'); end;
        if (~isempty(minVal)); A.minVal = minVal; else error('must give minVal'); end;
        if (~isempty(maxVal)); A.maxVal = maxVal; else error('must give maxVal'); end;
        if (~isempty(stepSize)); A.stepSize = stepSize; else error('must give stepSize'); end;
        if (~isempty(targetAcc)); A.targetAcc = targetAcc; else A.targetAcc = 0.7; end;
        if (~isempty(accuracy)); A.accuracy = accuracy; end;
        if (~isempty(invert)); A.invert = invert; else A.invert=0; end;
        if (~isempty(name)); A.name = name; end;
        if (A.stepSize > 1); A.stepSize = A.stepSize / 100; end; %if on 0-100 scale then convert to 0-1 scale
        A.numReversals = 0;
        A.numCorrect = 0;
        A.bigStepSize = A.stepSize * 2;
        A.smallStepSize = A.stepSize / 2;
        A.trialInd = 0;
        A.allTrialAcc = [];
        A.stimulusVal = A.initialVal;
        A.allStimVals = [];
        A.range = A.maxVal - A.minVal;
        A.step = A.range * A.stepSize;
        A.bigStep = A.range * A.bigStepSize;
        A.smallStep = A.range * A.smallStepSize;
        disp('created!');
        
    case 'update'
        A.trialInd = A.trialInd + 1;
        if (isempty(accuracy)); error('must give accuracy for this trial!'); end;
        if (isempty(A)); error('must supply the staircase structure from simpleStair(''create'')'); end;
        A.allTrialAcc = [A.allTrialAcc accuracy]; %grow array with new acc data
        A.completedTrials = length(A.allTrialAcc);
        A.totalAcc = mean(A.allTrialAcc);
        makeHarder = accuracy; %figure out what to do for next trial
        if (makeHarder)
            A.numCorrect = A.numCorrect + 1;
            if (A.numCorrect > 1) % if two correct responses then make harder
                if A.numReversals < 5
                    %A.stimulusVal = A.stimulusVal - A.bigStep;
                    A.stimulusVal = A.stimulusVal - A.step;
                elseif A.numReversals >= 5 & A.numReversals < 10 %#ok
                    A.stimulusVal = A.stimulusVal - A.step;
                elseif A.numReversals >= 11
                    %A.stimulusVal = A.stimulusVal - A.smallStep;
                    A.stimulusVal = A.stimulusVal - A.step;
                end
            end
            if A.numCorrect >=2
                A.numCorrect = 0;
            end
        else
            A.numReversals = A.numReversals + 1;
            if A.numReversals < 5
                %A.stimulusVal = A.stimulusVal + A.bigStep;
                A.stimulusVal = A.stimulusVal + A.step;
            elseif A.numReversals >= 5 & A.numReversals < 10 %#ok
                A.stimulusVal = A.stimulusVal + A.step;
            elseif A.numReversals >= 11
                %A.stimulusVal = A.stimulusVal + A.smallStep;
                A.stimulusVal = A.stimulusVal + A.step;
            end
            A.numCorrect = 0;
        end 
        if (A.stimulusVal < A.minVal)
            A.stimulusVal = A.minVal;
        end
        if (A.stimulusVal > A.maxVal)
            A.stimulusVal = A.maxVal;
        end
        %A.trialInd = length(A.allTrialAcc);
        A.allStimVals = [A.allStimVals A.stimulusVal];
        %disp(['total acc: ' num2str(A.totalAcc)])
        %disp('updated!');
    otherwise
        error('command: %s, is not a valid command for this function', cmd)
end
end