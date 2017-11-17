function fmriStats(subj)
delete 'diary';
diary on;
disp('#############################################################');
disp('##################### latest run below: #####################');

%try
	% add spm12 to path
	addpath('/home/hanayik/spm12/');
	disp('added spm12 to path');

	% subj is the full path to the subj folder (including the folder name)
	disp(['Running stats on: ' subj]);

	spm_get_defaults('cmdline',true);
    nii_block_TBV_statsOnly(subj)
	diary off;
	quit;
%catch catchErr
%fprintf('MATLAB encountered an error. Check diary file.');
%diary off;
%quit;
%end % try
end % fmriStats
