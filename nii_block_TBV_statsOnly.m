function nii_block_TBV_statsOnly
% #1. merge spin echo images (AP then PA) into one file
% fslmerge -t bothSpinEchoFieldMap SpinEchoFieldMap_AP_TBV002.nii SpinEchoFieldMap_PA_TBV002.nii 
% 
% #2. run topup on combined SpinEcho image (started at 1:07pm ended 1:32pm (25min to run))
% topup --imain=bothSpinEchoFieldMap --datain=acqparams.txt --config=b02b0.cnf --out=topupResults --fout=myField --iout=ubothSpinEchoFieldMap --verbose
% 
% #3. use matlab nii_replicate_vols to make AP image with as many vols as PA image
% 
% #4. make zero image of same size as image to be distorted from tRest_AP
% fslmaths tRest_AP_TBV002 -mul 0 ztRest_AP_TBV002
% 
% #5. apply topup (linear interp may be faster, but check results for quality) (started 1:36pm end 1:37pm) 
% applytopup --imain=ztRest_AP_TBV002,Rest_PA_TBV002 --datain=acqparams.txt --inindex=1,4 --method=jac --interp=trilinear --topup=topupResults --out=uRest_PA_TBV002
% 
% #6. apply topup (linear interp may be faster, but check results for quality) (started 1:40 end 1:50) 
% applytopup --imain=ztRest_AP_TBV002,Rest_PA_TBV002 --datain=acqparams.txt --inindex=1,4 --method=jac --topup=topupResults --out=uuRest_PA_TBV002
if ~exist('baseDir','var')
    baseDir = fullfile(fileparts(mfilename('fullpath'))); %start at the path of this function
end
disp(baseDir)
[fullsubjDirs,subjNames] = subFolderSub(baseDir,'T000'); %list participant folders
fprintf('Processing %d folders (subjects) in %s\n', numel(fullsubjDirs), baseDir);
statsOnly = true;
for i = 1:size(fullsubjDirs,2) %loop through all participant folders
    % Find T1, Rest, fMRI1, and fMRI2 files
    p.subjfolder = fileparts(fullsubjDirs{i});
    p.subjname = subjNames{i};
    p.fmriname(1,:) = findFilesSub(fullsubjDirs{i},'wsucfMRI1','before');
    p.fmriname(2,:) = findFilesSub(fullsubjDirs{i},'wsucfMRI2','before');
    fmri1Onsets = load(findFilesSub(fullsubjDirs{i},'fmri1.mat','after'));
    fmri2Onsets = load(findFilesSub(fullsubjDirs{i},'fmri2.mat','after'));
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
    %warning('nii:warncode', 'resliceMM set to %g (should be >=3 for real analyses', p.resliceMM);
    p.mocoRegress = true; %should motion parameters be included in statistics?
    tic
    stat_1st_levelSub(p);
    fprintf('Processing required %g seconds\n', toc);
end
%save_to_base(1)
return
%sample analysis of a block design








function [fullnameFolds, nameFolds]=subFolderSub(pathFolder,matchStr)
d = dir(fullfile(pathFolder,[matchStr '*']));
%save_to_base(1)
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