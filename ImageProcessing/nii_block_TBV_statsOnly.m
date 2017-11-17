function nii_block_TBV_statsOnly(subj)
% Find fMRI1, and fMRI2 files
p.subjfolder = subj;
p.fmriname(1,:) = findFilesSub(subj,'wsucfMRI1','before');
p.fmriname(2,:) = findFilesSub(subj,'wsucfMRI2','before');
fmri1Onsets = load(findFilesSub(subj,'fmri1.mat','after'));
fmri2Onsets = load(findFilesSub(subj,'fmri2.mat','after'));
p.TRsec = 0.72; p.slice_order = 3; %interleaved ascending
p.phase =  ''; %phase image from fieldmap
p.magn = ''; %magnitude image from fieldmap
p.names{1} = 'SJ';
p.names{2} = 'CL';
p.names{3} = 'OR';
p.onsets{1,1} = fmri1Onsets.s.blockOnsetTime(strcmp(fmri1Onsets.s.tasks,'SJ')); %SJ
p.onsets{1,2} = fmri1Onsets.s.blockOnsetTime(strcmp(fmri1Onsets.s.tasks,'CL')); %CL
p.onsets{1,3} = fmri1Onsets.s.blockOnsetTime(strcmp(fmri1Onsets.s.tasks,'OR')); %OR
p.onsets{2,1} = fmri2Onsets.s.blockOnsetTime(strcmp(fmri2Onsets.s.tasks,'SJ')); %SJ
p.onsets{2,2} = fmri2Onsets.s.blockOnsetTime(strcmp(fmri2Onsets.s.tasks,'CL')); %CL
p.onsets{2,3} = fmri2Onsets.s.blockOnsetTime(strcmp(fmri2Onsets.s.tasks,'OR')); %OR
p.duration{1,1} = fmri1Onsets.s.blockDuration(strcmp(fmri1Onsets.s.tasks,'SJ'));
p.duration{1,2} = fmri1Onsets.s.blockDuration(strcmp(fmri1Onsets.s.tasks,'CL'));
p.duration{1,3} = fmri1Onsets.s.blockDuration(strcmp(fmri1Onsets.s.tasks,'OR'));
p.duration{2,1} = fmri2Onsets.s.blockDuration(strcmp(fmri2Onsets.s.tasks,'SJ'));
p.duration{2,2} = fmri2Onsets.s.blockDuration(strcmp(fmri2Onsets.s.tasks,'CL'));
p.duration{2,3} = fmri2Onsets.s.blockDuration(strcmp(fmri2Onsets.s.tasks,'OR'));
p.resliceMM = 2;
p.mocoRegress = true; %should motion parameters be included in statistics?
tic
stat_1st_levelSub(p);
fprintf('Processing required %g seconds\n', toc);








function [fullnameFolds, nameFolds]=subFolderSub(pathFolder,matchStr)
d = dir(fullfile(pathFolder,[matchStr '*']));
isub = [d(:).isdir];
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];
nameFolds = sort(nameFolds);
for i = 1:length(nameFolds)
    fullnameFolds{i} = fullfile(pathFolder,nameFolds{i});%#ok
end
%end subFolderSub()

function matchedFile = findFilesSub(pathFolder,fileID,wildcardtype)
if strcmpi(wildcardtype,'before')
    d = dir(fullfile(pathFolder,[fileID '*']));
elseif strcmpi(wildcardtype,'after')
    d = dir(fullfile(pathFolder,['*' fileID]));
end
matchedFile = fullfile(pathFolder,d(1).name);
%end findFilesSub