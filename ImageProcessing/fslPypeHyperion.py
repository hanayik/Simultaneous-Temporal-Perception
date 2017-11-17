import os
import subprocess
import time
import shutil
import sys
import glob
from subprocess import call

# this subj
if (len(sys.argv) < 2):
    print("Exiting. No subject folder given")
    sys.exit()
else:
    thisSubj  = sys.argv[1]

# *************************************************
# import FSL module (if using on Hyperion cluster)
# make sure your .bash_profile has "module load fsl" (no quotes) in it so that
# fsl is loaded on every login automatically on the cluster
# *************************************************
# on macbook, or Hyperion?
STUDY = "Timing"
macbook = '/Users/thanayik'
hyperion = '/home/hanayik'
HOMEDIR = os.environ['HOME']
if (HOMEDIR == macbook):
    STUDYDIR 	= os.path.join(os.sep, "Volumes", "FAT1000", STUDY) #does not have trailing slash
else:
    STUDYDIR 	= os.path.join(os.sep, "data", "userdata", "hanayik", STUDY) #does not have trailing slash
# set up some constants
#STUDYDIR 	    = os.path.join(os.sep, "Volumes", "FAT1000", STUDY) #does not have trailing slash
FSLDIR 		    = os.environ['FSLDIR']
TOPUPPARAMS     = os.path.join(STUDYDIR, 'topupParams.txt')
TOPUPINDEX      = '4'
TOPUPCONFIG     = 'b02b0.cnf'
SEECHOSPACING   = 0.0000725
PEDIR           = '-y'
SUBJDIRS        = []
SMOOTHMM        = 5
STANDARD2mmBRAIN= os.path.join(FSLDIR,"data","standard","MNI152_T1_2mm_brain.nii.gz")
DOSTATS         = 1

# common FSL commands
bet 		= os.path.join(FSLDIR, 'bin', 'bet')
flirt 		= os.path.join(FSLDIR, 'bin', 'flirt')
fslmaths 	= os.path.join(FSLDIR, 'bin', 'fslmaths')
topup       = os.path.join(FSLDIR, 'bin', 'topup')
applytopup  = os.path.join(FSLDIR, 'bin', 'applytopup')
fslmerge    = os.path.join(FSLDIR, 'bin', 'fslmerge')
mcflirt     = os.path.join(FSLDIR, 'bin', 'mcflirt')
fast        = os.path.join(FSLDIR, 'bin', 'fast')
epireg      = os.path.join(FSLDIR, 'bin', 'epi_reg')
applyxfm4D  = os.path.join(FSLDIR, 'bin', 'applyxfm4D')
convert_xfm = os.path.join(FSLDIR, 'bin', 'convert_xfm')

print('FSLDIR: ' + FSLDIR)
print('HOMEDIR: ' + HOMEDIR)
print("STUDYDIR: " + STUDYDIR)
subj = os.path.join(STUDYDIR, thisSubj)
# list files used for processing
print("Raw files in " + subj + ": ")
fmri1 = glob.glob(os.path.join(subj, 'fMRI1_*.nii'))
fmri2 = glob.glob(os.path.join(subj, 'fMRI2_*.nii'))
T1 = glob.glob(os.path.join(subj, 'T1_*.nii'))
seAP = glob.glob(os.path.join(subj, 'SpinEchoFieldMap_AP_*.nii'))
sePA = glob.glob(os.path.join(subj, 'SpinEchoFieldMap_PA_*.nii'))
SBref1 = glob.glob(os.path.join(subj, 'SBref1_*.nii'))
SBref2 = glob.glob(os.path.join(subj, 'SBref2_*.nii'))
############################################################################
# check files
if not(fmri1):
    print("Cannot find fMRI1 file. Aborting processing this subject now...")
    sys.exit()
if not(fmri2):
    print("Cannot find fMRI2 file. Aborting processing this subject now...")
    sys.exit()
if not(T1):
    print("Cannot find T1 file. Aborting processing this subject now...")
    sys.exit()
if not(seAP):
    print("Cannot find seAP file. Aborting processing this subject now...")
    sys.exit()
if not(sePA):
    print("Cannot find sePA file. Aborting processing this subject now...")
    sys.exit()
if not(SBref1):
    print("Cannot find SBref1 file. Aborting processing this subject now...")
    sys.exit()
if not(SBref2):
    print("Cannot find SBref2 file. Aborting processing this subject now...")
    sys.exit()
fmri1 = fmri1[0]
print(fmri1)
fmri2 = fmri2[0]
print(fmri2)
T1 = T1[0]
print(T1)
seAP = seAP[0]
print(seAP)
sePA = sePA[0]
print(sePA)
SBref1 = SBref1[0]
print(SBref1)
SBref2 = SBref2[0]
print(SBref2)
sys.stdout.flush()
############################################################################
# 1). merge spin echo scans together
#fslmerge -t mergedSpinEcho SpinEchoFieldMap_AP_T001.nii SpinEchoFieldMap_PA_T001.nii
mSE = os.path.join(subj,"mSE.nii") # 'm' for 'merged spin echo'
if not(os.path.isfile(mSE)): #only run if expected output file does not exist
    cmd = [fslmerge, "-t", mSE, seAP, sePA]
    print("Running: fslmerge...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("1). FSLMERGE: file " + mSE + " exists already, not overwriting")
    sys.stdout.flush()
############################################################################
# 2). run topup on merged spin echo image
# topup --imain=mergedSpinEcho.nii.gz --datain=topupParams.txt --config=b02b0.cnf --out=topupFile --iout=uSpinEcho
umSE = os.path.join(subj, "u"+os.path.basename(mSE)) # 'u'ndistorted spin echo images
tupOutPrefix = os.path.join(subj,'tup') #'tup'
if not(os.path.isfile(umSE)): #only run if expected output file does not exist
    cmd = [topup, "--imain=" + mSE, "--datain=" + TOPUPPARAMS, "--config=" + TOPUPCONFIG, "--out=" + tupOutPrefix, "--iout=" + umSE]
    print("Running: topup (might take a long time)...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("2). TOPUP: file " + umSE + " exists already, not overwriting")
    sys.stdout.flush()
############################################################################
# 3). make mean ('a') spin echo file from undistorted spin echos
# fslmaths uSpinEcho.nii -Tmean meanuSpinEcho.nii
aumSE = os.path.join(subj, "a"+os.path.basename(umSE)) # 'a'veraged and 'u'ndistorted spin echo images
if not(os.path.isfile(aumSE)): #only run if expected output file does not exist
    cmd = [fslmaths, umSE, "-Tmean", aumSE, "-odt", "short"]
    print("Running: fslmaths...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("3). FSLMATHS: file " + aumSE + " exists already, not overwriting")
    sys.stdout.flush()
############################################################################
# 4). brain extract T1 structural image
# bet T1.nii bT1.nii -R
bT1 = os.path.join(subj, "b"+os.path.basename(T1)) # 'b'rain extrated T1
b = os.path.basename(bT1)
n = os.path.splitext(b)[0]
e = os.path.splitext(b)[1]
brainMask = os.path.join(subj, n+"_mask"+e)
if not(os.path.isfile(bT1)): #only run if expected output file does not exist
    cmd = [bet, T1, bT1, "-R","-m"] # -R for robust extraction (iterates several times)
    print("Running: bet...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("4). BET: file " + bT1 + " exists already, not overwriting")
    sys.stdout.flush()

############################################################################
# 5). run segmentaion and bias correction on T1
# fast -t 1 --segments -b -B --out iT1
ibT1 = os.path.join(subj, "ibT1_restore.nii")
T1biasField = os.path.join(subj, "ibT1_bias.nii")
iOutPrefix = os.path.join(subj,'ibT1')
if not(os.path.isfile(ibT1)): #only run if expected output file does not exist
    cmd = [fast, "-t", "1", "--segments", "-p", "-b", "-B", "-o", iOutPrefix, bT1]
    print("Running: fast segmentation...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("5). FAST: file " + ibT1 + " exists already, not overwriting")
    sys.stdout.flush()
wmseg = glob.glob(os.path.join(subj, '*T1_seg_2*.nii'))[0]
############################################################################

# 6). apply topup to SBref images
# applytopup --imain=SBref_fMRI1_PA_T001.nii --datain=topupParams.txt --inindex=4 --method=jac --topup=topupFile --out=uSBref_fMRI1_PA_T001.nii
uSBref1 = os.path.join(subj, "u"+os.path.basename(SBref1))
uSBref2 = os.path.join(subj, "u"+os.path.basename(SBref2))
# SBref 1 undistortion
if not(os.path.isfile(uSBref1)): #only run if expected output file does not exist
    cmd = [applytopup, "--datatype=short", "--imain="+SBref1, "--datain="+TOPUPPARAMS, "--inindex="+TOPUPINDEX, "--method=jac", "--topup="+tupOutPrefix, "--out="+uSBref1]
    print("Running: applytopup...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("6). APPLYTOPUP: file " + uSBref1 + " exists already, not overwriting")
    sys.stdout.flush()
# SBref 2 undistortion
if not(os.path.isfile(uSBref2)): #only run if expected output file does not exist
    cmd = [applytopup, "--datatype=short", "--imain="+SBref2, "--datain="+TOPUPPARAMS, "--inindex="+TOPUPINDEX, "--method=jac", "--topup="+tupOutPrefix, "--out="+uSBref2]
    print("Running: applytopup...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("6). APPLYTOPUP: file " + uSBref2 + " exists already, not overwriting")
    sys.stdout.flush()
############################################################################
# 7). use epi_reg to register epi SBref to T1
# epi_reg --epi=uSBref_fMRI1_PA_T001.nii --t1=T1_T001.nii --t1brain=T1_T001_brain.nii --out=epi2struct --echospacing=0.0000725 --pedir=-y
ruSBref1 = os.path.join(subj, "r"+os.path.basename(uSBref1))
ruSBref2 = os.path.join(subj, "r"+os.path.basename(uSBref2))
bn1 = os.path.basename(ruSBref1)
n1 = os.path.splitext(bn1)[0]
n1 = os.path.join(subj, n1)
bn2 = os.path.basename(ruSBref2)
n2 = os.path.splitext(bn2)[0]
n2 = os.path.join(subj, n2)
fmri1_flirt_mat = n1+".mat"
fmri2_flirt_mat = n2+".mat"
# ruSBref2
if not(os.path.isfile(ruSBref1)): #only run if expected output file does not exist
    cmd = [epireg, "--epi="+uSBref1, "--t1="+T1, "--t1brain="+ibT1, "--wmseg="+wmseg, "--out="+n1]
    print("Running: epi_reg...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("7). EPI_REG: file " + ruSBref1 + " exists already, not overwriting")
    sys.stdout.flush()
# ruSBref2
if not(os.path.isfile(ruSBref2)): #only run if expected output file does not exist
    cmd = [epireg, "--epi="+uSBref2, "--t1="+T1, "--t1brain="+ibT1, "--wmseg="+wmseg, "--out="+n2]
    print("Running: epi_reg...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("7). EPI_REG: file " + ruSBref2 + " exists already, not overwriting")
    sys.stdout.flush()
############################################################################
# 8). motion correct fMRI time series files ('c' for Corrected for motion)
# mcflirt -in fMRI1_PA_T001.nii -reffile SBref_fMRI1_PA_T001.nii -out rfMRI1_PA_T001.nii -stats -plots
cfmri1 = os.path.join(subj, "c"+os.path.basename(fmri1))
cfmri2 = os.path.join(subj, "c"+os.path.basename(fmri2))
# fmri1
if not(os.path.isfile(cfmri1)): #only run if expected output file does not exist
    cmd = [mcflirt, "-in", fmri1, "-reffile", SBref1, "-out", cfmri1, "-stats", "-plots"]
    print("Running: mcflirt...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("8). MCFLIRT: file " + cfmri1 + " exists already, not overwriting")
    sys.stdout.flush()
# fmri2
if not(os.path.isfile(cfmri2)): #only run if expected output file does not exist
    cmd = [mcflirt, "-in", fmri2, "-reffile", SBref2, "-out", cfmri2, "-stats", "-plots"]
    print("Running: mcflirt...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("8). MCFLIRT: file " + cfmri2 + " exists already, not overwriting")
    sys.stdout.flush()
############################################################################
# 9). apply topup correction to motion corrected fmri time series data
ucfmri1 = os.path.join(subj, "u"+os.path.basename(cfmri1))
ucfmri2 = os.path.join(subj, "u"+os.path.basename(cfmri2))
cfmri1Mean = glob.glob(os.path.join(subj, 'cfMRI1*meanvol*.nii'))[0]
cfmri2Mean = glob.glob(os.path.join(subj, 'cfMRI2*meanvol*.nii'))[0]
ucfmri1Mean = os.path.join(subj, "u"+os.path.basename(cfmri1Mean))
ucfmri2Mean = os.path.join(subj, "u"+os.path.basename(cfmri2Mean))
# fmri1
if not(os.path.isfile(ucfmri1)): #only run if expected output file does not exist
    cmd = [applytopup, "--datatype=short", "--imain="+cfmri1Mean, "--datain="+TOPUPPARAMS, "--inindex="+TOPUPINDEX, "--method=jac", "--topup="+tupOutPrefix, "--out="+ucfmri1Mean]
    print("Running: applytopup...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
    cmd = [applytopup, "--datatype=short", "--imain="+cfmri1, "--datain="+TOPUPPARAMS, "--inindex="+TOPUPINDEX, "--method=jac", "--topup="+tupOutPrefix, "--out="+ucfmri1]
    print("Running: applytopup...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("9). APPLYTOPUP: file " + ucfmri1 + " exists already, not overwriting")
    sys.stdout.flush()
# fmri2
if not(os.path.isfile(ucfmri2)): #only run if expected output file does not exist
    cmd = [applytopup, "--datatype=short", "--imain="+cfmri2Mean, "--datain="+TOPUPPARAMS, "--inindex="+TOPUPINDEX, "--method=jac", "--topup="+tupOutPrefix, "--out="+ucfmri2Mean]
    print("Running: applytopup...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
    cmd = [applytopup, "--datatype=short", "--imain="+cfmri2, "--datain="+TOPUPPARAMS, "--inindex="+TOPUPINDEX, "--method=jac", "--topup="+tupOutPrefix, "--out="+ucfmri2]
    print("Running: applytopup...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("9). APPLYTOPUP: file " + ucfmri1 + " exists already, not overwriting")
    sys.stdout.flush()
############################################################################
# 11). smooth fmri
# https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;54608a1b.1111
# gucfMRI1_PA_T001.nii_meanvol.nii -kernel gauss 1.27 -fmean xsmoothed.nii
sucfmri1 = os.path.join(subj, "s"+os.path.basename(ucfmri1))
sucfmri2 = os.path.join(subj, "s"+os.path.basename(ucfmri2))
sucfmri1Mean = os.path.join(subj, "s"+os.path.basename(ucfmri1Mean))
sucfmri2Mean = os.path.join(subj, "s"+os.path.basename(ucfmri2Mean))
# fmri1
if not(os.path.isfile(sucfmri1)): #only run if expected output file does not exist
    cmd = [fslmaths, ucfmri1Mean, "-kernel", "gauss", str(SMOOTHMM/2.3548), "-fmean", sucfmri1Mean, "-odt", "short"]
    print("Running: fslmaths smooth...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
    cmd = [fslmaths, ucfmri1, "-kernel", "gauss", str(SMOOTHMM/2.3548), "-fmean", sucfmri1, "-odt", "short"]
    print("Running: fslmaths smooth...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("11). FSLMATHS: file " + sucfmri1 + " exists already, not overwriting")
    sys.stdout.flush()
# fmri2
if not(os.path.isfile(sucfmri2)): #only run if expected output file does not exist
    cmd = [fslmaths, ucfmri2Mean, "-kernel", "gauss", str(SMOOTHMM/2.3548), "-fmean", sucfmri2Mean, "-odt", "short"]
    print("Running: fslmaths smooth...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
    cmd = [fslmaths, ucfmri2, "-kernel", "gauss", str(SMOOTHMM/2.3548), "-fmean", sucfmri2, "-odt", "short"]
    print("Running: fslmaths smooth...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("11). FSLMATHS: file " + sucfmri2 + " exists already, not overwriting")
    sys.stdout.flush()

############################################################################
# 12). register T1 brain to standard brain
# flirt -in T1_T001_brain.nii -ref $FSLDIR/data/standard/MNI152_T1_1mm_brain -omat struct2standard -out struct2standard
wibT1 = os.path.join(subj, "w"+os.path.basename(ibT1)) # registered T1
struct2standardMAT = os.path.join(subj, "struct2standard.mat")
if not(os.path.isfile(wibT1)):
    cmd = [flirt, "-in", ibT1, "-ref", STANDARD2mmBRAIN, "-omat", struct2standardMAT, "-out", wibT1, "-datatype", "short"]
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("12). FLIRT: file " + wibT1 + " exists already, not overwriting")
    sys.stdout.flush()

############################################################################
# 13). make transformation matrix for flirt to get epi to standard space
# convert_xfm -omat epi2standard.mat -concat struct2standard.mat epi2struct.mat
fmri1_2standardMAT = os.path.join(subj, "fmri1_2standard.mat")
fmri2_2standardMAT = os.path.join(subj, "fmri2_2standard.mat")
# fmri 1
if not(os.path.isfile(fmri1_2standardMAT)):
    cmd = [convert_xfm, "-omat", fmri1_2standardMAT, "-concat", struct2standardMAT, fmri1_flirt_mat]
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("13). CONVERT_XFM: file " + fmri1_2standardMAT + " exists already, not overwriting")
    sys.stdout.flush()
# fmri 2
if not(os.path.isfile(fmri2_2standardMAT)):
    cmd = [convert_xfm, "-omat", fmri2_2standardMAT, "-concat", struct2standardMAT, fmri2_flirt_mat]
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("13). CONVERT_XFM: file " + fmri2_2standardMAT + " exists already, not overwriting")
    sys.stdout.flush()
############################################################################
# 14). register epi to standard
# flirt -in urfMRI1_PA_T001.nii_meanvol.nii -ref $FSLDIR/data/standard/MNI152_T1_1mm_brain -applyxfm -init epi2standard.mat -out epi2standard.nii
wsucfmri1 = os.path.join(subj, "w"+os.path.basename(sucfmri1))
wsucfmri2 = os.path.join(subj, "w"+os.path.basename(sucfmri2))
wsucfmri1Mean = os.path.join(subj, "w"+os.path.basename(sucfmri1Mean))
wsucfmri2Mean = os.path.join(subj, "w"+os.path.basename(sucfmri2Mean))
# fmri1
if not(os.path.isfile(wsucfmri1)): #only run if expected output file does not exist
    cmd = [flirt, "-in", sucfmri1Mean, "-ref", STANDARD2mmBRAIN, "-applyxfm", "-init", fmri1_2standardMAT, "-out", wsucfmri1Mean, "-datatype", "short"]
    print("Running: flirt epi2standard...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
    cmd = [flirt, "-in", sucfmri1, "-ref", STANDARD2mmBRAIN, "-applyxfm", "-init", fmri1_2standardMAT, "-out", wsucfmri1, "-datatype", "short"]
    print("Running: flirt epi2standard...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("14). FLIRT: file " + wsucfmri1 + " exists already, not overwriting")
    sys.stdout.flush()
# fmri2
if not(os.path.isfile(wsucfmri2)): #only run if expected output file does not exist
    cmd = [flirt, "-in", sucfmri2Mean, "-ref", STANDARD2mmBRAIN, "-applyxfm", "-init", fmri2_2standardMAT, "-out", wsucfmri2Mean, "-datatype", "short"]
    print("Running: flirt epi2standard...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
    cmd = [flirt, "-in", sucfmri2, "-ref", STANDARD2mmBRAIN, "-applyxfm", "-init", fmri2_2standardMAT, "-out", wsucfmri2, "-datatype", "short"]
    print("Running: flirt epi2standard...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
else:
    print("14). FLIRT: file " + wsucfmri2 + " exists already, not overwriting")
    sys.stdout.flush()

############################################################################
# 15). compute stats using SPM12
if not(os.path.isdir(os.path.join(subj, 'STATS'))):
    cmd = ["matlab", "-nodesktop", "-nosplash", "-r", "fmriStats('"+subj+"')"]
    print("Running: SPM12 stats...")
    print (cmd)
    sys.stdout.flush()
    call(cmd)
###### END ###############
