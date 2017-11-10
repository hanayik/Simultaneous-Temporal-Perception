function stat_1st_levelSub (s)
% first level statistics
%  basefmriname : names of 4D fMRI data (one per session)
%  kTR : repeat time in seconds
%  s : structure with statistics
%   
%Examples
% stat_1st_blockSub('swa','fMRI.nii', 2)
% stat_1st_blockSub('swa',strvcat('fMRI1.nii','fMRI2.nii'), 2)
kTR = s.TRsec;
basefmriname = s.fmriname;
if ~isfield(s,'mocoRegress'), s.mocoRegress = false; end;
nCond = numel(s.names);
if nCond ~= size(s.onsets,2)
    error('"s.names" specifies %d conditions while "s.onsets" specifies %d',  nCond, size(s.onsets,2));
end
nSessions = size(s.onsets,1);
fprintf('Experiment has %d sessions with %d conditions\n',nSessions,nCond);
if nSessions ~= size(basefmriname,1)
    error('There must be %d sessions of fMRI data', nSessions);
end    
%prepare SPM
if exist('spm','file')~=2; fprintf('%s requires SPM\n',which(mfilename)); return; end;
spm('Defaults','fMRI');
spm_jobman('initcfg'); % useful in SPM8 only
clear matlabbatch
%get files if not specified....
if ~exist('kTR','var') || (kTR <= 0)
    error('%s requires the repeat-time (TR) in seconds', mfilename);
end 
%next make sure each image has its full path
fmriname = [];
for ses = 1:nSessions
    [pth,nam,ext] = spm_fileparts( deblank (basefmriname(ses,:)));
    if isempty(pth)
        pth = pwd; 
    end;
    fmriname = strvcat(fmriname, fullfile(pth, [nam ext])); %#ok<REMFF1>
end
%next - generate output folder
if ~exist('statdirname','var') %no input: select fMRI file[s]
 [pth,nam] = spm_fileparts(deblank(fmriname(1,:)));
 statdirname = 'STATS';
 fprintf('Directory for SPM.mat file not specified - using folder named %s\n',statdirname);
end
predir = pwd;
%create new stat directory
if isempty(pth); pth=pwd; end;
statpth = fullfile(pth, statdirname);
if exist(statpth, 'file') ~= 7; mkdir(statpth); end;
fprintf(' SPM.mat file saved in %s\n',statdirname);
if (min([s.duration{:}]) > 2) && (max([s.duration{:}]) < 32); 
    hpf = mean([s.duration{:}]) * 4;
	temporalderiv = false;
	fprintf('Block design : using %.1fs high pass filter with no temporal derivative.\n',hpf);
else
    temporalderiv = true;
    hpf = 128;
	fprintf('Event-related design : using %.1fs high pass filter with a temporal derivative.\n',hpf);
end;
% MODEL SPECIFICATION
%--------------------------------------------------------------------------
clear matlabbatch
matlabbatch{1}.spm.stats.fmri_spec.dir = {statpth};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = kTR;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
for ses = 1:nSessions 
    %sesFiles = fmriname{ses};%getsesvolsSubSingle(fmriname, ses);
    sesFiles = getsesvolsSubSingle('', fmriname, ses);
    fprintf('Session %d has %d volumes\n',ses, length(sesFiles) );
    %sesFiles = getsesvolsSubSingle(basefmriname, ses);
    matlabbatch{1}.spm.stats.fmri_spec.sess(ses).scans = sesFiles;
    for c = 1:nCond
        matlabbatch{1}.spm.stats.fmri_spec.sess(ses).cond(c).name = deblank(char(s.names{c}));
        matlabbatch{1}.spm.stats.fmri_spec.sess(ses).cond(c).onset = cell2mat(s.onsets(ses, c));
        if numel(s.duration) == 1
            matlabbatch{1}.spm.stats.fmri_spec.sess(ses).cond(c).duration = s.duration{1};
        else
            matlabbatch{1}.spm.stats.fmri_spec.sess(ses).cond(c).duration = cell2mat(s.duration(ses, c));
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(ses).cond(c).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess(ses).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(ses).cond(c).orth = 1; %SPM12
    end
    matlabbatch{1}.spm.stats.fmri_spec.sess(ses).multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(ses).regress = struct('name', {}, 'val', {});
    if s.mocoRegress
        [p,n] = spm_fileparts(deblank(fmriname(ses,:)));
        pat = sprintf('*fMRI%d*.par',ses);
        possibilities = dir(fullfile(p,pat));
        motionFilePar = fullfile(p,possibilities(1).name);
        [p,n,ext] = fileparts(motionFilePar);
        motionFileTxt = fullfile(p,[n '.txt']); % copy to txt file for reading in
        copyfile(motionFilePar, motionFileTxt);
        pause(1);
        tbl = readtable(motionFileTxt);
        writetable(tbl,motionFileTxt,'Delimiter', '\t','WriteVariableNames',false);
        motionFile = motionFileTxt;
        %motionFile = fullfile(p, ['rp_', n(5:end), '.txt']);
        if ~exist(motionFile, 'file')
            error('Unable to find realign parameters for motion correction %s', motionFile);
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(ses).multi_reg = {motionFile};
    else
        matlabbatch{1}.spm.stats.fmri_spec.sess(ses).multi_reg = {''}; 
    end
    matlabbatch{1}.spm.stats.fmri_spec.sess(ses).hpf = hpf;
end
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
if temporalderiv
	matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [1 0];
else 
	matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
end
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8; %SPM12
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
% MODEL ESTIMATION
%--------------------------------------------------------------------------
matlabbatch{2}.spm.stats.fmri_est.spmmat = cellstr(fullfile(statpth,'SPM.mat'));
% INFERENCE
%--------------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.spmmat = cellstr(fullfile(statpth,'SPM.mat'));
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name    = 'Task>Rest';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec = ones(1,nCond);
nContrast = 1;
if nCond > 1
    for pos = 1: nCond
        for neg = 1: nCond
            if pos ~= neg
                nContrast = nContrast + 1;
                c = zeros(1,nCond);
                c(pos) = 1;
                c(neg) = -1;
                matlabbatch{3}.spm.stats.con.consess{nContrast}.tcon.convec = c;
                matlabbatch{3}.spm.stats.con.consess{nContrast}.tcon.name = [char(s.names{pos}) '>' char(s.names{neg})];
            end % j ~= i
        end %for j
    end %for i
end % > 1 conditions
if isfield(s,'statAddSimpleEffects') && s.statAddSimpleEffects
    for pos = 1: nCond
        nContrast = nContrast + 1;
        c = zeros(1,nCond);
        c(pos) = 1;
        matlabbatch{3}.spm.stats.con.consess{nContrast}.tcon.convec = c;
        matlabbatch{3}.spm.stats.con.consess{nContrast}.tcon.name = char(s.names{pos}) ;
    end
end
if temporalderiv %zero pad temporal derivations
    for c = 1 : nContrast
        for cond = 1 : nCond
            v = matlabbatch{3}.spm.stats.con.consess{c}.tcon.convec;
            c2 = cond * 2;
            v = [v(1:(c2-1)) 0 v(c2:end)];
            matlabbatch{3}.spm.stats.con.consess{c}.tcon.convec = v;
            
        end
    end
end
if s.mocoRegress %add 6 nuisance regressors for motion paramets (rotation + translation]
    for c = 1 : nContrast
    	 matlabbatch{3}.spm.stats.con.consess{c}.tcon.convec = [ matlabbatch{3}.spm.stats.con.consess{c}.tcon.convec  0 0 0 0 0 0];
    end  
end
if (nSessions > 1) %replicate contrasts for each session
    for c = 1 : nContrast
        v = matlabbatch{3}.spm.stats.con.consess{c}.tcon.convec;
        for s = 2: nSessions
         matlabbatch{3}.spm.stats.con.consess{c}.tcon.convec = [matlabbatch{3}.spm.stats.con.consess{c}.tcon.convec v];
        end
    end
end
spm_jobman('run',matlabbatch);
cd(predir); %return to starting directory...
%end stat_1st_levelSub()

function [sesvols] = getsesvolsSubSingle(prefix, fmriname, session)
%* Load all fMRI images from single sessions
[pth,nam,ext,vol] = spm_fileparts( deblank (fmriname(session,:))); %#ok<*NASGU>
sesname = fullfile(pth,[prefix, nam, ext]);
hdr = spm_vol(sesname);
nvol = length(hdr);
if (nvol < 2), fprintf('Error 4D fMRI data required %s\n', sesname); return; end;
sesvols = cellstr([sesname,',1']);
for vol = 2 : nvol
    sesvols = [sesvols; [sesname,',',int2str(vol)]  ]; %#ok<AGROW>
end;
%end getsesvolsSubSingle()