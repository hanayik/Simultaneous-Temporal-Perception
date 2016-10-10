function  [A] = SetUpAdaptiveStimLevel(method,startingStimlevel,stimMin,stimMax,step,minStep,maxStep)
%This function is designed to set up a particular adaptive thresholding
%method specified in the [method] input argument. method must be a string.
% method : 'PEST', 'PEST1', 'PEST2', 'PEST3' 
%          n.b. append number for desired accuracy 'PEST1'=50.0%, 'PEST2'
%          (default)=66.7% (70.7%),'PEST3'=75%(79.4%) (SEE LEVITT 1971)
% startingStimlevel : initial threshold
% stimMin : minimum possible threshold
% stimMax : maximum possible threshold
% step : initial adjustment between trials
% minStep : minimum adjustment between trials
% maxStep : maximum adjustment between trials
%
%EXAMPLE - PEST, estimate 66.7% accuracy
%     stimMin = 1; %e.g. we can not show a stimulus for less than one screen refresh
%     stimStart = 40; %starting threshold will be 40 screen refreshes
%     stimMax = 60; %never show a stimulus for more than 60 screen refreshes
%     minStep = 1; %minimum adjustment size is one screen refresh
%     startStep = 12; %starting adjustment size is 12 screen refreshes
%     maxStep = 16; %largest adjustement size
%     A = SetUpAdaptiveStimLevel('PEST2',stimStart,stimMin,stimMax,startStep, minStep, maxStep);	
%     for trial = 1 : 20
%         accuracy = input(['Does the participant detect a stimulus of intensity ' num2str(A.stimlevel) '? Y/N [Y]:'],'s');
%         accuracy = strcmpi(accuracy,'Y'); %logical true or false
%         A = CalculateStimLevel(A, accuracy);
%     end


%%%% QUEST WILL BE ADDED IN THE FUTURE %%%%%%% 

% if strncmpi(method,'QUEST',5) == true
%     if isempty(which('QuestUpdate')), fprintf('Error: install PsychToolbox for QUEST\n'); end;
%     if ~exist('gamma','var'), error('Not enough arguments for QUEST'); end;
%     if ~exist('grain','var'), grain = []; end;
%     if ~exist('range','var'), range = []; end;
%     %call on QuestCreate function provided by Psychtoolbox
%     %QuestCreate will also do the input checking for us
%     %setup Quest threshold estimating for simultaneity judgement (sj)
%     if ~isempty(strfind(method,'1'))
%         pThreshold=0.50;%probability threshold
%     elseif ~isempty(strfind(method,'3'))
%         pThreshold=0.707;%probability threshold
%     else
%         pThreshold=0.794;%probability threshold
%     end
%     A=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain);%make the 'A' structure for quest
%     A.stimlevel = QuestQuantile(A);
%     A.method = method;
%     A.stimMin = stimMin;
%     A.stimMax = stimMax;
%     return;
% end

if strncmpi(method,'PEST',4) == true 
    if nargin > 7
        fprintf('PEST does not use all the arguments you provide');
    end    
    A.stepSize = step;
    A.origStepSize = step;
    A.stimlevel = startingStimlevel;
    if ~exist('minStep','var'), minStep = step / 8; end;
    if ~exist('maxStep','var'), maxStep = step * 2; end;
    
    A.minStep = minStep;
    A.maxStep = maxStep;
    if maxStep < minStep * 8
       fprintf('Warning: maxStep should be at least x8 minStep!\n');
    end
    A.maxStep = maxStep;
    if step < minStep || step > maxStep 
       fprintf('Warning: step should be between min and max step!\n');
    end
else
    error('Invalid method input');
end
%set values used by ALL methods:
A.method = method;
A.trialCount = 1;
A.numReverse = 0; %number of reversals 
A.numRun = 0; %number of times currect accuracy was repeated
A.numRunOK = 0; %number of repeated correct responses, not same as numRun due to PEST rule 4
A.stimMin = stimMin;  
A.stimMax = stimMax;
A.prevAccuracy = -1; %first trial - prior trial neither correct or incorrect
if ~isempty(strfind(method,'1'))
   A.numOKToMakeHarder = 1; 
elseif ~isempty(strfind(method,'3'))
  A.numOKToMakeHarder = 3;  
else
  A.numOKToMakeHarder = 2;   
end
    